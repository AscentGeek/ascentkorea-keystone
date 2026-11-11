---
name: secure-code-review
description: 소스코드 보안 점검. SAST/시크릿/의존성 스캐너를 실행하고 결과를 triage한 뒤, 인가 누락·인젝션 등 로직 취약점을 직접 추적해 리포트를 작성한다. "보안 점검", "취약점 확인", "secure code review" 요청 시 사용.
argument-hint: "[경로 | --diff | --all] [--publish <Confluence URL>] [--no-publish]  (기본: 변경분 있으면 diff, 없으면 전체. 게시는 기본 수행, 위치는 publish-target.md)"
---

# Secure Code Review

기준: **사내 보안 기준 v0.1(권고, `checklists/internal-standard.md`) + OWASP Top 10 (2021) + CWE**. 사내 기준은 초안·권고 단계이므로 위반은 "표준 위반(권고)"으로 기록하고, 사내 기준에 없는 취약점도 OWASP/CWE 기준으로 지적한다. 분류·심각도·오탐 판정은 사내 기준 1절의 규칙을 따른다.

## 1. 범위 결정
- 인자가 경로면 해당 경로.
- `--diff`: `git diff` 기준 변경 파일 (git repo인 경우 `git diff origin/main...HEAD` 우선, 없으면 `git diff HEAD`).
- 그 외: repo 전체 (`node_modules`, `.venv`, `dist`, `build`, `vendor` 제외).
- 결정한 범위를 리포트 상단에 기록한다.

## 2. 언어/스택 탐지 → 체크리스트 로드
| 탐지 신호 | 로드 |
|---|---|
| 항상 | `checklists/internal-standard.md` (판정 규칙 1절 + 항목) |
| 항상 | `checklists/owasp-top10.md` |
| `package.json`, `*.js/ts` | `checklists/node.md` |
| `requirements.txt`, `pyproject.toml`, `*.py` | `checklists/python.md` |
| 그 외 (Java, Go, PHP 등) | `checklists/other-languages.md` |
| `Dockerfile`, `*.tf`, `.github/workflows` | `checklists/other-languages.md`의 IaC/CI 절 |

## 3. 스캐너 실행
```bash
bash .claude/skills/secure-code-review/scripts/scan.sh <대상경로> <출력디렉터리>
```
- 출력 디렉터리 미지정 시 임시 디렉터리를 쓰고 repo 안에 결과 파일을 만들지 않는다.
- 미설치 도구는 스크립트가 SKIPPED로 표시한다. 리포트의 "스캐너 커버리지"에 그대로 기록하고, 설치 안내를 덧붙인다.

## 4. Triage (스캐너 결과 검증)
각 결과를 열어 실제 코드를 읽고 분류한다. 상세 기준은 `internal-standard.md` 1절(분류, 의존성 CVE 매핑, 오탐 기준)이다.
- **확정**: 위반이 확인되고 추가 취약점·repo 밖 특수 조건 없이 악용 가능
- **조건부**: 악용에 다른 취약점, repo 밖 설정, 특정 기능 활성화가 필요 (조건 명시)
- **오탐**: 도달 불가, 이미 방어됨 → **코드 인용 근거**와 사유 한 줄을 적어 제외 목록으로. "이스케이프했다"만으로 정규식 탐지를 제외하는 등 1.4절이 금지한 근거는 쓰지 않는다
- 사내 기준 항목을 위반한 지적에는 **위반 기준 ID**를 기록한다
- 의존성 CVE는 패키지 단위로 묶고 도달성으로 등급을 정한다 (1.3절)
- `.security-ignore.md`에 등재된 항목은 사유·승인자를 확인하고 제외 (만료일 지난 것은 재점검).

## 5. 수동 점검 (스캐너가 약한 영역)
다음은 반드시 직접 코드를 추적한다:
1. **인가**: 모든 라우트/핸들러에 인증·인가가 있는가? 객체 접근 시 소유자 검증(IDOR)이 있는가? 관리자 기능 분리는?
2. **데이터 흐름**: 요청 입력(query/body/header/cookie/파일) → DB 쿼리, 쉘, 파일 경로, URL 요청, 템플릿, 역직렬화로 가는 경로.
3. **비즈니스 로직**: 금액/수량 조작, 레이스 컨디션, 상태 전이 우회, 비밀번호 재설정/초대 흐름.
4. **설정**: CORS, 쿠키 플래그, CSRF, 보안 헤더, 디버그 모드, 에러 메시지 노출.

## 6. 보고서 작성 (제출용 산출물)
`report-template.md` 양식을 **그대로** 따라 최종 보고서를 작성한다 (표지 정보, 결재란, 요약, 개요, 지적사항 목록/상세, 조치 계획, 오탐, 한계, 부록).
- 저장 위치: 점검 대상 repo의 `security-reports/` (없으면 생성)
- 파일명: `security-report_<repo명>_<YYYYMMDD>.md`
- 점검자/검토자/승인자 성명·서명, 담당자, 목표일은 **비워 둔다** (사용자가 기입). 임의로 채우지 않는다.
- 지적이 0건이어도 보고서를 작성한다 (점검 범위, 스캐너 커버리지, 한계 포함).
- 시크릿 원문 금지. 스캐너 원본 JSON은 보고서에 첨부하지 않고 경로만 기재한다.
- 보고서에는 취약점 정보가 담기므로 `security-reports/`가 `.gitignore`에 없으면 추가를 **권고**만 한다 (임의 수정 금지).

심각도는 `internal-standard.md`의 항목 기본값과 1.2/1.3절 조정 규칙으로 정한다. 기본 정의는 다음과 같다:
- **Critical**: 인증 없이 원격 코드 실행/전체 데이터 유출, 운영 시크릿 노출
- **High**: 인증된 사용자의 권한 상승, 인젝션, IDOR, 광범위 데이터 노출
- **Medium**: 조건부 악용, 방어 심층 부족, 취약 의존성 (도달 가능)
- **Low**: 정보 노출 경미, 하드닝 권고
- **Info**: 참고

## 7. 제출 (Confluence 게시)
보고서(.md) 작성이 끝나면 **기본으로 Confluence에 게시한다.** `publish-confluence.md`의 절차를 따른다. PDF는 만들지 않는다.
- 게시 위치: 호출 인자 `--publish <URL>`이 있으면 그 URL, 없으면 `publish-target.md`의 `default_publish_url`
- `--no-publish`가 있으면 게시하지 않는다. 기본 URL이 비어 있거나 접근 불가면 게시하지 않고 사유와 보고서 경로를 알린다
- 영역(repo 이름) 페이지를 상위로 두고, 이미 있으면 그 하위에 추가, 없으면 영역 페이지를 만든 뒤 추가
- 제목: `소스코드 보안 점검 보고서 - <영역> (<YYYY-MM-DD HH:mm>)`
- 결재란·담당자·목표일은 비워 둔 채 게시, 시크릿 원문 없는지 게시 직전 확인
- 게시 대상은 위 URL로 한정한다. 이메일, Jira, Slack 등 다른 곳으로는 사용자가 명시적으로 요청할 때만 보낸다
- 최종 응답에는 보고서 `.md` **전체 경로**, 게시한 Confluence 페이지 URL(게시한 경우), 요약(심각도별 건수), 사용자가 기입할 항목(결재란·담당자·목표일), 스캐너 SKIPPED/FAILED 여부를 알린다

## 8. 하지 말 것
- 점검 대상 소스 코드 수정/커밋 (수정안은 보고서에 diff 형태로만. 생성 파일은 `security-reports/` 하위만)
- 근거 없는 추측성 지적, 스캐너 출력 복붙
- 시크릿 원문 기재
- 결재란/담당자 임의 기입, 제출(외부 전송) 임의 수행
- 실제 서비스 대상 공격 시도 (공격 시나리오는 코드 기반 서술만)
