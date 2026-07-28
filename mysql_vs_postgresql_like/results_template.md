# 결과 기록 템플릿 — MySQL vs PostgreSQL `%LIKE%`

## 환경

| 항목 | MySQL | PostgreSQL |
|------|-------|------------|
| 버전 | | |
| 호스트/포트 | | |
| product_rows | | |
| 희소 매칭 건수 (`희소토큰zxq`) | | |
| 흔한 매칭 건수 (`에어맥스`) | | |

## EXPLAIN (예상 계획)

### Sparse `LIKE '%희소토큰zxq%'` COUNT

| 항목 | MySQL | PostgreSQL |
|------|-------|------------|
| access / node type | | |
| estimated rows | | |
| Extra / Filter | | |

### Common `LIKE '%에어맥스%'` COUNT

| 항목 | MySQL | PostgreSQL |
|------|-------|------------|
| access / node type | | |
| estimated rows | | |
| Extra / Filter | | |

## EXPLAIN ANALYZE (실측)

### Sparse COUNT

| 항목 | MySQL | PostgreSQL |
|------|-------|------------|
| actual rows | | |
| actual time / Execution Time | | |
| loops | | |
| buffers (PG) | | |

### Common COUNT

| 항목 | MySQL | PostgreSQL |
|------|-------|------------|
| actual rows | | |
| actual time / Execution Time | | |
| loops | | |
| buffers (PG) | | |

## Runtime (선택, 03_*.sql)

| token | MySQL avg_ms | PostgreSQL avg_ms |
|-------|--------------|-------------------|
| SPARSE | | |
| COMMON | | |

## 관찰 메모

- leading `%` 때문에 양쪽 모두 full/seq scan 이었는가?
- 희소 vs 흔함에서 **스캔 비용은 비슷하고 필터 후 rows만 다른가?**
- LIMIT 20 list 쿼리에서 early stop / sort 비용 차이는?

```text
(추가 메모)
```
