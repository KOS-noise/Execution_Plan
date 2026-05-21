-- Run after:
--   USE explain_lab;
--   SOURCE .../00_local_standalone_setup.sql;
--
-- 목적:
-- 1) 희소 키워드(낮은 매칭률) 조건에서 LIKE vs FULLTEXT 비교
-- 2) 콘솔 출력 오버헤드 제거를 위해 COUNT(*) INTO 변수 방식 사용

SET NAMES utf8mb4 COLLATE utf8mb4_general_ci;
SET @kw_like := '%희소토큰zxq%';
SET @kw_ft := '+희소토큰zxq*';
SET @loops := 50;

DROP TEMPORARY TABLE IF EXISTS bench_result_sparse;
CREATE TEMPORARY TABLE bench_result_sparse (
    run_no INT,
    query_type VARCHAR(20),
    elapsed_ms DECIMAL(10,3),
    matched_rows INT
);

DROP PROCEDURE IF EXISTS run_sparse_search_bench;
DELIMITER //
CREATE PROCEDURE run_sparse_search_bench(IN in_loops INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE t0 DATETIME(6);
    DECLARE t1 DATETIME(6);
    DECLARE t2 DATETIME(6);
    DECLARE t3 DATETIME(6);
    DECLARE v_count INT;

    WHILE i <= in_loops DO
        -- LIKE timing
        SET t0 = NOW(6);
        SELECT SQL_NO_CACHE COUNT(*) INTO v_count
        FROM product p
        WHERE p.name LIKE @kw_like;
        SET t1 = NOW(6);

        INSERT INTO bench_result_sparse(run_no, query_type, elapsed_ms, matched_rows)
        VALUES (
            i,
            'LIKE',
            TIMESTAMPDIFF(MICROSECOND, t0, t1) / 1000.0,
            v_count
        );

        -- FULLTEXT timing
        SET t2 = NOW(6);
        SELECT SQL_NO_CACHE COUNT(*) INTO v_count
        FROM product p
        WHERE MATCH(p.name) AGAINST(@kw_ft IN BOOLEAN MODE);
        SET t3 = NOW(6);

        INSERT INTO bench_result_sparse(run_no, query_type, elapsed_ms, matched_rows)
        VALUES (
            i,
            'FULLTEXT',
            TIMESTAMPDIFF(MICROSECOND, t2, t3) / 1000.0,
            v_count
        );

        SET i = i + 1;
    END WHILE;
END //
DELIMITER ;

CALL run_sparse_search_bench(@loops);
DROP PROCEDURE IF EXISTS run_sparse_search_bench;

-- 요약 통계
SELECT
    query_type,
    ROUND(AVG(elapsed_ms), 3) AS avg_ms,
    ROUND(MIN(elapsed_ms), 3) AS min_ms,
    ROUND(MAX(elapsed_ms), 3) AS max_ms,
    MIN(matched_rows) AS matched_rows
FROM bench_result_sparse
GROUP BY query_type;

-- 개선율 계산
SELECT
    ROUND(
        (
            (SELECT AVG(elapsed_ms) FROM bench_result_sparse WHERE query_type = 'LIKE') -
            (SELECT AVG(elapsed_ms) FROM bench_result_sparse WHERE query_type = 'FULLTEXT')
        ) /
        (SELECT AVG(elapsed_ms) FROM bench_result_sparse WHERE query_type = 'LIKE') * 100,
        2
    ) AS improvement_percent;

