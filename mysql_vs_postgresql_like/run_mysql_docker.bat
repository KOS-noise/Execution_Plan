@echo off
REM MySQL 8.4 (Docker explain-mysql) — 시드 + EXPLAIN + EXPLAIN ANALYZE
REM 사전: docker run 으로 explain-mysql 기동됨 (포트 3307)

setlocal
cd /d "%~dp0"

echo [1/3] seed
docker cp "%~dp000_mysql_setup_seed.sql" explain-mysql:/tmp/00_seed.sql
docker exec -i explain-mysql mysql -uroot -e "source /tmp/00_seed.sql"

echo [2/3] EXPLAIN
docker cp "%~dp001_mysql_explain_like.sql" explain-mysql:/tmp/01_explain.sql
docker exec -i explain-mysql mysql -uroot -e "source /tmp/01_explain.sql"

echo [3/3] EXPLAIN ANALYZE
docker cp "%~dp002_mysql_explain_analyze_like.sql" explain-mysql:/tmp/02_analyze.sql
docker exec -i explain-mysql mysql -uroot -e "source /tmp/02_analyze.sql"

echo DONE
endlocal
