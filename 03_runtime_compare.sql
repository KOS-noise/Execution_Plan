-- Run after: USE <your_database>;
-- 목적: 반복 실행으로 LIKE vs FULLTEXT 평균 시간(ms) 비교

SET @kw_like := '%에어맥스%';
SET @kw_ft := '+에어맥스*';
SET @loops := 30;

DROP TEMPORARY TABLE IF EXISTS bench_result;
CREATE TEMPORARY TABLE bench_result (
    run_no INT,
    query_type VARCHAR(20),
    elapsed_ms DECIMAL(10,3)
);

DROP PROCEDURE IF EXISTS run_search_bench;
DELIMITER //
CREATE PROCEDURE run_search_bench(IN in_loops INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE t0 DATETIME(6);
    DECLARE t1 DATETIME(6);
    DECLARE t2 DATETIME(6);
    DECLARE t3 DATETIME(6);

    WHILE i <= in_loops DO
        -- LIKE timing
        SET t0 = NOW(6);
        SELECT SQL_NO_CACHE p.product_id
        FROM product p
        WHERE p.name LIKE @kw_like
        ORDER BY p.product_id DESC
        LIMIT 20;
        SET t1 = NOW(6);

        INSERT INTO bench_result(run_no, query_type, elapsed_ms)
        VALUES (
            i,
            'LIKE',
            TIMESTAMPDIFF(MICROSECOND, t0, t1) / 1000.0
        );

        -- FULLTEXT timing
        SET t2 = NOW(6);
        SELECT SQL_NO_CACHE p.product_id
        FROM product p
        WHERE MATCH(p.name) AGAINST(@kw_ft IN BOOLEAN MODE)
        ORDER BY p.product_id DESC
        LIMIT 20;
        SET t3 = NOW(6);

        INSERT INTO bench_result(run_no, query_type, elapsed_ms)
        VALUES (
            i,
            'FULLTEXT',
            TIMESTAMPDIFF(MICROSECOND, t2, t3) / 1000.0
        );

        SET i = i + 1;
    END WHILE;
END //
DELIMITER ;

CALL run_search_bench(@loops);
DROP PROCEDURE IF EXISTS run_search_bench;

-- 요약 통계
SELECT
    query_type,
    ROUND(AVG(elapsed_ms), 3) AS avg_ms,
    ROUND(MIN(elapsed_ms), 3) AS min_ms,
    ROUND(MAX(elapsed_ms), 3) AS max_ms
FROM bench_result
GROUP BY query_type;

-- 개선율 계산
SELECT
    ROUND(
        (
            (SELECT AVG(elapsed_ms) FROM bench_result WHERE query_type = 'LIKE') -
            (SELECT AVG(elapsed_ms) FROM bench_result WHERE query_type = 'FULLTEXT')
        ) /
        (SELECT AVG(elapsed_ms) FROM bench_result WHERE query_type = 'LIKE') * 100,
        2
    ) AS improvement_percent;

