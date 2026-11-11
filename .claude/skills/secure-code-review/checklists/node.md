# Node.js / TypeScript 추가 체크리스트

## 위험 sink 검색 키워드 (Grep 시작점)
- 코드 실행: `eval(`, `new Function(`, `vm.runIn`, `setTimeout("`, `child_process`, `exec(`, `execSync(`, `spawn(.*shell:\s*true`
- SQL: `` query(`...${ ``, `query("..." +`, Sequelize `literal(`, `sequelize.query(` (replacements 미사용), Knex `.raw(`, Prisma `$queryRawUnsafe`, `$executeRawUnsafe`, TypeORM `query(` 문자열 결합
- NoSQL: `find(req.body`, `findOne(req.query`, `$where`, `$regex` 사용자 입력
- 경로: `fs.readFile(.*req`, `path.join(.*req` (정규화·prefix 검증 없음), `res.sendFile`, `express.static` 범위
- XSS: `innerHTML`, `dangerouslySetInnerHTML`, `v-html`, `res.send(` 에 사용자 입력 포함 HTML, `document.write`
- SSRF: `axios(`/`fetch(`/`got(`/`request(` 에 사용자 URL
- 역직렬화/템플릿: `node-serialize`, `serialize-javascript` 구버전, `ejs`/`pug`/`handlebars` render에 사용자 입력을 템플릿 문자열로 사용
- 정규식 DoS: 사용자 입력 대상 중첩 수량자 정규식 `(a+)+`
- 난수: `Math.random()` 로 토큰/비밀번호/ID 생성

## Node 특화 이슈
- [ ] **Prototype Pollution**: `lodash.merge/set/defaultsDeep`, 재귀 병합/`Object.assign` 에 사용자 JSON, `__proto__`/`constructor` 키 필터
- [ ] **Mass Assignment**: `Model.create(req.body)`, `update(req.body)` 로 role/isAdmin 등 덮어쓰기 가능
- [ ] **JWT** (`jsonwebtoken`): `verify` 시 `algorithms` 명시 여부, `decode`만 쓰고 검증 안 함, 시크릿 하드코딩, `expiresIn`
- [ ] **Express 설정**: `helmet` 사용, `app.disable('x-powered-by')`, `trust proxy` 적정, `cors({origin: true})`, body 크기 제한, rate limit(`express-rate-limit`), 에러 핸들러가 스택 노출
- [ ] **쿠키/세션**: `express-session` 의 `secret` 하드코딩, `cookie.secure/httpOnly/sameSite`, 기본 MemoryStore 운영 사용
- [ ] **CSRF**: 쿠키 기반 인증인데 `csurf` 류/SameSite 없음
- [ ] **입력 검증**: zod/joi/class-validator 등 스키마 검증이 라우트에 일관 적용되는가
- [ ] **NestJS**: Guard 누락된 컨트롤러, `@Public()` 남용, ValidationPipe `whitelist` 미설정
- [ ] **Next.js**: API route 인증 누락, `getServerSideProps` 에서 비밀 노출, `NEXT_PUBLIC_` 에 시크릿, SSRF(이미지 `remotePatterns`), 미들웨어 인증 우회
- [ ] **프론트(React/Vue)**: 토큰 localStorage 저장(XSS 시 탈취) 여부 판단, `target="_blank"` rel, `postMessage` origin 검증
- [ ] **의존성**: `package-lock.json` 존재, `postinstall` 스크립트가 있는 의심 패키지, `npm audit` 결과가 도달 가능한가
- [ ] **환경변수**: `.env` 커밋, `process.env` 미설정 시 기본값으로 약한 시크릿 사용 (`|| 'secret'`)
