# Python 추가 체크리스트

## 위험 sink 검색 키워드 (Grep 시작점)
- 코드 실행: `eval(`, `exec(`, `compile(`, `__import__(`
- 명령 실행: `os.system`, `os.popen`, `subprocess.*shell=True`, `commands.`
- SQL: `execute(f"`, `execute("..." %`, `execute("..." +`, `.format(` 쿼리, SQLAlchemy `text(f"`, Django `.raw(`, `.extra(`, `RawSQL(`
- 역직렬화: `pickle.load(s)`, `cPickle`, `yaml.load(` (SafeLoader 아님), `marshal.load`, `shelve`, `jsonpickle`
- 경로: `open(` / `send_file(` / `os.path.join(` 에 사용자 입력 (정규화·prefix 검증 없음), `zipfile.extractall` / `tarfile.extractall` (Zip Slip)
- SSRF: `requests.get(` / `urllib.request.urlopen(` / `httpx` 에 사용자 URL
- 템플릿: `render_template_string(` 사용자 입력, Jinja2 `Environment(autoescape=False)`, Django `|safe`, `mark_safe`
- XML: `xml.etree`, `lxml` (resolve_entities), `minidom` → `defusedxml` 권장
- 난수/암호: `random.` 로 토큰 생성 (`secrets` 사용해야 함), `hashlib.md5/sha1` 비밀번호, `Crypto.Cipher.DES`, ECB
- TLS: `verify=False`, `ssl._create_unverified_context`
- 디버그: `app.run(debug=True)`, Django `DEBUG = True`, `ALLOWED_HOSTS = ['*']`
- 정규식 DoS: 사용자 입력 대상 중첩 수량자

## Python 특화 이슈
- [ ] **Django**: `SECRET_KEY` 하드코딩, `CSRF_COOKIE_SECURE`/`SESSION_COOKIE_SECURE`, `@csrf_exempt` 남용, `permission_classes` 누락(DRF 기본이 AllowAny인 설정), `ModelSerializer` `fields='__all__'` 로 Mass Assignment, queryset이 `request.user` 로 필터되지 않음(IDOR)
- [ ] **Flask**: `SECRET_KEY` 약함/하드코딩, 세션 쿠키 플래그, 인증 데코레이터 누락 라우트, `send_file`/`send_from_directory` 경로, `Flask-CORS` 전체 허용
- [ ] **FastAPI**: `Depends(auth)` 누락 라우트, Pydantic 모델이 과도한 필드(role 등) 수용, CORS `allow_origins=["*"]` + credentials, `/docs` 운영 노출 여부
- [ ] **JWT** (`PyJWT`/`python-jose`): `decode` 시 `algorithms` 명시, `verify_signature=False`, 만료 검증
- [ ] **Celery/큐**: 직렬화 포맷 `pickle`, 브로커 인증 없음
- [ ] **파일 처리**: `tempfile.mktemp`(레이스) → `mkstemp`, 업로드 파일명 `secure_filename`, 이미지/PDF 파서 DoS(크기 제한)
- [ ] **ORM 우회**: `filter(**request.GET)`, `order_by(request.GET[...])` 로 필드/관계 노출
- [ ] **의존성**: `requirements.txt` 해시/버전 고정, `pip-audit` 결과의 도달 가능성, 사내 인덱스 대신 공개 PyPI 사용 시 dependency confusion
- [ ] **시크릿**: `os.environ.get('X', 'default-secret')`, `settings.py`/`config.py`/노트북(`.ipynb`) 출력 속 키
- [ ] **assert** 로 인증/검증 (`python -O` 에서 제거됨)
