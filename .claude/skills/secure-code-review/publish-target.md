# 기본 게시 대상

점검 후 보고서는 아래 Confluence 위치에 **기본으로 게시**된다. 호출 인자 `--publish <URL>`이 있으면 그 URL이 우선하고, `--no-publish`면 게시하지 않는다.

default_publish_url: https://ascentkorea.atlassian.net/wiki/spaces/hGCyJ3dirkUt/overview?homepageId=2302312680

- 이 값을 바꾸면 이후 점검의 기본 게시 위치가 바뀐다. 팀/프로젝트별로 다르게 쓰려면 이 파일을 복사해 수정한다.
- 값이 비어 있거나 접근할 수 없으면 게시하지 않고, 사유와 함께 보고서 파일 경로만 알린다.
