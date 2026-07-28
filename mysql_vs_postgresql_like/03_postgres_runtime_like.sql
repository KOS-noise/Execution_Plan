-- PostgreSQL: %LIKE% 반복 런타임 (COUNT)
-- Run after: 00_postgres_setup_seed.sql
-- psql -d explain_lab -f 03_postgres_runtime_like.sql

\c explain_lab

DO $$
DECLARE
    loops INT := 30;
    i INT;
    t0 TIMESTAMPTZ;
    t1 TIMESTAMPTZ;
    v_count BIGINT;
BEGIN
    DROP TABLE IF EXISTS bench_like_pg;
    CREATE TEMP TABLE bench_like_pg (
        run_no INT,
        token_type TEXT,
        elapsed_ms NUMERIC(10,3),
        matched_rows BIGINT
    );

    FOR i IN 1..loops LOOP
        t0 := clock_timestamp();
        SELECT COUNT(*) INTO v_count
        FROM product p
        WHERE p.name LIKE '%희소토큰zxq%';
        t1 := clock_timestamp();

        INSERT INTO bench_like_pg(run_no, token_type, elapsed_ms, matched_rows)
        VALUES (
            i,
            'SPARSE',
            EXTRACT(EPOCH FROM (t1 - t0)) * 1000.0,
            v_count
        );

        t0 := clock_timestamp();
        SELECT COUNT(*) INTO v_count
        FROM product p
        WHERE p.name LIKE '%에어맥스%';
        t1 := clock_timestamp();

        INSERT INTO bench_like_pg(run_no, token_type, elapsed_ms, matched_rows)
        VALUES (
            i,
            'COMMON',
            EXTRACT(EPOCH FROM (t1 - t0)) * 1000.0,
            v_count
        );
    END LOOP;
END $$;

SELECT
    token_type,
    ROUND(AVG(elapsed_ms), 3) AS avg_ms,
    ROUND(MIN(elapsed_ms), 3) AS min_ms,
    ROUND(MAX(elapsed_ms), 3) AS max_ms,
    MIN(matched_rows) AS matched_rows
FROM bench_like_pg
GROUP BY token_type
ORDER BY token_type;
