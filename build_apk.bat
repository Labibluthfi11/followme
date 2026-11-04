@echo off
setlocal
cd /d "%~dp0"

echo ======================================================
echo    MEMULAI BUILD APK RELEASE (DENGAN OBFUSCATION)
echo ======================================================
echo.

where flutter >nul 2>nul
if errorlevel 1 (
    echo ERROR: Flutter tidak ditemukan di PATH.
    echo Tambahkan folder bin Flutter ke PATH lalu coba lagi.
    pause
    exit /b 1
)

call flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
if errorlevel 1 (
    echo.
    echo BUILD GAGAL. Periksa pesan error di atas.
    pause
    exit /b 1
)

if not exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo ERROR: Build selesai tetapi file APK tidak ditemukan.
    pause
    exit /b 1
)

echo.
echo ======================================================
echo    BUILD BERHASIL!
echo    Lokasi APK: build\app\outputs\flutter-apk\app-release.apk
echo    Lokasi Simbol: build\app\outputs\symbols (Simpan ini buat debug)
echo ======================================================
echo.
pause
