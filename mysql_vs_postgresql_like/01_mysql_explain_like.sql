-- MySQL: %LIKE% 예상 계획 (EXPLAIN)
-- Run after: 00_mysql_setup_seed.sql

USE explain_lab;
SET NAMES utf8mb4 COLLATE utf8mb4_general_ci;
SET @kw_sparse := '%희소토큰zxq%';
SET @kw_common := '%에어맥스%';
SET @min_price := 0;
SET @max_price := 5000000;

SELECT '=== MySQL EXPLAIN: sparse LIKE COUNT ===' AS section;

EXPLAIN
SELECT COUNT(*) AS cnt
FROM product p
WHERE p.name LIKE @kw_sparse;

EXPLAIN FORMAT=JSON
SELECT COUNT(*) AS cnt
FROM product p
WHERE p.name LIKE @kw_sparse;

SELECT '=== MySQL EXPLAIN: common LIKE COUNT ===' AS section;

EXPLAIN
SELECT COUNT(*) AS cnt
FROM product p
WHERE p.name LIKE @kw_common;

EXPLAIN FORMAT=JSON
SELECT COUNT(*) AS cnt
FROM product p
WHERE p.name LIKE @kw_common;

SELECT '=== MySQL EXPLAIN: sparse LIKE list (LIMIT 20) ===' AS section;

EXPLAIN
SELECT p.product_id, p.name
FROM product p
LEFT JOIN category c ON p.category_id = c.category_id
WHERE p.name LIKE @kw_sparse
  AND p.price >= @min_price
  AND p.price <= @max_price
ORDER BY p.product_id DESC
LIMIT 20 OFFSET 0;

EXPLAIN FORMAT=JSON
SELECT p.product_id, p.name
FROM product p
LEFT JOIN category c ON p.category_id = c.category_id
WHERE p.name LIKE @kw_sparse
  AND p.price >= @min_price
  AND p.price <= @max_price
ORDER BY p.product_id DESC
LIMIT 20 OFFSET 0;

SELECT '=== MySQL EXPLAIN: common LIKE list (LIMIT 20) ===' AS section;

EXPLAIN
SELECT p.product_id, p.name
FROM product p
LEFT JOIN category c ON p.category_id = c.category_id
WHERE p.name LIKE @kw_common
  AND p.price >= @min_price
  AND p.price <= @max_price
ORDER BY p.product_id DESC
LIMIT 20 OFFSET 0;

-- 매칭 건수 정합
SELECT '희소토큰zxq' AS token, COUNT(*) AS matched
FROM product WHERE name LIKE @kw_sparse
UNION ALL
SELECT '에어맥스', COUNT(*)
FROM product WHERE name LIKE @kw_common;
