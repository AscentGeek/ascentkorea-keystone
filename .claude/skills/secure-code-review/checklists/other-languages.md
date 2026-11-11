# 기타 언어 및 IaC/CI 체크리스트

공통 원칙: `owasp-top10.md` 를 기준으로 하되, 아래 언어별 위험 sink를 Grep으로 시작점 삼는다.
이 언어들은 팀 주력이 아니므로 **스캐너(semgrep) 결과 비중을 높이고, 수동 점검은 인가·인젝션에 집중**한다.

## Java / Kotlin (Spring)
- SQL: `createQuery("..." +`, `Statement.execute`, JdbcTemplate 문자열 결합, MyBatis `${}` (`#{}` 가 안전)
- 역직렬화: `ObjectInputStream.readObject`, Jackson `enableDefaultTyping`, `XMLDecoder`
- SpEL/OGNL/템플릿 인젝션, `Runtime.exec`, `ProcessBuilder`
- XXE: `DocumentBuilderFactory` 에 `disallow-doctype-decl` 미설정
- Spring Security: `permitAll()` 범위, `csrf().disable()`, `@PreAuthorize` 누락, Actuator 엔드포인트 노출, `@RequestBody` 엔티티 직접 바인딩(Mass Assignment)
- Log4Shell 등 알려진 취약 버전

## Go
- `exec.Command("sh", "-c", ...)`, `database/sql` 문자열 결합 쿼리, `html/template` 대신 `text/template`
- `http.ServeFile` / `filepath.Join` 경로 검증, `InsecureSkipVerify: true`
- goroutine 레이스로 인한 권한/상태 문제, `math/rand` 로 토큰 생성

## PHP
- `include/require` 에 사용자 입력(LFI/RFI), `unserialize`, `eval`, `system/exec/passthru`
- `mysqli_query` 문자열 결합, `==` 느슨한 비교(매직 해시), `extract($_GET)`
- 업로드 확장자 검증, `display_errors`

## Ruby / Rails
- `find_by_sql`/`where("... #{}")`, `send`/`constantize` 사용자 입력, `Marshal.load`, `YAML.load`
- strong parameters 누락, `html_safe`/`raw`, `protect_from_forgery` 비활성화

## C# / .NET
- `SqlCommand` 문자열 결합, `BinaryFormatter`, `[AllowAnonymous]` 범위, `ValidateAntiForgeryToken` 누락, `Process.Start`

## 프론트엔드 공통
- 시크릿/API 키가 번들에 포함, 소스맵 운영 노출, 서드파티 스크립트 무결성(SRI)

## IaC / 컨테이너 / CI

### Dockerfile
- [ ] `USER` 미지정(root 실행), `latest` 태그, 시크릿을 `ENV`/`ARG`/`COPY` 로 이미지에 포함
- [ ] `ADD` 로 원격 URL, 불필요한 패키지/빌드 도구가 최종 이미지에 잔존, 멀티스테이지 미사용

### Terraform / CloudFormation / K8s
- [ ] `0.0.0.0/0` 인바운드, 공개 S3/스토리지, 암호화 비활성, IAM `*:*`
- [ ] K8s: `privileged`, `hostNetwork`, `runAsRoot`, 시크릿 평문 매니페스트, 리소스 제한 없음

### GitHub Actions (`.github/workflows`)
- [ ] 서드파티 Action이 태그/브랜치 고정 (커밋 SHA 고정 권장)
- [ ] `pull_request_target` 에서 PR 코드를 checkout·실행
- [ ] `${{ github.event.* }}` (이슈 제목, PR 제목/브랜치명 등)를 `run:` 에 직접 삽입 (스크립트 인젝션)
- [ ] `permissions:` 미지정(과도한 기본 GITHUB_TOKEN 권한)
- [ ] 시크릿을 로그에 출력, `secrets: inherit` 남용, self-hosted 러너에서 fork PR 실행
