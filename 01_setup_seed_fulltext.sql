-- Run after: USE <your_database>;
-- 목적:
-- 1) product.name FULLTEXT 인덱스 보장
-- 2) 벤치용 데이터가 100,000건 미만이면 더미 데이터 보강

SET @target_rows := 100000;

-- 현재 데이터 확인
SELECT COUNT(*) AS current_rows FROM product;

-- FULLTEXT 인덱스 생성 (없으면)
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

-- category_id 기본값 확보
SET @fallback_category_id := (
    SELECT MIN(category_id) FROM category
);

-- 숫자 시퀀스용 임시 테이블: 0..999, 0..99 → CROSS JOIN 최대 100,000행
DROP TEMPORARY TABLE IF EXISTS tmp_seq_1000;
CREATE TEMPORARY TABLE tmp_seq_1000 (n INT PRIMARY KEY);

INSERT INTO tmp_seq_1000 (n)
WITH RECURSIVE cte AS (
    SELECT 0 AS n
    UNION ALL
    SELECT n + 1 FROM cte WHERE n < 999
)
SELECT n FROM cte;

DROP TEMPORARY TABLE IF EXISTS tmp_seq_100;
CREATE TEMPORARY TABLE tmp_seq_100 (n INT PRIMARY KEY);

INSERT INTO tmp_seq_100 (n)
WITH RECURSIVE cte AS (
    SELECT 0 AS n
    UNION ALL
    SELECT n + 1 FROM cte WHERE n < 99
)
SELECT n FROM cte;

-- 부족한 건수 계산
SET @current_rows := (SELECT COUNT(*) FROM product);
SET @need_rows := GREATEST(@target_rows - @current_rows, 0);

-- 부족할 때만 더미 insert
-- 1,000 x 100 = 100,000 조합 중 필요한 수만큼 삽입
INSERT INTO product (name, price, stock, description, image, status, category_id, store_id)
SELECT
    CASE
        WHEN MOD(a.n + b.n, 2) = 0 THEN CONCAT('에어맥스 벤치 ', a.n, '-', b.n)
        ELSE CONCAT('일반신발 벤치 ', a.n, '-', b.n)
    END AS name,
    10000 + (a.n * 1000 + b.n) AS price,
    100 AS stock,
    'benchmark-seed' AS description,
    'bench.jpg' AS image,
    'A' AS status,
    @fallback_category_id AS category_id,
    (SELECT MIN(store_id) FROM store) AS store_id
FROM tmp_seq_1000 a
CROSS JOIN tmp_seq_100 b
LIMIT @need_rows;

SELECT COUNT(*) AS final_rows FROM product;

-- 인덱스 상태 재확인
SHOW INDEX FROM product;
