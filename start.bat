@echo off
chcp 65001 >nul
echo ========================================
echo   n8n Docker
echo ========================================
echo.

set "ROOT_DIR=%~dp0"
set "CERT_DIR=%ROOT_DIR%docker\nginx\certs"

REM Check if openssl is available
set "OPENSSL_CMD=openssl"
where openssl >nul 2>nul
if %ERRORLEVEL% neq 0 (
    if exist "C:\Program Files\OpenSSL-Win64\bin\openssl.exe" (
        set "OPENSSL_CMD=C:\Program Files\OpenSSL-Win64\bin\openssl.exe"
        goto :ssl_ready
    )
    echo [INFO] OpenSSL not found. Installing via winget...
    winget install --id ShiningLight.OpenSSL.Light --accept-source-agreements --accept-package-agreements
    if exist "C:\Program Files\OpenSSL-Win64\bin\openssl.exe" (
        set "OPENSSL_CMD=C:\Program Files\OpenSSL-Win64\bin\openssl.exe"
        goto :ssl_ready
    )
    echo [ERROR] OpenSSL not found after install. Please restart terminal.
    pause
    exit /b 1
)
:ssl_ready

echo [1/2] Generating SSL certificates...

if not exist "%CERT_DIR%" mkdir "%CERT_DIR%"

"%OPENSSL_CMD%" req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "%CERT_DIR%\privkey.pem" -out "%CERT_DIR%\fullchain.pem" -subj "/C=TW/ST=Taiwan/L=Taipei/O=Dev/CN=localhost"

if %ERRORLEVEL% neq 0 (
    echo [ERROR] SSL cert generation failed.
    pause
    exit /b 1
)

echo [OK] SSL certs generated in %CERT_DIR%
echo.

echo [2/2] Starting Docker Compose...

cd /d "%ROOT_DIR%docker"
docker compose up -d

if %ERRORLEVEL% neq 0 (
    echo [ERROR] Docker Compose failed.
    pause
    exit /b 1
)

echo.
echo ========================================
echo   Done! Open https://localhost:8444
echo ========================================
pause
