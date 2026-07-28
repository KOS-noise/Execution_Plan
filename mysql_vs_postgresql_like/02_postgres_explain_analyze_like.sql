-- PostgreSQL: %LIKE% 실측 계획 (EXPLAIN ANALYZE + BUFFERS)
-- 주의: 쿼리가 실제로 1회 실행됨
-- psql -d explain_lab -f 02_postgres_explain_analyze_like.sql

\c explain_lab

\echo === PostgreSQL EXPLAIN ANALYZE: sparse LIKE COUNT ===

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT COUNT(*) AS cnt
FROM product p
WHERE p.name LIKE '%희소토큰zxq%';

\echo === PostgreSQL EXPLAIN ANALYZE: common LIKE COUNT ===

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT COUNT(*) AS cnt
FROM product p
WHERE p.name LIKE '%에어맥스%';

\echo === PostgreSQL EXPLAIN ANALYZE: sparse LIKE list (LIMIT 20) ===

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT p.product_id, p.name
FROM product p
LEFT JOIN category c ON p.category_id = c.category_id
WHERE p.name LIKE '%희소토큰zxq%'
  AND p.price >= 0
  AND p.price <= 5000000
ORDER BY p.product_id DESC
LIMIT 20 OFFSET 0;

\echo === PostgreSQL EXPLAIN ANALYZE: common LIKE list (LIMIT 20) ===

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT p.product_id, p.name
FROM product p
LEFT JOIN category c ON p.category_id = c.category_id
WHERE p.name LIKE '%에어맥스%'
  AND p.price >= 0
  AND p.price <= 5000000
ORDER BY p.product_id DESC
LIMIT 20 OFFSET 0;

-- JSON 실측 (발표용 붙여넣기 편리)
\echo === PostgreSQL EXPLAIN ANALYZE FORMAT JSON (sparse COUNT) ===

EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT COUNT(*) AS cnt
FROM product p
WHERE p.name LIKE '%희소토큰zxq%';
