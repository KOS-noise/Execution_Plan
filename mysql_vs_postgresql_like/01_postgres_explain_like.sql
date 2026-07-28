-- PostgreSQL: %LIKE% 예상 계획 (EXPLAIN)
-- Run after: 00_postgres_setup_seed.sql
-- psql -d explain_lab -f 01_postgres_explain_like.sql

\c explain_lab

\echo === PostgreSQL EXPLAIN: sparse LIKE COUNT ===

EXPLAIN
SELECT COUNT(*) AS cnt
FROM product p
WHERE p.name LIKE '%희소토큰zxq%';

EXPLAIN (FORMAT JSON)
SELECT COUNT(*) AS cnt
FROM product p
WHERE p.name LIKE '%희소토큰zxq%';

\echo === PostgreSQL EXPLAIN: common LIKE COUNT ===

EXPLAIN
SELECT COUNT(*) AS cnt
FROM product p
WHERE p.name LIKE '%에어맥스%';

EXPLAIN (FORMAT JSON)
SELECT COUNT(*) AS cnt
FROM product p
WHERE p.name LIKE '%에어맥스%';

\echo === PostgreSQL EXPLAIN: sparse LIKE list (LIMIT 20) ===

EXPLAIN
SELECT p.product_id, p.name
FROM product p
LEFT JOIN category c ON p.category_id = c.category_id
WHERE p.name LIKE '%희소토큰zxq%'
  AND p.price >= 0
  AND p.price <= 5000000
ORDER BY p.product_id DESC
LIMIT 20 OFFSET 0;

EXPLAIN (FORMAT JSON)
SELECT p.product_id, p.name
FROM product p
LEFT JOIN category c ON p.category_id = c.category_id
WHERE p.name LIKE '%희소토큰zxq%'
  AND p.price >= 0
  AND p.price <= 5000000
ORDER BY p.product_id DESC
LIMIT 20 OFFSET 0;

\echo === PostgreSQL EXPLAIN: common LIKE list (LIMIT 20) ===

EXPLAIN
SELECT p.product_id, p.name
FROM product p
LEFT JOIN category c ON p.category_id = c.category_id
WHERE p.name LIKE '%에어맥스%'
  AND p.price >= 0
  AND p.price <= 5000000
ORDER BY p.product_id DESC
LIMIT 20 OFFSET 0;

-- 매칭 건수 정합
SELECT '희소토큰zxq' AS token, COUNT(*) AS matched
FROM product WHERE name LIKE '%희소토큰zxq%'
UNION ALL
SELECT '에어맥스', COUNT(*)
FROM product WHERE name LIKE '%에어맥스%';
