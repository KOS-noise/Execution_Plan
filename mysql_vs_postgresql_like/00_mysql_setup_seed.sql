-- MySQL/MariaDB: explain_lab + product 100K 시드
-- 상위 00_local_standalone_setup.sql 과 동일 분포
--   희소: 희소토큰zxq (~0.1%)
--   흔함: 에어맥스 (~50%)
--   나머지: 일반신발

CREATE DATABASE IF NOT EXISTS explain_lab;
USE explain_lab;

SET NAMES utf8mb4 COLLATE utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS category (
    category_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL
);

CREATE TABLE IF NOT EXISTS store (
    store_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    store_name VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL
);

CREATE TABLE IF NOT EXISTS product (
    product_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
    price INT NOT NULL,
    stock INT NOT NULL DEFAULT 100,
    description TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
    image VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
    status CHAR(1) NOT NULL DEFAULT 'A',
    category_id BIGINT,
    store_id BIGINT,
    KEY idx_product_price (price),
    KEY idx_product_category (category_id),
    KEY idx_product_store (store_id)
);

INSERT INTO category (category_name)
SELECT '벤치카테고리'
WHERE NOT EXISTS (SELECT 1 FROM category);

INSERT INTO store (store_name)
SELECT '벤치스토어'
WHERE NOT EXISTS (SELECT 1 FROM store);

SET @target_rows := 100000;
SET @current_rows := (SELECT COUNT(*) FROM product);
SET @need_rows := GREATEST(@target_rows - @current_rows, 0);

DROP TEMPORARY TABLE IF EXISTS tmp_seq_100;
CREATE TEMPORARY TABLE tmp_seq_100 (n INT PRIMARY KEY);

INSERT INTO tmp_seq_100 (n)
WITH RECURSIVE cte AS (
    SELECT 0 AS n
    UNION ALL
    SELECT n + 1 FROM cte WHERE n < 99
)
SELECT n FROM cte;

DROP TEMPORARY TABLE IF EXISTS tmp_seq_1000;
CREATE TEMPORARY TABLE tmp_seq_1000 (n INT PRIMARY KEY);

INSERT INTO tmp_seq_1000 (n)
WITH RECURSIVE cte AS (
    SELECT 0 AS n
    UNION ALL
    SELECT n + 1 FROM cte WHERE n < 999
)
SELECT n FROM cte;

INSERT INTO product (name, price, stock, description, image, status, category_id, store_id)
SELECT
    CASE
        WHEN MOD(a.n * 100 + b.n, 1000) = 0 THEN CONCAT('희소토큰zxq 벤치 ', a.n, '-', b.n)
        WHEN MOD(a.n + b.n, 2) = 0 THEN CONCAT('에어맥스 벤치 ', a.n, '-', b.n)
        ELSE CONCAT('일반신발 벤치 ', a.n, '-', b.n)
    END AS name,
    10000 + (a.n * 100 + b.n) AS price,
    100 AS stock,
    'benchmark-seed' AS description,
    'bench.jpg' AS image,
    'A' AS status,
    (SELECT MIN(category_id) FROM category),
    (SELECT MIN(store_id) FROM store)
FROM tmp_seq_1000 a
CROSS JOIN tmp_seq_100 b
WHERE (a.n * 100 + b.n) < @need_rows;

-- 시드 검증
SELECT DATABASE() AS db_name, COUNT(*) AS product_rows FROM product;

SELECT '희소토큰zxq' AS token, COUNT(*) AS matched
FROM product WHERE name LIKE '%희소토큰zxq%'
UNION ALL
SELECT '에어맥스', COUNT(*)
FROM product WHERE name LIKE '%에어맥스%';
