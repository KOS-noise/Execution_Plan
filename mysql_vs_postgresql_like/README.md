# MySQL vs PostgreSQL — `%LIKE%` 성능 비교

상위 `Execution_Plan`과 **동일 데이터·동일 LIKE 조건**으로, MySQL과 PostgreSQL의  
`EXPLAIN` / `EXPLAIN ANALYZE` 결과를 나란히 비교하기 위한 실험입니다.

> 이 실험의 초점은 FULLTEXT가 아니라 `name LIKE '%키워드%'` **(leading wildcard)** 입니다.

## 분석 조건 (공통)


| 항목    | 값                                            |
| ----- | -------------------------------------------- |
| DB명   | `explain_lab`                                |
| 테이블   | `product` (+ `category`, `store`)            |
| 목표 건수 | **100,000** rows                             |
| 흔한 토큰 | `에어맥스` (이름에 약 50% 포함)                        |
| 희소 토큰 | `희소토큰zxq` (약 **0.1%**, `MOD(..., 1000) = 0`) |
| 쿼리 A  | `WHERE name LIKE '%희소토큰zxq%'` + `COUNT(*)`   |
| 쿼리 B  | `WHERE name LIKE '%에어맥스%'` + `COUNT(*)`      |
| 부가    | `LIMIT 20` 목록형 LIKE (페이지 검색 패턴)              |


시드 로직은 `00_local_standalone_setup.sql` 과 동일합니다.

## 폴더 구성


| 파일                                     | 역할                                             |
| -------------------------------------- | ---------------------------------------------- |
| `00_mysql_setup_seed.sql`              | MySQL/MariaDB 스키마 + 100K 시드                    |
| `00_postgres_setup_seed.sql`           | PostgreSQL 스키마 + 100K 시드                       |
| `01_mysql_explain_like.sql`            | MySQL `EXPLAIN` / `EXPLAIN FORMAT=JSON`        |
| `01_postgres_explain_like.sql`         | PostgreSQL `EXPLAIN` / `EXPLAIN (FORMAT JSON)` |
| `02_mysql_explain_analyze_like.sql`    | MySQL 8.0.18+ `EXPLAIN ANALYZE`                |
| `02_postgres_explain_analyze_like.sql` | PostgreSQL `EXPLAIN (ANALYZE, BUFFERS)`        |
| `03_mysql_runtime_like.sql`            | MySQL 반복 시간 측정 (선택)                            |
| `03_postgres_runtime_like.sql`         | PostgreSQL 반복 시간 측정 (선택)                       |
| `results_template.md`                  | 결과 기록 템플릿                                      |




## 실행 순서



### 1) 시드

**MySQL (Docker `explain-mysql` 권장 — 로컬에 MySQL8 없을 때):**

```powershell
docker run -d --name explain-mysql -e MYSQL_ALLOW_EMPTY_PASSWORD=yes -e MYSQL_DATABASE=explain_lab -p 3307:3306 mysql:8.4
# ready 후
docker cp .\00_mysql_setup_seed.sql explain-mysql:/tmp/00_seed.sql
docker exec -i explain-mysql mysql -uroot --default-character-set=utf8mb4 -e "source /tmp/00_seed.sql"
# 또는 한 번에: .\run_mysql_docker.bat
```

**PostgreSQL (Docker — PowerShell 파이프 대신 `docker cp` 권장):**


```powershell
docker cp .\00_postgres_setup_seed.sql explain-pg:/tmp/00_seed.sql
docker exec -i explain-pg psql -U postgres -f /tmp/00_seed.sql
```

> `Get-Content ... | docker exec` 는 PowerShell이 UTF-16으로 보내서 `syntax error at or near "-"` 가 날 수 있습니다.



### 2) 예상 계획 (EXPLAIN)

```powershell
# MySQL
mysql -h 127.0.0.1 -P 3307 -u root explain_lab -e "source 01_mysql_explain_like.sql"

# PostgreSQL (Docker)
docker cp .\01_postgres_explain_like.sql explain-pg:/tmp/01_explain.sql
docker exec -i explain-pg psql -U postgres -d explain_lab -f /tmp/01_explain.sql
```

### 3) 실측 계획 (EXPLAIN ANALYZE)

```powershell
docker cp .\02_postgres_explain_analyze_like.sql explain-pg:/tmp/02_analyze.sql
docker exec -i explain-pg psql -U postgres -d explain_lab -f /tmp/02_analyze.sql
```

### 4) (선택) 런타임 ms

```powershell
docker cp .\03_postgres_runtime_like.sql explain-pg:/tmp/03_runtime.sql
docker exec -i explain-pg psql -U postgres -d explain_lab -f /tmp/03_runtime.sql
```



## 비교 시 볼 포인트

1. **access type / Seq Scan** — leading `%` 때문에 B-tree 인덱스를 못 타는지
2. **rows (예상) vs actual rows** — 희소 vs 흔한 토큰의 선택도 차이
3. **Execution Time / actual time** — 엔진별 실측 비용
4. **Buffers (PostgreSQL)** — shared hit/read 차이



## 주의

- MySQL `EXPLAIN ANALYZE`는 **8.0.18+**. MariaDB는 `ANALYZE SELECT ...` (상위 `07_*.sql` 참고).
- 두 DB를 같은 머신·비슷한 디스크에서 돌릴 것. 절대 시간보다 **엔진 내 희소/흔한 비율**과 **계획 형태**를 먼저 비교.
- PostgreSQL에 `pg_trgm` GIN을 붙이면 `%LIKE%`가 빨라질 수 있음. **기본 실험은 인덱스 없이** 공정 비교하고, 개선안은 별도로 추가하세요.

