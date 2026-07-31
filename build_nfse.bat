@echo off
setlocal

set "PATH=C:\Borland\bcc58\Bin;C:\MiniGUI\Harbour\bin;%PATH%"
set "HB_COMPILER=bcc"

if not exist exe mkdir exe

C:\MiniGUI\Harbour\bin\hbmk2.exe nfse_nacional.hbp -comp=bcc -q -w0 2>&1 | findstr /V /I /C:"Warning"

if %errorlevel% equ 0 (
    echo.
    echo =========================================
    echo   Compilado com sucesso! Executando...   
    echo =========================================
    echo.
pause
    D:\dps_nacional\exe\nfse_nacional_demo.exe
) else (
    echo.
    echo =========================================
    echo   Ocorreu um erro na compilacao.         
    echo =========================================
    echo.
    pause

)

endlocal
