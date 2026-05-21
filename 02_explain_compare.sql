-- Run after: USE <your_database>;
-- 목적: 실행 계획 관점에서 LIKE vs FULLTEXT 비교

SET @kw_like := '%에어맥스%';
SET @kw_ft := '+에어맥스*';
SET @min_price := 0;
SET @max_price := 5000000;

-- A) LIKE 기반 검색 (기존 패턴 스캔 가정)
EXPLAIN FORMAT=JSON
SELECT p.product_id, p.name
FROM product p
LEFT JOIN category c ON p.category_id = c.category_id
WHERE p.name LIKE @kw_like
  AND p.price >= @min_price
  AND p.price <= @max_price
ORDER BY p.product_id DESC
LIMIT 20 OFFSET 0;

-- B) FULLTEXT 기반 검색 (현재 코드 방식)
EXPLAIN FORMAT=JSON
SELECT p.product_id, p.name
FROM product p
LEFT JOIN category c ON p.category_id = c.category_id
WHERE MATCH(p.name) AGAINST(@kw_ft IN BOOLEAN MODE)
  AND p.price >= @min_price
  AND p.price <= @max_price
ORDER BY p.product_id DESC
LIMIT 20 OFFSET 0;

-- C) 페이지네이션 countQuery 정합성 확인 (코드와 동일 조건)
SELECT COUNT(*) AS total_like
FROM product p
LEFT JOIN category c ON p.category_id = c.category_id
WHERE p.name LIKE @kw_like
  AND p.price >= @min_price
  AND p.price <= @max_price;

SELECT COUNT(*) AS total_fulltext
FROM product p
LEFT JOIN category c ON p.category_id = c.category_id
WHERE MATCH(p.name) AGAINST(@kw_ft IN BOOLEAN MODE)
  AND p.price >= @min_price
  AND p.price <= @max_price;

