@echo off
REM ============================================================
REM Oracle MySQL 8.4 Windows 서비스 (MySQL84) 재구성
REM - MariaDB(3306)와 충돌 나지 않도록 MySQL은 3307
REM - 데이터 디렉터리: C:\mysql84\data
REM
REM 반드시 "관리자 권한으로 실행" 할 것
REM ============================================================

setlocal EnableExtensions
set "MYSQLD=C:\Program Files\MySQL\MySQL Server 8.4\bin\mysqld.exe"
set "INI=%~dp0mysql84-my.ini"

if not exist "%MYSQLD%" (
  echo [ERROR] mysqld 없음: %MYSQLD%
  exit /b 1
)
if not exist "%INI%" (
  echo [ERROR] my.ini 없음: %INI%
  exit /b 1
)

echo [1/5] C:\mysql84 폴더 준비
if not exist "C:\mysql84" mkdir "C:\mysql84"
if not exist "C:\mysql84\data" mkdir "C:\mysql84\data"

echo [2/5] my.ini 복사 -^> C:\mysql84\my.ini
copy /Y "%INI%" "C:\mysql84\my.ini" >nul
if errorlevel 1 (
  echo [ERROR] my.ini 복사 실패. 관리자 권한인지 확인.
  exit /b 1
)

echo [3/5] 데이터 디렉터리 초기화 (비어 있을 때만)
REM --defaults-file 은 mysqld 에서 항상 첫 번째 인자여야 함
if exist "C:\mysql84\data\mysql" (
  echo       이미 초기화됨 - 건너뜀
) else (
  echo       mysqld --initialize-insecure 실행 중...
  "%MYSQLD%" --defaults-file=C:\mysql84\my.ini --initialize-insecure
  if errorlevel 1 (
    echo [ERROR] initialize 실패.
    echo        C:\mysql84\data 가 비어 있지 않으면 폴더 전체 삭제 후 다시 실행.
    exit /b 1
  )
)

echo [4/5] 기존 MySQL84 서비스 제거 후 재등록
sc stop MySQL84 >nul 2>&1
sc delete MySQL84 >nul 2>&1
REM 서비스 등록 시에도 --defaults-file 이 맨 앞이어야 함 (미지정 시 잘못된 datadir/포트로 기동 실패)
ping -n 4 127.0.0.1 >nul
"%MYSQLD%" --defaults-file=C:\mysql84\my.ini --install MySQL84
if errorlevel 1 (
  echo [ERROR] 서비스 등록 실패
  exit /b 1
)
echo       서비스 구성 확인:
sc qc MySQL84 | findstr /i "BINARY"

echo [5/5] 서비스 시작
net start MySQL84
if errorlevel 1 (
  echo [ERROR] net start 실패.
  echo        오류 로그 (있으면):
  for %%f in ("C:\mysql84\data\*.err") do (
    echo ---- %%f ----
    more +0 "%%f" 2>nul
  )
  echo        이벤트 뷰어 - Windows 로그 - 응용 프로그램 에서 MySQL 도 확인.
  exit /b 1
)

echo.
echo 완료. 접속 예:
echo   "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe" -h 127.0.0.1 -P 3307 -u root
echo (비밀번호 없이 root 접속 가능 - initialize-insecure 사용)
echo.
endlocal
exit /b 0
