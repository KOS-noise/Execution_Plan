# Product Search Benchmark (MySQL)

이 폴더는 `LIKE` 검색과 `FULLTEXT(MATCH ... AGAINST)` 검색의 차이를 비교하기 위한 실측 SQL 모음입니다.

## 대상

- 테이블: `product`
- 비교 쿼리
  - 기존 가정: `name LIKE '%에어맥스%'`
  - 개선 방식: `MATCH(name) AGAINST('+에어맥스*' IN BOOLEAN MODE)`

## 실행 전 준비

1. MySQL 8.0+ 접속
2. 이커머스 DB 선택 (`USE <db_name>;`)

### Windows: MySQL84 서비스가 안 뜰 때 (MariaDB와 3306 충돌)

- 증상: `net start MySQL84` → NET HELPMSG 3534  
- 원인: **3306을 MariaDB가 이미 사용**하거나, **데이터 디렉터리 미초기화**  
- 조치: `windows/setup-mysql84-admin.bat` 을 **관리자 권한**으로 실행  
  - MySQL은 **3307**, 데이터는 **`C:\mysql84\data`**, 설정은 **`C:\mysql84\my.ini`**  
  - 초기 root 비밀번호 없음(`--initialize-insecure`) — 로컬 전용  
- 접속: `mysql -h 127.0.0.1 -P 3307 -u root`  
- 이후 `SOURCE` 로 `00` … 벤치 SQL 은 **반드시 `-P 3307`** 으로 같은 인스턴스에 붙일 것
3. `product` 테이블에 최소 컬럼 존재 확인
   - `product_id`, `name`, `price`, `category_id`

## 실행 순서

1. `01_setup_seed_fulltext.sql`
   - FULLTEXT 인덱스 생성(없으면)
   - 벤치용 더미 데이터 보강(약 100K 건까지)
2. `02_explain_compare.sql`
   - `EXPLAIN FORMAT=JSON`으로 LIKE vs FULLTEXT 예상 계획 비교 (에어맥스 + 조인/가격 조건)
3. `03_runtime_compare.sql`
   - 반복 실행으로 응답시간(ms) 비교
4. `04_runtime_selective_compare.sql`
   - 희소 키워드 조건에서 출력 오버헤드를 제거한 시간 비교
5. `06_explain_analyze_sparse_compare.sql`
   - `04`와 동일 조건으로 `EXPLAIN` / `EXPLAIN FORMAT=JSON` 비교 (발표·Plan 관점용)
6. `07_explain_analyze_sparse_optional.sql` (선택)
   - 실측 통계: **MariaDB**는 `ANALYZE SELECT ...`, **MySQL 8.0.18+**는 파일 주석의 `EXPLAIN ANALYZE` 사용
7. `05_api_route_benchmark.ps1`
   - 서비스 분기(before/after) 전환 기준 API 응답시간 비교

## 결과 기록 템플릿

- 데이터 건수: `_____ rows`
- LIKE (평균): `_____ ms`
- FULLTEXT (평균): `_____ ms`
- 개선율: `_____ %`
- EXPLAIN rows 비교: `LIKE _____ vs FULLTEXT _____`

희소 키워드 벤치(`04`)를 썼다면:

- LIKE (희소, 평균): `_____ ms`
- FULLTEXT (희소, 평균): `_____ ms`
- 개선율(희소): `_____ %`

개선율 계산식:

`(LIKE평균 - FULLTEXT평균) / LIKE평균 * 100`

## 코드 반영 전/후 API 비교 (서비스 분기 기준)

`ProductServiceImpl`에는 아래 런타임 옵션이 있습니다.

- `app.product.search.filter-aware-routing=false` : 변경 전(before) 분기
- `app.product.search.filter-aware-routing=true` : 변경 후(after) 분기 (기본값)

실행 예시:

1) 서버를 before 모드로 실행
- `./gradlew bootRun --args='--app.product.search.filter-aware-routing=false'`

2) 벤치 스크립트 실행
- `powershell -ExecutionPolicy Bypass -File .\docs\sql-benchmark\05_api_route_benchmark.ps1`

3) 스크립트 안내에 따라 서버를 after 모드로 재실행 후 Enter
- `./gradlew bootRun --args='--app.product.search.filter-aware-routing=true'`

출력 지표:

- 평균(ms), 중앙값(ms), P95(ms), 평균 개선율(%)


