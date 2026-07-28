# 실측 비교 결과 — MySQL 8.4 vs PostgreSQL 16 (`%LIKE%`)

환경: Docker Desktop / 동일 머신  
데이터: `explain_lab.product` **100,000** rows  
매칭: 희소 `희소토큰zxq` = **100** / 흔함 `에어맥스` = **49,900**

컨테이너:

- `explain-mysql` (mysql:8.4, port 3307)
- `explain-pg` (postgres:16, port 5432)

측정: 각자 쉘에서 `02_*_explain_analyze_like.sql` 실행 결과

---

## COUNT(*) — leading `%LIKE%`


| 항목             | MySQL 8.4 (쉘 실측)        | PostgreSQL 16 (쉘 실측)       |
| -------------- | ----------------------- | -------------------------- |
| 희소 access      | **Table scan** + Filter | **Seq Scan** + Filter      |
| 희소 actual rows | 100 / 100000 scanned    | 100 / Rows Removed 99900   |
| 희소 actual time | **23.1 ms**             | **12.433 ms**              |
| 흔함 access      | **Table scan** + Filter | **Seq Scan** + Filter      |
| 흔함 actual rows | 49900 / 100000 scanned  | 49900 / Rows Removed 50100 |
| 흔함 actual time | **24.7 ms**             | **18.636 ms**              |


관찰:

- 양쪽 모두 leading `%` 때문에 **인덱스 없이 풀스캔**
- 희소/흔함 모두 스캔량은 전체 테이블 → COUNT 시간은 비슷 (매칭 수보다 스캔이 지배)
- 이 환경에서는 PostgreSQL COUNT가 더 짧음 (절대값은 캐시·머신에 따라 변동)

---

## LIMIT 20 + ORDER BY product_id DESC


| 항목                   | MySQL 8.4 (쉘 실측)                        | PostgreSQL 16 (쉘 실측)                    |
| -------------------- | --------------------------------------- | --------------------------------------- |
| 희소 access            | **PRIMARY reverse index scan** + Filter | **Seq Scan** → top-N Sort               |
| 희소 scanned / matched | reverse **19901** rows → 20             | Seq Scan **100** → Sort                 |
| 희소 actual time       | **7.66 ms**                             | **10.597 ms**                           |
| 흔함 access            | **PRIMARY reverse index scan** + Filter | **Index Scan Backward (pkey)** + Filter |
| 흔함 scanned           | reverse **40** rows → 20                | Filter removed 19                       |
| 흔함 actual time       | **0.04 ms**                             | **0.041 ms**                            |


관찰:

- **흔한 토큰 + LIMIT 20 + PK 역순**이면 양 엔진 모두 early stop → **매우 빠름 (~0.04 ms)**
- **희소 토큰**은 매칭이 드물어, MySQL은 PK 역순으로 많이 훑고(19901행), PG는 전량 Seq Scan 후 Sort
- COUNT와 목록(LIMIT)의 계획이 **완전히 다를 수 있음** → 벤치는 실제 API 쿼리 형태와 맞춰야 함

---

## MySQL 원문 (쉘 `source /tmp/02_analyze.sql`)

### sparse LIKE COUNT — 23.1 ms

```text
-> Aggregate: count(0)  (cost=11242 rows=1) (actual time=23.1..23.1 rows=1 loops=1)
    -> Filter: (p.`name` like '%희소토큰zxq%')  (cost=10137 rows=11057) (actual time=0.0511..23 rows=100 loops=1)
        -> Table scan on p  (cost=10137 rows=99524) (actual time=0.0249..12.2 rows=100000 loops=1)
```

### common LIKE COUNT — 24.7 ms

```text
-> Aggregate: count(0)  (cost=11242 rows=1) (actual time=24.7..24.7 rows=1 loops=1)
    -> Filter: (p.`name` like '%에어맥스%')  (cost=10137 rows=11057) (actual time=0.0217..23.1 rows=49900 loops=1)
        -> Table scan on p  (cost=10137 rows=99524) (actual time=0.0197..12.7 rows=100000 loops=1)
```

### sparse LIKE list LIMIT 20 — 7.66 ms

```text
-> Limit: 20 row(s)  (cost=1386 rows=2.22) (actual time=0.368..7.66 rows=20 loops=1)
    -> Nested loop left join  (cost=1386 rows=2.22) (actual time=0.367..7.66 rows=20 loops=1)
        -> Filter: ((p.`name` like '%희소토큰zxq%') and (p.price >= 0) and (p.price <= 5000000))  (cost=3.85 rows=2.22) (actual time=0.361..7.64 rows=20 loops=1)
            -> Index scan on p using PRIMARY (reverse)  (cost=3.85 rows=40) (actual time=0.00986..5.39 rows=19901 loops=1)
        -> Single-row covering index lookup on c using PRIMARY (category_id=p.category_id)  (cost=0.25 rows=1) (actual time=491e-6..514e-6 rows=1 loops=20)
```

### common LIKE list LIMIT 20 — 0.04 ms

```text
-> Limit: 20 row(s)  (cost=1386 rows=2.22) (actual time=0.02..0.04 rows=20 loops=1)
    -> Nested loop left join  (cost=1386 rows=2.22) (actual time=0.0195..0.0388 rows=20 loops=1)
        -> Filter: ((p.`name` like '%에어맥스%') and (p.price >= 0) and (p.price <= 5000000))  (cost=3.85 rows=2.22) (actual time=0.0156..0.0312 rows=20 loops=1)
            -> Index scan on p using PRIMARY (reverse)  (cost=3.85 rows=40) (actual time=0.0107..0.0218 rows=40 loops=1)
        -> Single-row covering index lookup on c using PRIMARY (category_id=p.category_id)  (cost=0.25 rows=1) (actual time=214e-6..233e-6 rows=1 loops=20)
```

### (참고) `--raw --table` 단일 쿼리 재실행 — sparse COUNT 22.8 ms

```text
-> Aggregate: count(0)  (cost=11242 rows=1) (actual time=22.8..22.8 rows=1 loops=1)
    -> Filter: (p.`name` like '%희소토큰zxq%')  (cost=10137 rows=11057) (actual time=0.0465..22.8 rows=100 loops=1)
        -> Table scan on p  (cost=10137 rows=99524) (actual time=0.0259..12.3 rows=100000 loops=1)
```

---

## PostgreSQL 원문 (쉘 `/tmp/02_analyze.sql`)

### sparse LIKE COUNT — 12.433 ms

```text
Aggregate  (cost=2679.03..2679.04 rows=1 width=8) (actual time=12.382..12.384 rows=1 loops=1)
  Buffers: shared hit=1429
  ->  Seq Scan on product p  (cost=0.00..2679.00 rows=10 width=0) (actual time=0.006..12.372 rows=100 loops=1)
        Filter: ((name)::text ~~ '%희소토큰zxq%'::text)
        Rows Removed by Filter: 99900
        Buffers: shared hit=1429
Planning Time: 0.321 ms
Execution Time: 12.433 ms
```

### common LIKE COUNT — 18.636 ms

```text
Aggregate  (cost=2820.41..2820.43 rows=1 width=8) (actual time=18.613..18.615 rows=1 loops=1)
  Buffers: shared hit=1429
  ->  Seq Scan on product p  (cost=0.00..2679.00 rows=56566 width=0) (actual time=0.007..15.605 rows=49900 loops=1)
        Filter: ((name)::text ~~ '%에어맥스%'::text)
        Rows Removed by Filter: 50100
        Buffers: shared hit=1429
Planning Time: 0.075 ms
Execution Time: 18.636 ms
```

### sparse LIKE list LIMIT 20 — 10.597 ms

```text
Limit  (cost=3179.17..3179.19 rows=10 width=34) (actual time=10.571..10.575 rows=20 loops=1)
  Buffers: shared hit=1432
  ->  Sort  (cost=3179.17..3179.19 rows=10 width=34) (actual time=10.569..10.572 rows=20 loops=1)
        Sort Key: p.product_id DESC
        Sort Method: top-N heapsort  Memory: 27kB
        Buffers: shared hit=1432
        ->  Seq Scan on product p  (cost=0.00..3179.00 rows=10 width=34) (actual time=0.006..10.522 rows=100 loops=1)
              Filter: (((name)::text ~~ '%희소토큰zxq%'::text) AND (price >= 0) AND (price <= 5000000))
              Rows Removed by Filter: 99900
              Buffers: shared hit=1429
Planning Time: 0.301 ms
Execution Time: 10.597 ms
```

### common LIKE list LIMIT 20 — 0.041 ms

```text
Limit  (cost=0.29..1.98 rows=20 width=34) (actual time=0.012..0.025 rows=20 loops=1)
  Buffers: shared hit=3
  ->  Index Scan Backward using product_pkey on product p  (cost=0.29..4786.29 rows=56566 width=34) (actual time=0.012..0.023 rows=20 loops=1)
        Filter: (((name)::text ~~ '%에어맥스%'::text) AND (price >= 0) AND (price <= 5000000))
        Rows Removed by Filter: 19
        Buffers: shared hit=3
Planning Time: 0.175 ms
Execution Time: 0.041 ms
```

---

## 한 줄 결론

> `%LIKE%` **COUNT/집계**는 MySQL·PostgreSQL 모두 풀스캔이라 선택도와 무관하게 비싸고,  
> `%LIKE%` **최신순 LIMIT 목록**은 흔한 키워드에서만 인덱스 역순 early stop으로 빨라진다.

---

## 재실행

```powershell
cd C:\FINAL\Execution_Plan\mysql_vs_postgresql_like

# MySQL
docker cp .\02_mysql_explain_analyze_like.sql explain-mysql:/tmp/02_analyze.sql
docker exec -i explain-mysql mysql -uroot --default-character-set=utf8mb4 -e "source /tmp/02_analyze.sql"

# PostgreSQL
docker cp .\02_postgres_explain_analyze_like.sql explain-pg:/tmp/02_analyze.sql
docker exec -i explain-pg psql -U postgres -d explain_lab -f /tmp/02_analyze.sql
```

