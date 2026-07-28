-- PostgreSQL: explain_lab + product 100K 시드
-- MySQL 00_mysql_setup_seed.sql 과 동일 분포
--   희소: 희소토큰zxq (~0.1%)
--   흔함: 에어맥스 (~50%)
--   나머지: 일반신발
--
-- 실행: psql -h 127.0.0.1 -U postgres -f 00_postgres_setup_seed.sql

SELECT 'CREATE DATABASE explain_lab'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'explain_lab')\gexec

\c explain_lab

CREATE TABLE IF NOT EXISTS category (
    category_id BIGSERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS store (
    store_id BIGSERIAL PRIMARY KEY,
    store_name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS product (
    product_id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price INT NOT NULL,
    stock INT NOT NULL DEFAULT 100,
    description TEXT,
    image VARCHAR(255),
    status CHAR(1) NOT NULL DEFAULT 'A',
    category_id BIGINT,
    store_id BIGINT
);

CREATE INDEX IF NOT EXISTS idx_product_price ON product (price);
CREATE INDEX IF NOT EXISTS idx_product_category ON product (category_id);
CREATE INDEX IF NOT EXISTS idx_product_store ON product (store_id);

INSERT INTO category (category_name)
SELECT '벤치카테고리'
WHERE NOT EXISTS (SELECT 1 FROM category);

INSERT INTO store (store_name)
SELECT '벤치스토어'
WHERE NOT EXISTS (SELECT 1 FROM store);

DO $$
DECLARE
    target_rows INT := 100000;
    current_rows INT;
    need_rows INT;
    cat_id BIGINT;
    sto_id BIGINT;
BEGIN
    SELECT COUNT(*) INTO current_rows FROM product;
    need_rows := GREATEST(target_rows - current_rows, 0);
    SELECT MIN(category_id) INTO cat_id FROM category;
    SELECT MIN(store_id) INTO sto_id FROM store;

    -- MySQL 00 과 동일: a(0..999) x b(0..99), MOD(a*100+b,1000)=0 희소 / MOD(a+b,2)=0 흔함
    IF need_rows > 0 THEN
        INSERT INTO product (name, price, stock, description, image, status, category_id, store_id)
        SELECT
            CASE
                WHEN MOD(a * 100 + b, 1000) = 0 THEN format('희소토큰zxq 벤치 %s-%s', a, b)
                WHEN MOD(a + b, 2) = 0 THEN format('에어맥스 벤치 %s-%s', a, b)
                ELSE format('일반신발 벤치 %s-%s', a, b)
            END,
            10000 + (a * 100 + b),
            100,
            'benchmark-seed',
            'bench.jpg',
            'A',
            cat_id,
            sto_id
        FROM generate_series(0, 999) AS a
        CROSS JOIN generate_series(0, 99) AS b
        WHERE (a * 100 + b) < need_rows;
    END IF;
END $$;

ANALYZE product;

SELECT current_database() AS db_name, COUNT(*) AS product_rows FROM product;

SELECT '희소토큰zxq' AS token, COUNT(*) AS matched
FROM product WHERE name LIKE '%희소토큰zxq%'
UNION ALL
SELECT '에어맥스', COUNT(*)
FROM product WHERE name LIKE '%에어맥스%';
