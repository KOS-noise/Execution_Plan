-- 팀 원격 DB 없이, 로컬 MariaDB에서 단독 벤치 실행용
-- 사용 DB: explain_lab (없으면 생성)
-- 기본 목표: 100,000 rows (희소 키워드 비교가 가능하도록 데이터 확장)

CREATE DATABASE IF NOT EXISTS explain_lab;
USE explain_lab;

-- 클라이언트/리터럴과 컬럼 charset 정합 (LIKE / 변수 혼합 시 collation 오류 방지)
SET NAMES utf8mb4 COLLATE utf8mb4_general_ci;

-- 최소 스키마 준비 (벤치에 필요한 컬럼만)
-- 기존 DB가 euckr 등으로 만들어졌다면: DROP DATABASE explain_lab; 후 재실행 권장
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

-- FULLTEXT 인덱스 보장
SET @has_ft := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'product'
      AND index_name = 'ft_product_name'
);

SET @sql_create_ft := IF(
    @has_ft = 0,
    'ALTER TABLE product ADD FULLTEXT INDEX ft_product_name (name)',
    'SELECT ''FULLTEXT index already exists'' AS msg'
);
PREPARE stmt FROM @sql_create_ft;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 100K 행까지 더미 데이터 채우기
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
        -- 희소 키워드 (약 0.1%)를 섞어 선택도 높은 검색 시나리오 생성
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

SELECT DATABASE() AS db_name, COUNT(*) AS product_rows FROM product;

