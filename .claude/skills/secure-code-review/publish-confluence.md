# 보고서 Confluence 게시 절차

**점검이 끝나면 기본으로 수행한다.** 게시 위치는 `--publish <URL>`이 있으면 그 URL, 없으면 `publish-target.md`의 `default_publish_url`이다. `--no-publish`이거나 대상 URL이 비어 있으면 게시하지 않고 보고서 파일(.md)만 만든다. 지정된 URL 외의 대상에는 게시하지 않는다.

## 게시 위치 규칙
- **영역(점검 대상 repo 이름)을 상위 페이지로** 둔다. 예: `my-service`
- 영역 페이지가 **이미 있으면** 그 아래에 하위 페이지로 추가하고, **없으면** 영역 페이지를 먼저 만든 뒤 그 아래에 추가한다.
- 보고서 제목: `<YYYY-MM-DD HH:mm> - <영역>` (점검 일시 선두, KST. 예: `2026-11-11 18:00 - ascentkorea-hubble-intent`)
  - 일시는 `TZ=Asia/Seoul date "+%Y-%m-%d %H:%M"`로 얻는다.
- 영역 페이지의 부모는 사용자가 준 URL의 페이지(보통 스페이스 홈). URL이 특정 페이지를 가리키면 그 페이지 아래에 영역 페이지를 둔다.
- Confluence "폴더"는 생성 도구가 없으므로 **일반 페이지**로 대체하고, 그 사실을 최종 응답에 알린다.

## 절차 (Atlassian MCP 도구)
도구가 지연 로드 상태면 먼저 ToolSearch로 아래를 한 번에 불러온다:
`getConfluenceSpaces, searchConfluenceUsingCql, getConfluencePageDescendants, getConfluencePage, createConfluencePage`

1. **URL 파싱**: `https://<site>.atlassian.net/wiki/spaces/<스페이스키>/...` → `cloudId`=`<site>.atlassian.net`, 스페이스 키, `homepageId` 쿼리값(있으면).
2. **스페이스 ID 조회**: `getConfluenceSpaces(keys=[스페이스키])` → 숫자 `id`(=`spaceId`)와 `homepageId`를 얻는다. 접근 불가/없음이면 중단하고 사유를 보고한다.
3. **영역 페이지 탐색**: `searchConfluenceUsingCql`로 `space = "<키>" AND title ~ "<영역>"` 검색. 필요하면 `getConfluencePageDescendants(홈)`도 확인한다.
   - 제목이 영역명과 **정확히 일치**하는 페이지가 1개 → 그것을 상위로 사용
   - 0개 → `createConfluencePage`로 영역 페이지 생성 (parent=홈 또는 URL의 페이지). 본문은 영역 개요 몇 줄
   - 2개 이상(모호) → **게시하지 않고** 후보를 보고한다
4. **보고서 하위 페이지 생성**: `createConfluencePage(spaceId, parentId=영역 페이지 id, title, contentFormat="markdown", body=...)`
   - 본문은 보고서 `.md`에서 **최상위 `# 제목` 한 줄을 제외**한 내용(제목은 페이지 제목으로 대체)
   - 결재란·담당자·목표일·변경이력 일자/작성자는 **비워 둔 채** 올린다
   - 마크다운 표/목록/코드 표기는 정상 변환된다. 매우 긴 본문은 한 번의 호출로 보낸다
5. **검증**: 응답의 `body.storage`에서 표·목록·코드가 변환됐는지 확인하고, 페이지 URL(`_links.base` + `_links.webui`)을 얻는다. 실패하면 오류를 그대로 보고한다 (성공으로 보고하지 않는다).
6. **보고**: 영역 페이지 신규 생성 여부, 보고서 페이지 URL, 제목, 비워 둔 항목, 접근 권한 확인 권고를 알린다.

## 주의
- 보고서에는 취약점 상세가 담겨 있다. 최종 응답에 **스페이스 접근 권한을 확인하라**고 권고한다.
- 시크릿 원문이 보고서에 없는지(앞 4자+*** 마스킹) 게시 직전에 한 번 확인한다.
- 같은 점검을 다시 게시할 때는 기존 보고서를 덮어쓰지 않고 **새 일시 제목의 하위 페이지로 추가**한다.
- 게시한 내용은 외부 시스템에 남는다. 임의로 삭제/수정하지 않는다.
