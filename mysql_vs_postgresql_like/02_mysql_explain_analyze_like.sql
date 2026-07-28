-- MySQL 8.0.18+: %LIKE% 실측 계획 (EXPLAIN ANALYZE)
-- PostgreSQL 02 와 동일 조건(리터럴 LIKE, COUNT / LIMIT 20)
-- Docker: docker cp 후 mysql -uroot source

USE explain_lab;
SET NAMES utf8mb4 COLLATE utf8mb4_general_ci;

SELECT '=== MySQL EXPLAIN ANALYZE: sparse LIKE COUNT ===' AS section;

EXPLAIN ANALYZE
SELECT COUNT(*) AS cnt
FROM product p
WHERE p.name LIKE '%희소토큰zxq%';

SELECT '=== MySQL EXPLAIN ANALYZE: common LIKE COUNT ===' AS section;

EXPLAIN ANALYZE
SELECT COUNT(*) AS cnt
FROM product p
WHERE p.name LIKE '%에어맥스%';

SELECT '=== MySQL EXPLAIN ANALYZE: sparse LIKE list (LIMIT 20) ===' AS section;

EXPLAIN ANALYZE
SELECT p.product_id, p.name
FROM product p
LEFT JOIN category c ON p.category_id = c.category_id
WHERE p.name LIKE '%희소토큰zxq%'
  AND p.price >= 0
  AND p.price <= 5000000
ORDER BY p.product_id DESC
LIMIT 20 OFFSET 0;

SELECT '=== MySQL EXPLAIN ANALYZE: common LIKE list (LIMIT 20) ===' AS section;

EXPLAIN ANALYZE
SELECT p.product_id, p.name
FROM product p
LEFT JOIN category c ON p.category_id = c.category_id
WHERE p.name LIKE '%에어맥스%'
  AND p.price >= 0
  AND p.price <= 5000000
ORDER BY p.product_id DESC
LIMIT 20 OFFSET 0;
