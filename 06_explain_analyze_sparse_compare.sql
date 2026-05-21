-- Run after:
--   USE explain_lab;
--   SOURCE .../00_local_standalone_setup.sql;
--
-- 목적:
--   04_runtime_selective_compare.sql 과 동일한 조건(희소 키워드, product 단일 테이블, COUNT(*))
--   으로 실행 계획을 비교한다.
--
--   - EXPLAIN: 옵티마이저 예상 계획
--   - EXPLAIN FORMAT=JSON: 예상 계획(JSON)
--   - 실측 계획(EXPLAIN ANALYZE): MySQL 8.0.18+ / MariaDB 10.7+ → 07_explain_analyze_sparse_optional.sql
--
-- 참고: 구버전 MariaDB에서 collation 오류가 나면 explain_lab 을 DROP 후 00 을 다시 실행하거나,
--       SET NAMES utf8mb4; 후 컬럼이 utf8mb4 인지 확인.

SET NAMES utf8mb4 COLLATE utf8mb4_general_ci;
SET @kw_like := '%희소토큰zxq%';
SET @kw_ft := '+희소토큰zxq*';

-- ========== A) 예상 계획 (전통 형식) ==========

EXPLAIN
SELECT COUNT(*) AS cnt
FROM product p
WHERE p.name LIKE @kw_like;

EXPLAIN
SELECT COUNT(*) AS cnt
FROM product p
WHERE MATCH(p.name) AGAINST(@kw_ft IN BOOLEAN MODE);

-- ========== B) 예상 계획 (JSON) ==========

EXPLAIN FORMAT=JSON
SELECT COUNT(*) AS cnt
FROM product p
WHERE p.name LIKE @kw_like;

EXPLAIN FORMAT=JSON
SELECT COUNT(*) AS cnt
FROM product p
WHERE MATCH(p.name) AGAINST(@kw_ft IN BOOLEAN MODE);

-- ========== C) 실측 계획 ==========
-- MariaDB 10.7 미만 / MySQL 8.0.18 미만에서는 문법 오류(1064)가 납니다.
-- 이 경우: SOURCE 07_explain_analyze_sparse_optional.sql 을 지원 버전에서만 실행.
