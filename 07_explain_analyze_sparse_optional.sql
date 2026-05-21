-- 실측 실행 통계가 붙은 계획 (쿼리는 실제로 1회 실행됨)
--
-- MariaDB (10.1+): ANALYZE <explainable> — 표에 r_rows, r_filtered 등 실측 열이 추가됨
-- MySQL 8.0.18+:   EXPLAIN ANALYZE SELECT ... (아래 MySQL 블록 주석 참고)
--
-- 06_explain_analyze_sparse_compare.sql 과 동일 조건(04 희소 키워드 + COUNT(*)).

SET NAMES utf8mb4 COLLATE utf8mb4_general_ci;
SET @kw_like := '%희소토큰zxq%';
SET @kw_ft := '+희소토큰zxq*';

-- ----- MariaDB -----
ANALYZE SELECT COUNT(*) AS cnt
FROM product p
WHERE p.name LIKE @kw_like;

ANALYZE SELECT COUNT(*) AS cnt
FROM product p
WHERE MATCH(p.name) AGAINST(@kw_ft IN BOOLEAN MODE);

-- ----- MySQL 8.0.18+ 전용 (MariaDB에서는 실행하지 말 것) -----
-- EXPLAIN ANALYZE SELECT COUNT(*) AS cnt
-- FROM product p
-- WHERE p.name LIKE @kw_like;
--
-- EXPLAIN ANALYZE SELECT COUNT(*) AS cnt
-- FROM product p
-- WHERE MATCH(p.name) AGAINST(@kw_ft IN BOOLEAN MODE);
