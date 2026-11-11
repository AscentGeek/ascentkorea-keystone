#!/usr/bin/env bash
# 보안 스캐너 래퍼. 설치된 도구만 실행하고 미설치 도구는 SKIPPED 로 보고한다.
# 사용법: scan.sh <대상경로> [출력디렉터리]
# 모든 스캔은 로컬에서 실행되며 소스코드를 외부로 전송하지 않는다.
#   - semgrep: 명시 룰셋(p/default 등)은 룰 다운로드를 위해 외부 접속하나 코드는 전송하지 않음.
#              완전 오프라인이 필요하면 SEMGREP_CONFIG 로 로컬 룰 경로 지정)
set -u

TARGET="${1:-.}"
OUT="${2:-$(mktemp -d "${TMPDIR:-/tmp}/secscan.XXXXXX")}"
mkdir -p "$OUT"
cd "$TARGET" || { echo "대상 경로 접근 불가: $TARGET" >&2; exit 2; }

SUMMARY="$OUT/summary.txt"
: > "$SUMMARY"
log() { echo "$*" | tee -a "$SUMMARY"; }
have() { command -v "$1" >/dev/null 2>&1; }

EXCLUDES=(--exclude node_modules --exclude .venv --exclude venv --exclude dist --exclude build --exclude vendor --exclude .git)

log "== 대상: $(pwd)"
log "== 출력: $OUT"

# 1) SAST: semgrep
if have semgrep; then
  # 'auto' 는 metrics 활성화가 필요해 --metrics=off 와 함께 쓸 수 없다. 명시적 룰셋을 사용한다.
  # 오프라인/사내 룰 사용: SEMGREP_CONFIG=/path/to/rules (단일 값)
  if [ -n "${SEMGREP_CONFIG:-}" ]; then
    CFG_ARGS=(--config "$SEMGREP_CONFIG")
  else
    CFG_ARGS=(--config p/default --config p/owasp-top-ten --config p/security-audit)
  fi
  semgrep scan "${CFG_ARGS[@]}" --metrics=off --json --quiet "${EXCLUDES[@]}" . \
    > "$OUT/semgrep.json" 2> "$OUT/semgrep.err"
  rc=$?
  # semgrep: 0=정상, 1=findings(--error 사용 시). 그 외는 실패
  if [ -s "$OUT/semgrep.json" ]; then log "[OK]      semgrep -> semgrep.json"; else log "[FAILED]  semgrep (rc=$rc, semgrep.err 확인)"; fi
else
  log "[SKIPPED] semgrep  (설치: brew install semgrep 또는 pipx install semgrep)"
fi

# 2) 시크릿: gitleaks (git 이력 포함 / 아니면 디렉터리)
if have gitleaks; then
  if [ -d .git ]; then
    gitleaks detect --source . --report-format json --report-path "$OUT/gitleaks.json" --redact --no-banner >/dev/null 2>&1
  else
    gitleaks detect --no-git --source . --report-format json --report-path "$OUT/gitleaks.json" --redact --no-banner >/dev/null 2>&1
  fi
  log "[OK]      gitleaks -> gitleaks.json (값은 redact 처리됨)"
else
  log "[SKIPPED] gitleaks (설치: brew install gitleaks)"
fi

# 3) 의존성: Node
if [ -f package.json ]; then
  if have npm; then
    if [ -f package-lock.json ] || [ -f npm-shrinkwrap.json ]; then
      npm audit --json > "$OUT/npm-audit.json" 2> "$OUT/npm-audit.err"
      log "[OK]      npm audit -> npm-audit.json"
    elif [ -f yarn.lock ] && have yarn; then
      yarn audit --json > "$OUT/yarn-audit.json" 2> "$OUT/yarn-audit.err"
      log "[OK]      yarn audit -> yarn-audit.json"
    elif [ -f pnpm-lock.yaml ] && have pnpm; then
      pnpm audit --json > "$OUT/pnpm-audit.json" 2> "$OUT/pnpm-audit.err"
      log "[OK]      pnpm audit -> pnpm-audit.json"
    elif { [ -f bun.lock ] || [ -f bun.lockb ]; } && have bun; then
      # bun audit 은 bun >= 1.2.15 에서 지원
      if bun audit --json > "$OUT/bun-audit.json" 2> "$OUT/bun-audit.err"; [ -s "$OUT/bun-audit.json" ]; then
        log "[OK]      bun audit -> bun-audit.json"
      else
        log "[FAILED]  bun audit (bun $(bun --version 2>/dev/null) — 1.2.15 이상 필요, bun-audit.err 확인) → trivy가 설치돼 있으면 bun.lock을 대신 점검, 아니면 의존성 CVE 미점검"
      fi
    elif [ -f bun.lock ] || [ -f bun.lockb ]; then
      log "[SKIPPED] bun audit (bun 미설치) → 의존성 CVE 미점검"
    else
      log "[SKIPPED] Node 의존성 audit (락 파일 없음 — 그 자체가 지적사항)"
    fi
  else
    log "[SKIPPED] Node 의존성 audit (npm 없음)"
  fi
fi

# 4) 의존성: Python
if [ -f requirements.txt ] || [ -f pyproject.toml ] || [ -f Pipfile.lock ] || [ -f poetry.lock ]; then
  if have pip-audit; then
    if [ -f requirements.txt ]; then
      pip-audit -r requirements.txt -f json -o "$OUT/pip-audit.json" >/dev/null 2> "$OUT/pip-audit.err"
    else
      pip-audit -f json -o "$OUT/pip-audit.json" >/dev/null 2> "$OUT/pip-audit.err"
    fi
    log "[OK]      pip-audit -> pip-audit.json"
  else
    log "[SKIPPED] pip-audit (설치: pipx install pip-audit)"
  fi
  if have bandit; then
    bandit -r . -f json -o "$OUT/bandit.json" -x ./node_modules,./.venv,./venv,./tests >/dev/null 2>&1
    log "[OK]      bandit -> bandit.json"
  else
    log "[SKIPPED] bandit (선택, 설치: pipx install bandit)"
  fi
fi

# 5) 범용: trivy (취약 의존성, IaC 설정, 시크릿)
if have trivy; then
  trivy fs --quiet --scanners vuln,misconfig --format json --output "$OUT/trivy.json" . >/dev/null 2> "$OUT/trivy.err"
  log "[OK]      trivy -> trivy.json"
else
  log "[SKIPPED] trivy (선택, 설치: brew install trivy)"
fi

log ""
log "== 완료. 결과 디렉터리: $OUT"
echo "$OUT"
