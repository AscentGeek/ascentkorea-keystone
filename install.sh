#!/usr/bin/env bash
# secure-code-review (Skill) + security-reviewer (Agent) 설치 스크립트
#
# 사용법:
#   ./install.sh --global              # 내 PC 전체에서 사용 (~/.claude)  ← 권장
#   ./install.sh --project <repo경로>  # 특정 repo에만 설치 (<repo>/.claude)
#   ./install.sh --global --update     # 새 버전으로 갱신 (publish-target.md 설정은 유지)
#   ./install.sh --global --uninstall  # 제거
#
# 이 스크립트는 skills/secure-code-review 와 agents/security-reviewer.md 두 곳만 건드린다.
# 다른 Claude Code 설정(settings.json 등)은 수정하지 않는다.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.claude"
SKILL_NAME="secure-code-review"
AGENT_FILE="security-reviewer.md"

MODE=""; TARGET_ROOT=""; UPDATE=0; UNINSTALL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --global)    MODE="global"; TARGET_ROOT="$HOME/.claude" ;;
    --project)   MODE="project"; shift; [ $# -gt 0 ] || { echo "--project 뒤에 repo 경로가 필요합니다" >&2; exit 2; }
                 [ -d "$1" ] || { echo "경로가 없습니다: $1" >&2; exit 2; }
                 TARGET_ROOT="$(cd "$1" && pwd)/.claude" ;;
    --update)    UPDATE=1 ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help)   sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "알 수 없는 옵션: $1 (./install.sh --help)" >&2; exit 2 ;;
  esac
  shift
done
[ -n "$MODE" ] || { echo "--global 또는 --project <repo경로> 를 지정하세요 (./install.sh --help)" >&2; exit 2; }
[ -d "$SRC/skills/$SKILL_NAME" ] || { echo "설치 원본을 찾을 수 없습니다: $SRC (저장소 루트에서 실행하세요)" >&2; exit 2; }

DEST_SKILL="$TARGET_ROOT/skills/$SKILL_NAME"
DEST_AGENT="$TARGET_ROOT/agents/$AGENT_FILE"

if [ "$UNINSTALL" -eq 1 ]; then
  rm -rf "$DEST_SKILL" "$DEST_AGENT"
  echo "제거 완료: $DEST_SKILL, $DEST_AGENT"
  exit 0
fi

if [ -e "$DEST_SKILL" ] && [ "$UPDATE" -ne 1 ]; then
  echo "이미 설치되어 있습니다: $DEST_SKILL" >&2
  echo "새 버전으로 갱신하려면 --update 를 붙이세요." >&2
  exit 1
fi

# 갱신 시 사용자가 바꾼 기본 게시 위치(publish-target.md)는 보존한다.
KEEP_TARGET=""
if [ "$UPDATE" -eq 1 ] && [ -f "$DEST_SKILL/publish-target.md" ]; then
  KEEP_TARGET="$(mktemp)"; cp "$DEST_SKILL/publish-target.md" "$KEEP_TARGET"
fi

mkdir -p "$TARGET_ROOT/skills" "$TARGET_ROOT/agents"
rm -rf "$DEST_SKILL"
cp -R "$SRC/skills/$SKILL_NAME" "$DEST_SKILL"
cp "$SRC/agents/$AGENT_FILE" "$DEST_AGENT"
chmod +x "$DEST_SKILL/scripts/"*.sh

if [ -n "$KEEP_TARGET" ]; then
  cp "$KEEP_TARGET" "$DEST_SKILL/publish-target.md"; rm -f "$KEEP_TARGET"
  echo "기존 publish-target.md 설정을 유지했습니다."
fi

echo "설치 완료 ($MODE)"
echo "  skill: $DEST_SKILL"
echo "  agent: $DEST_AGENT"
echo
echo "다음 단계:"
echo "  1) Claude Code를 재시작하세요."
echo "  2) 점검할 repo에서 /secure-code-review --no-publish 로 시험해 보세요."
echo "  3) 스캐너 설치: brew install semgrep gitleaks trivy && pipx install pip-audit bandit"
echo "  4) 기본 게시 위치 확인: $DEST_SKILL/publish-target.md"
