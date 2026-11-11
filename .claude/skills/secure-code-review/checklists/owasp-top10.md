# OWASP Top 10 (2021) 점검 체크리스트 (언어 공통)

## A01 Broken Access Control (CWE-284, 639, 862, 863, 352)
- [ ] 모든 엔드포인트에 인증 미들웨어/데코레이터가 적용되어 있는가 (누락된 라우트 목록화)
- [ ] 객체 ID로 조회/수정/삭제 시 소유자·테넌트 검증이 있는가 (IDOR)
- [ ] 프론트에서만 권한을 숨기고 서버 검증이 없는 기능
- [ ] 관리자/내부 API가 일반 사용자에게 노출되는가
- [ ] CORS가 `*` 또는 요청 Origin 반사 + credentials 허용인가
- [ ] 상태 변경 요청의 CSRF 방어 (토큰 또는 SameSite)
- [ ] 파일 경로를 사용자 입력으로 구성 (Path Traversal, CWE-22)

## A02 Cryptographic Failures (CWE-259, 327, 328, 330, 798)
- [ ] 비밀번호 해시: bcrypt/scrypt/argon2 사용 (MD5/SHA1/단순 SHA256 금지)
- [ ] 하드코딩된 키/토큰/비밀번호, 코드에 포함된 `.env`
- [ ] 보안 용도 난수에 `Math.random()` / `random` 모듈 사용
- [ ] ECB 모드, 고정 IV, 약한 알고리즘 (DES, RC4)
- [ ] TLS 검증 비활성화 (`rejectUnauthorized: false`, `verify=False`)
- [ ] 민감정보 평문 저장/전송/로그

## A03 Injection (CWE-89, 78, 79, 94, 90, 643)
- [ ] SQL: 문자열 결합/포맷으로 쿼리 구성 (파라미터 바인딩 아님)
- [ ] NoSQL: 요청 객체를 쿼리에 그대로 전달 (`$ne`, `$gt` 연산자 주입)
- [ ] OS 명령: 사용자 입력이 쉘 호출에 도달 (`exec`, `os.system`, `shell=True`)
- [ ] XSS: 이스케이프 없는 HTML 출력 (`innerHTML`, `dangerouslySetInnerHTML`, `|safe`, `v-html`)
- [ ] 템플릿 인젝션 (SSTI), `eval`/`exec`/`Function()` 사용
- [ ] LDAP/XPath/헤더 인젝션 (CRLF)

## A04 Insecure Design
- [ ] 로그인/비밀번호 재설정/OTP에 rate limit, 잠금 정책
- [ ] 금액·수량·권한 등 비즈니스 로직 서버측 검증
- [ ] 레이스 컨디션 (재고, 쿠폰, 포인트 이중 사용)
- [ ] 비밀번호 재설정 토큰: 예측 불가, 1회용, 만료

## A05 Security Misconfiguration (CWE-16, 611, 548)
- [ ] 디버그 모드/스택트레이스 운영 노출 (`DEBUG=True`, Express 기본 에러)
- [ ] 기본 계정/기본 비밀번호, 불필요한 포트·기능
- [ ] 보안 헤더 (CSP, HSTS, X-Content-Type-Options, X-Frame-Options)
- [ ] 쿠키: `HttpOnly`, `Secure`, `SameSite`
- [ ] XML 파서의 외부 엔티티 허용 (XXE)
- [ ] 클라우드 스토리지/DB가 공개 설정

## A06 Vulnerable and Outdated Components (CWE-1104)
- [ ] 알려진 취약점이 있는 의존성 (스캐너 결과 + 실제 도달 가능성 확인)
- [ ] 락 파일 없음 / 버전 미고정
- [ ] 유지보수 중단 패키지, 의심스러운 이름의 패키지 (typosquatting)

## A07 Identification and Authentication Failures (CWE-287, 384, 613, 307)
- [ ] JWT: `alg: none` 허용, 서명 미검증, 약한 시크릿, 만료 없음
- [ ] 세션 고정, 로그아웃 시 무효화 안 됨
- [ ] 약한 비밀번호 정책, 자격 증명 대입 방어 부재
- [ ] 인증 우회 가능한 경로 (헤더 신뢰, 디버그 백도어)

## A08 Software and Data Integrity Failures (CWE-502, 345)
- [ ] 안전하지 않은 역직렬화 (`pickle`, `yaml.load`, `node-serialize`, `eval` 기반)
- [ ] CI/CD: 서드파티 Action이 태그/브랜치로만 고정, `pull_request_target` 오용
- [ ] 무결성 검증 없는 업데이트/플러그인 로딩, CDN 스크립트 SRI 없음

## A09 Security Logging and Monitoring Failures (CWE-117, 532)
- [ ] 인증 실패/권한 거부/중요 변경이 로그에 남는가
- [ ] 로그에 비밀번호·토큰·주민번호·카드번호 등 민감정보
- [ ] 사용자 입력을 그대로 로그에 기록 (로그 인젝션)

## A10 Server-Side Request Forgery (CWE-918)
- [ ] 사용자 제공 URL로 서버가 요청 (webhook, 이미지 가져오기, 프록시)
- [ ] 내부 IP/메타데이터(169.254.169.254) 차단, 리다이렉트 추적 제한, DNS rebinding 고려

## 파일 업로드 / 기타
- [ ] 확장자·MIME·크기 검증, 저장 경로 고정, 실행 권한 없음, 파일명 정규화
- [ ] 개인정보(PII) 수집·저장·마스킹 처리
