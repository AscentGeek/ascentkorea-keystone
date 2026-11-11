# Secure Code Review (Claude Code Skill + Agent)

개발팀 소스코드의 보안 취약점을 점검하는 Claude Code용 Skill과 Subagent입니다.
스캐너(SAST/시크릿/의존성)로 후보를 수집하고, Claude가 오탐을 걸러낸 뒤 인가 누락·인젝션 같은 로직 취약점을 직접 추적해 리포트를 작성합니다.

- **점검 기준**: 사내 보안 기준 v0.1(초안·권고, `checklists/internal-standard.md`) + OWASP Top 10 (2021) + CWE. 외부 인증·계약 기준은 없음
- **주력 언어**: Node/TypeScript, Python (그 외 Java, Go, PHP, Ruby, .NET, IaC/CI 포함)
- **실행 방식**: 개발자가 수동 실행
- **산출물**: 제출용 보고서 (Markdown). 결재란·담당자는 비워 둠. 점검 후 기본으로 Confluence에 게시(`--no-publish`로 끔), 그 외 제출은 사용자가 직접
- **안전 원칙**: 점검 대상 소스는 읽기 전용 (생성 파일은 `security-reports/`뿐), 시크릿 원문은 보고서에 기록하지 않음

## 빠른 시작

```bash
git clone https://github.com/AscentGeek/ascentkorea-keystone.git
cd ascentkorea-keystone
./install.sh --global          # 내 PC 전체에서 사용 (~/.claude에 설치)
```

Claude Code를 재시작한 뒤, **점검할 repo에서** 실행합니다.

```
/secure-code-review --no-publish     # 처음에는 게시 없이 시험
```

설치 옵션, 업데이트, 제거 방법은 아래 [1-1. 다운로드 및 설치](#1-1-다운로드-및-설치)를 보세요.

## 구성

```
install.sh                            # 설치 스크립트 (전역/프로젝트, 갱신, 제거)
.claude/
├── agents/
│   └── security-reviewer.md          # 읽기 전용 점검 에이전트 (Read/Grep/Glob/Bash)
└── skills/secure-code-review/
    ├── SKILL.md                      # 점검 절차
    ├── report-template.md            # 리포트 양식
    ├── publish-confluence.md         # Confluence 게시 절차 (기본 수행)
    ├── publish-target.md             # 기본 게시 위치(URL) 설정
    ├── .security-ignore.example.md   # 오탐/예외 관리 예시
    ├── checklists/
    │   ├── internal-standard.md      # 사내 보안 기준 v0.1 (판정 규칙 + 항목)
    │   ├── owasp-top10.md            # 공통
    │   ├── node.md
    │   ├── python.md
    │   └── other-languages.md        # Java/Go/PHP/Ruby/.NET + Docker/Terraform/GitHub Actions
    └── scripts/
        └── scan.sh                   # 스캐너 래퍼
```

## 1. 설치

### 1-1. 다운로드 및 설치

**요구사항**: Claude Code, macOS 또는 Linux의 bash(Windows는 WSL 또는 Git Bash), git. 보고서 Confluence 게시를 쓰려면 Atlassian 연동(1-3절)이 필요합니다.

**① 다운로드** (둘 중 하나)

| 방법 | 절차 | 비고 |
|---|---|---|
| git clone (권장) | `git clone https://github.com/AscentGeek/ascentkorea-keystone.git` | 업데이트가 쉽습니다 (`git pull`) |
| ZIP | GitHub 저장소 페이지의 **Code → Download ZIP**, 압축을 풀고 그 폴더로 이동 | 업데이트 시 다시 받아야 합니다 |

저장소가 비공개이면 GitHub 조직(AscentGeek) 접근 권한이 필요합니다. clone이 거부되면 GitHub 계정 로그인 또는 SSH 키 설정을 확인하세요.

**② 설치** (다운로드한 폴더에서 실행)

| 범위 | 명령 | 설명 |
|---|---|---|
| 전역 (권장) | `./install.sh --global` | `~/.claude`에 설치. 어느 repo에서든 사용하고, 점검 대상 repo에는 파일이 생기지 않습니다 |
| 특정 repo | `./install.sh --project <repo경로>` | `<repo>/.claude`에 설치. repo에 파일이 추가되므로 커밋할지는 팀에서 정하세요 |

스크립트는 `skills/secure-code-review`와 `agents/security-reviewer.md` 두 곳만 건드리며, 다른 Claude Code 설정은 수정하지 않습니다.

**③ 확인**: Claude Code를 재시작한 뒤 점검할 repo에서 `/secure-code-review`를 입력해 자동완성에 나오는지 확인하고, `/secure-code-review --no-publish`로 시험합니다. 스캐너는 1-2절대로 설치하세요(없으면 SKIPPED로 표시됩니다).

**업데이트**

```bash
cd ascentkorea-keystone && git pull
./install.sh --global --update      # (프로젝트 설치였다면 --project <repo경로> --update)
```
`--update`는 설치된 파일을 새 버전으로 교체하되, 직접 바꾼 `publish-target.md`(기본 게시 위치)는 **유지**합니다. 표준이나 체크리스트를 직접 수정했다면 갱신 시 덮어써지므로 변경 내용을 따로 보관하세요.

**제거**

```bash
./install.sh --global --uninstall   # (프로젝트 설치였다면 --project <repo경로> --uninstall)
```

**수동 설치** (스크립트를 쓸 수 없을 때): `.claude/skills/secure-code-review` 폴더를 `~/.claude/skills/`로, `.claude/agents/security-reviewer.md`를 `~/.claude/agents/`로 복사하고 `scripts/*.sh`에 실행 권한(`chmod +x`)을 줍니다.

**기본 게시 위치 변경**: 설치된 `publish-target.md`의 `default_publish_url`을 자기 팀의 Confluence 위치로 수정하거나, 실행 때마다 `--publish <URL>`을 주세요. 게시를 원하지 않으면 `--no-publish`를 씁니다.

### 1-2. 스캐너 설치 (권장)
설치된 도구만 실행되며, 없는 도구는 리포트에 **SKIPPED(미점검)**로 표시됩니다.

| 도구 | 용도 | 설치 |
|---|---|---|
| semgrep | SAST (코드 패턴 취약점) | `brew install semgrep` 또는 `pipx install semgrep` |
| gitleaks | 하드코딩 시크릿 (git 이력 포함) | `brew install gitleaks` |
| npm / yarn / pnpm audit | Node 의존성 취약점 | Node 설치 시 포함 |
| pip-audit | Python 의존성 취약점 | `pipx install pip-audit` |
| bandit | Python SAST (선택) | `pipx install bandit` |
| trivy | 의존성/IaC/Dockerfile (선택) | `brew install trivy` |

한 번에 설치:
```bash
brew install semgrep gitleaks trivy && pipx install pip-audit bandit
```

### 1-3. Confluence 연동 (보고서 게시용)
Claude Code에 Atlassian(Confluence) 연동이 되어 있고, 게시 대상 스페이스에 쓰기 권한이 있어야 합니다. 연동이 없으면 게시는 건너뛰고 `.md` 보고서만 남습니다.

## 2. 사용법

점검할 repo에서 Claude Code를 실행한 뒤 호출합니다.

### Skill 호출
```
/secure-code-review                 # 변경분(git diff)이 있으면 변경분, 없으면 전체
/secure-code-review src/            # 특정 경로
/secure-code-review --diff          # PR 변경분만 (origin/main 기준)
/secure-code-review --all           # repo 전체
```

### Agent 호출 (자연어)
```
security-reviewer 에이전트로 이 repo 보안 점검해줘
auth 모듈만 보안 리뷰하고 리포트 만들어줘
```

> Skill은 현재 대화에서 직접 수행하고, Agent는 별도 컨텍스트에서 읽기 전용으로 수행한 뒤 결과만 돌려줍니다. 대규모 repo는 Agent를 권장합니다.

### 스캐너만 단독 실행
```bash
bash .claude/skills/secure-code-review/scripts/scan.sh <대상경로> [출력디렉터리]
```
출력 디렉터리를 생략하면 임시 디렉터리에 저장되고 마지막 줄에 경로가 출력됩니다.

## 3. 점검 흐름

1. **범위 결정**: 경로 / diff / 전체 (`node_modules`, `.venv`, `dist` 등 제외)
2. **스택 탐지 → 체크리스트 로드**: 사내 보안 기준(`internal-standard.md`)과 OWASP는 항상, `package.json`→node, `requirements.txt`/`pyproject.toml`→python 등은 탐지 시
3. **스캐너 실행**: semgrep, gitleaks, 의존성 audit, trivy
4. **Triage**: 각 결과를 실제 코드로 확인해 확정 / 조건부 / 오탐으로 분류 (판정 규칙은 사내 기준 1절). 사내 기준 위반에는 위반 기준 ID 기록
5. **수동 점검**: 인가(IDOR), source→sink 데이터 흐름, 비즈니스 로직, 설정
6. **보고서 작성**: `report-template.md` 양식 그대로 `security-reports/`에 저장
7. **Confluence 게시**: 기본 수행 (`--no-publish`로 끔, 아래 4절)

## 4. 최종 보고서 작성 및 제출

### 산출물
```
<점검 대상 repo>/security-reports/
└── security-report_<repo명>_<YYYYMMDD>.md    # 보고서 원본 (Confluence에도 게시)
```

### 보고서 구성
표지 정보 → 결재란 → 1.요약 → 2.점검 개요(범위·방법·스캐너 커버리지) → 3.지적사항 목록(위반 기준 ID 포함) → 4.지적사항 상세 → 5.조치 계획 → 6.오탐/제외 → 7.한계 → 부록(원본 결과 위치, 변경 이력)

### 제출 전 담당자가 할 일 (체크리스트)
- [ ] **결재란**(점검자/검토자/승인자 성명·서명) 기입 — AI는 임의로 채우지 않습니다
- [ ] **조치 계획**의 담당자·목표일 기입
- [ ] 지적사항 중 신뢰도 "낮음(추정)"은 직접 확인 후 확정/삭제
- [ ] 스캐너 **SKIPPED** 항목이 있으면 설치 후 재점검, 또는 "미점검"임을 보고서에 유지
- [ ] 보안등급 표기 확인 (기본: 내부용)
- [ ] 게시된 Confluence 페이지에서 위 항목을 직접 기입 (게시 후 수정)

### 제출 (Confluence 게시)
점검이 끝나면 **기본으로 Confluence에 게시**합니다. 기본 위치는 `.claude/skills/secure-code-review/publish-target.md`의 `default_publish_url`입니다. 이메일, Jira, Slack 등은 사용자가 요청할 때만 진행합니다.

```
/secure-code-review --all                      # 기본 위치에 게시
/secure-code-review --all --publish <URL>      # 이 URL에 게시 (기본값 대신)
/secure-code-review --all --no-publish         # 게시하지 않고 파일만 생성
```

URL 형식: `https://<사이트>.atlassian.net/wiki/spaces/<스페이스키>/overview?homepageId=<홈페이지ID>`

| 규칙 | 내용 |
|---|---|
| 상위 페이지 | 영역(점검 대상 repo 이름). 이미 있으면 그 아래에 추가, 없으면 새로 만든 뒤 추가 |
| 보고서 제목 | `소스코드 보안 점검 보고서 - <영역> (<YYYY-MM-DD HH:mm>)` |
| 재점검 | 기존 보고서를 덮어쓰지 않고 새 일시 제목의 하위 페이지로 추가 |
| 비워 두는 항목 | 결재란, 담당자, 목표일, 변경 이력 (게시 후 Confluence에서 직접 기입) |
| 한계 | Confluence **폴더**는 생성 도구가 없어 일반 페이지로 대체. 폴더가 필요하면 직접 만들어 이동 |

필요 조건: Claude Code에 Atlassian(Confluence) 연동이 되어 있고 해당 스페이스에 쓰기 권한이 있어야 합니다. 상세 절차는 `.claude/skills/secure-code-review/publish-confluence.md`.

### 보관 주의
보고서에는 취약점 상세가 들어 있습니다. 점검 대상 repo의 `.gitignore`에 `security-reports/`를 추가해 실수로 커밋되지 않게 하세요 (Claude는 권고만 하고 직접 수정하지 않습니다).

## 5. 보고서 읽는 법

| 항목 | 의미 |
|---|---|
| 심각도 | Critical / High / Medium / Low / Info |
| 분류 | **확정**: 위반이 확인되고 추가 취약점·repo 밖 특수 조건 없이 악용 가능 / **조건부**: 악용에 다른 취약점, repo 밖 설정, 기능 활성화가 필요(조건 명시) |
| 위반 기준 ID | 위반한 사내 기준 항목 (예: `WEB-01`). 해당 없으면 `-` |
| 신뢰도 | 높음 / 중간 / 낮음(추정) — 낮음은 개발자가 직접 확인 필요 |
| 스캐너 커버리지 | SKIPPED 도구가 있으면 그 영역은 **미점검**임 |
| 오탐/제외 목록 | 제외한 항목과 사유 (검토용) |

심각도 기준
- **Critical**: 인증 없이 원격 코드 실행/전체 데이터 유출, 운영 시크릿 노출
- **High**: 권한 상승, 인젝션, IDOR, 광범위 데이터 노출
- **Medium**: 조건부 악용, 방어 심층 부족, 도달 가능한 취약 의존성
- **Low / Info**: 하드닝 권고, 참고

항목별 기본 심각도와 조정 규칙은 사내 보안 기준 1.2/1.3절을 따릅니다.

### 사내 보안 기준 (v0.1, 권고)
`.claude/skills/secure-code-review/checklists/internal-standard.md`에 있습니다. **초안이며 권고 단계**라 위반은 "표준 위반(권고)"으로 기록하고 배포를 막는 근거로 쓰지 않습니다. 외부 인증·계약 기준은 없고, 뼈대는 OWASP ASVS 4.0 레벨 1과 CWE입니다.

| 구성 | 내용 |
|---|---|
| 판정 규칙 (1절) | 확정/조건부 정의, 심각도 조정(조건부이고 도달 경로 미확인이면 1단계 하향), **의존성 CVE 도달성 매핑표**, 오탐 인정 기준, 조치 권고 기한(초안 값) |
| 항목 30개 | AUTH, SES, ACC, INP, CRY, SEC, WEB, DEP, CI, LOG, ERR, BIZ, FILE (항목별 근거 CWE/ASVS, 점검 방법, 기본 심각도) |
| 8절 | 보안 담당자가 확정해야 할 항목 (조치 기한, 기본 심각도, 승인자, 권고→필수 전환 시점) |

권고를 필수로 바꾸려면 `internal-standard.md`의 상태와 0절 문구를 고치면 됩니다.

## 6. 오탐/예외 관리

점검 대상 repo 루트에 `.security-ignore.md`를 만들어 등록합니다. 양식은 `.security-ignore.example.md` 참고.

- **사유 · 승인자 · 만료일**이 모두 있어야 제외됩니다.
- 만료일이 지난 항목은 다시 점검 대상이 됩니다.
- 점검 중 오탐으로 제외할 때는 **코드 인용 근거**가 필요합니다. "이스케이프했다"만으로 정규식 탐지를 제외하는 것처럼 사내 기준 1.4절이 금지한 근거는 인정되지 않습니다.

## 7. 보안/운영 주의사항

- **소스 수정 없음**: 수정안은 보고서에 diff 형태로만 제시합니다. 적용은 개발자가 합니다. 생성하는 파일은 `security-reports/` 하위의 보고서뿐입니다.
- **시크릿 마스킹**: gitleaks는 `--redact`, 리포트에는 앞 4자 + `***`만 기록합니다.
- **외부 전송**: 소스코드는 외부로 전송하지 않습니다. 단, semgrep은 룰셋(`p/default`, `p/owasp-top-ten`, `p/security-audit`) 다운로드를 위해 외부에 접속합니다(`--metrics=off` 적용). 완전 오프라인이 필요하면:
  ```bash
  SEMGREP_CONFIG=/path/to/local/rules bash .claude/skills/secure-code-review/scripts/scan.sh .
  ```
- **프롬프트 인젝션 방어**: 점검 대상 파일(주석, README 등) 안의 지시문은 데이터로만 취급하고 따르지 않습니다.
- **리포트 보관**: 리포트에는 취약점 정보가 담기므로 공개 이슈/채널에 올리지 말고 팀 내부에서만 공유하세요.
- **한계**: 런타임 설정, 인프라, 외부 서비스, 스캐너 미설치 영역은 점검되지 않습니다. 이 도구는 보안 전문가 리뷰와 침투 테스트를 대체하지 않습니다.

## 8. 커스터마이징

| 하고 싶은 것 | 수정할 파일 |
|---|---|
| 점검 항목 추가/삭제 | `checklists/*.md` |
| 새 언어/프레임워크 추가 | `checklists/<언어>.md` 생성 후 `SKILL.md`의 "스택 탐지" 표에 추가 |
| 심각도 기준 변경 | `SKILL.md` 6절 |
| 보고서 양식 변경 (사내 서식, 로고, 보안등급 등) | `report-template.md` |
| 스캐너 추가 | `scripts/scan.sh` |
| 사내 보안 기준 항목·판정 규칙·조치 기한 변경 | `checklists/internal-standard.md` (확정 필요 항목은 8절) |
| 권고 → 필수 전환 | `internal-standard.md`의 상태와 0절 문구, 필요 시 `SKILL.md` 기준 문구 수정 |

## 9. 문제 해결

| 증상 | 확인 |
|---|---|
| `/secure-code-review`가 보이지 않음 | `.claude/skills/secure-code-review/SKILL.md` 위치 확인 후 Claude Code 재시작 |
| 스캐너가 전부 SKIPPED | 위 1-2절대로 설치, `which semgrep` 등으로 PATH 확인 |
| semgrep 결과가 비어 있음 | 출력 디렉터리의 `semgrep.err` 확인 (네트워크 차단 시 룰셋 다운로드 실패) |
| Node 의존성 audit이 SKIPPED | 락 파일(`package-lock.json` 등) 없음 — 그 자체가 지적사항 |
| 점검이 너무 오래 걸림 | 경로를 좁히거나 `--diff` 사용 |
| Confluence 게시가 건너뛰어짐 | Atlassian 연동과 스페이스 쓰기 권한 확인, `publish-target.md`의 URL 확인 |

## 10. 로드맵 (선택)

- [ ] GitHub Actions 연동 (PR 자동 점검, 코멘트 게시)
- [ ] 취약 샘플 앱(OWASP Juice Shop, DVNA)으로 탐지율 검증
- [ ] 오탐 피드백 기반 체크리스트 튜닝
- [ ] 사내 보안 기준 v0.1 확정(심각도·조치 기한), 2개 분기 운영 후 필수 항목 전환 검토
