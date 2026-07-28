-- MySQL: %LIKE% 반복 런타임 (출력 오버헤드 최소화 = COUNT INTO)
-- Run after: 00_mysql_setup_seed.sql

USE explain_lab;
SET NAMES utf8mb4 COLLATE utf8mb4_general_ci;

SET @kw_sparse := '%희소토큰zxq%';
SET @kw_common := '%에어맥스%';
SET @loops := 30;

DROP TEMPORARY TABLE IF EXISTS bench_like_mysql;
CREATE TEMPORARY TABLE bench_like_mysql (
    run_no INT,
    token_type VARCHAR(20),
    elapsed_ms DECIMAL(10,3),
    matched_rows INT
);

DROP PROCEDURE IF EXISTS run_like_bench_mysql;
DELIMITER //
CREATE PROCEDURE run_like_bench_mysql(IN in_loops INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE t0 DATETIME(6);
    DECLARE t1 DATETIME(6);
    DECLARE t2 DATETIME(6);
    DECLARE t3 DATETIME(6);
    DECLARE v_count INT;

    WHILE i <= in_loops DO
        SET t0 = NOW(6);
        SELECT SQL_NO_CACHE COUNT(*) INTO v_count
        FROM product p
        WHERE p.name LIKE @kw_sparse;
        SET t1 = NOW(6);

        INSERT INTO bench_like_mysql(run_no, token_type, elapsed_ms, matched_rows)
        VALUES (i, 'SPARSE', TIMESTAMPDIFF(MICROSECOND, t0, t1) / 1000.0, v_count);

        SET t2 = NOW(6);
        SELECT SQL_NO_CACHE COUNT(*) INTO v_count
        FROM product p
        WHERE p.name LIKE @kw_common;
        SET t3 = NOW(6);

        INSERT INTO bench_like_mysql(run_no, token_type, elapsed_ms, matched_rows)
        VALUES (i, 'COMMON', TIMESTAMPDIFF(MICROSECOND, t2, t3) / 1000.0, v_count);

        SET i = i + 1;
    END WHILE;
END //
DELIMITER ;

CALL run_like_bench_mysql(@loops);
DROP PROCEDURE IF EXISTS run_like_bench_mysql;

SELECT
    token_type,
    ROUND(AVG(elapsed_ms), 3) AS avg_ms,
    ROUND(MIN(elapsed_ms), 3) AS min_ms,
    ROUND(MAX(elapsed_ms), 3) AS max_ms,
    MIN(matched_rows) AS matched_rows
FROM bench_like_mysql
GROUP BY token_type
ORDER BY token_type;
