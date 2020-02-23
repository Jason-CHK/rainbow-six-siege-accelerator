@echo off

:: Request admin permission. Ref: https://stackoverflow.com/a/10052222/4806616
:-------------------------------------
REM  --> Check for permissions.
    IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
>nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params= %*
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params:"=""%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------

REM --> Initial reset, then start infinite poll cycles.
CALL :reset
FOR /L %%N IN () DO CALL :cycle

REM --> Reset network to normal by enabling wifi autoconfig.
:reset
ECHO Resetting to normal network...
SET "running="
netsh wlan set autoconfig enabled=yes interface="Wi-Fi"
ECHO.
EXIT /B 0

REM --> Enhance network by disabling wifi autoconfig.
:enhance
ECHO Enhancing network but no re-connection...
SET "running=y"
netsh wlan set autoconfig enabled=no interface="Wi-Fi"
ECHO.
EXIT /B 0

REM --> Poll cycle of 10 seconds. Detect if R6S is running and if a switch flip is needed.
:cycle
tasklist /nh /fi "imagename eq RainbowSix*" | find /i "RainbowSix" >NUL && (
SET "shouldrun=y"
) || (
SET "shouldrun="
)
IF DEFINED shouldrun IF NOT DEFINED running ( CALL :enhance )
IF NOT DEFINED shouldrun IF DEFINED running ( CALL :reset )
@timeout /t 10 /nobreak >NUL
EXIT /B 0
