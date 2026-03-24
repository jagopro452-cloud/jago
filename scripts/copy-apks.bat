@echo off
REM APK Auto-Copy Script for Windows
REM Usage: copy-apks.bat

echo.
echo 4 APK Auto-Copy Script (Windows)
echo ================================
echo.

REM Customer App
if exist "flutter_apps\customer_app\build\app\outputs\apk\release\app-release.apk" (
    echo Copying Customer App APK...
    copy "flutter_apps\customer_app\build\app\outputs\apk\release\app-release.apk" ^
         "public\apks\jago-customer-v1.0.56-release.apk"
    if %ERRORLEVEL% equ 0 (
        echo 4 Copied: jago-customer-v1.0.56-release.apk
        copy "public\apks\jago-customer-v1.0.56-release.apk" ^
             "public\apks\jago-customer-final.apk"
        echo 4 Also copied: jago-customer-final.apk
    ) else (
        echo 8 Failed to copy customer app
    )
) else (
    echo 8 Customer app build not found
    echo   Build it first: cd flutter_apps\customer_app ^&^& flutter build apk --release
)

echo.

REM Driver App
if exist "flutter_apps\driver_app\build\app\outputs\apk\release\app-release.apk" (
    echo Copying Driver App APK...
    copy "flutter_apps\driver_app\build\app\outputs\apk\release\app-release.apk" ^
         "public\apks\jago-driver-v1.0.58-release.apk"
    if %ERRORLEVEL% equ 0 (
        echo 4 Copied: jago-driver-v1.0.58-release.apk
        copy "public\apks\jago-driver-v1.0.58-release.apk" ^
             "public\apks\jago-driver-final.apk"
        echo 4 Also copied: jago-driver-final.apk
    ) else (
        echo 8 Failed to copy driver app
    )
) else (
    echo 8 Driver app build not found
    echo   Build it first: cd flutter_apps\driver_app ^&^& flutter build apk --release
)

echo.
echo Current APK files:
dir public\apks\*.apk /S

echo.
echo 4 Done!
pause
