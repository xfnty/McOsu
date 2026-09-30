@echo off
setlocal enableextensions enabledelayedexpansion

set "MAX_PARALLEL_JOBS=4"

set "SRC_DIR=src"
set "LIB_DIR=libraries"
set "BUILD_DIR=build"
set "OUT_DIR=out"
set "OBJ_DIR=out\obj"
set "EXE_DIR=out\bin"
set "EXE_PATH=%EXE_DIR%\McOsu.exe"
set "ZIP_PATH=%OUT_DIR%\McOsu-windows-x86.zip"
set "RES_PATH=%OBJ_DIR%\resources.res"
set "LDARGS=%OBJ_DIR%\ldargs.txt"
set "OBJLIST=%OBJ_DIR%\objs.txt"

set "CFLAGS=-DNOMINMAX -DWIN32 -O3 -m32 -Wall -c -fmessage-length=0 -Wno-sign-compare -Wno-unused-local-typedefs -Wno-reorder -Wno-switch -Wno-deprecated-declarations -Wno-vla-cxx-extension -Wno-unused-but-set-variable -fno-stack-check -fno-stack-protector -mno-stack-arg-probe"
set "LDFLAGS=/INCREMENTAL:NO /NOIMPLIB /NOEXP /NOLOGO"
set "LDLINKS="%~dp0%RES_PATH%" user32.lib kernel32.lib comdlg32.lib Advapi32.lib ucrt.lib vcruntime.lib msvcrt.lib Comctl32.lib gdi32.lib Shell32.lib bass.lib bass_fx.lib dxgi.lib d3d11.lib d3dcompiler.lib freetype.lib libjpeg.lib"

set "includes=-I"%~dp0%SRC_DIR%\Util""
set "links="
set /a "num_sources=0"
set /a "num_sources_compiled=0"

if "%1"=="" (
    call :Help || goto :ExitError
) else (
    for %%a in (%*) do (
        if "%%a"=="clean" (
            call :Clean || goto :ExitError
        ) else if "%%a"=="build" (
            call :Build || goto :ExitError
        ) else if "%%a"=="pack" (
            call :Pack || goto :ExitError
        ) else if "%%a"=="run" (
            call :Run || goto :ExitError
        ) else (
            echo error: Unknown command '%%a'
            goto :ExitError
        )
    )
)
goto :Exit

:Help
echo Usage: do [clean/build/pack/run...]
exit /b 0

:Clean
echo Deleting "%OUT_DIR%" ...
rmdir /q /s "%~dp0%OUT_DIR%" 2> nul
exit /b 0

:Build
echo Checking environment ...
if "%VSCMD_ARG_TGT_ARCH%" neq "x86" (
    echo error: you're not running this under 'x86 Native Tools Command Prompt for VS'
    goto :ExitError
)
where /q clang || (
    echo error: 'clang.exe' is required
    exit /b 1
)
where /q link || (
    echo error: 'link.exe' is required
    exit /b 1
)
mkdir "%~dp0%OBJ_DIR%" "%~dp0%EXE_DIR%" 2> nul
echo Compiling ...
set "dirty=0"
type nul>"%~dp0%OBJLIST%"
del /q /s /f "%~dp0%OBJ_DIR%\*.job" "%~dp0%OBJ_DIR%\*.fail" >nul 2>&1
for /r "%~dp0%SRC_DIR%" %%a in (*.cpp) do set /a "num_sources+=1"
for /r "%~dp0%SRC_DIR%" %%a in (*.c) do set /a "num_sources+=1"
for /d /r "%~dp0%SRC_DIR%" %%a in (*) do set "includes=-I"%%a" !includes!"
for /d %%a in ("%~dp0%LIB_DIR%\*") do set "includes=-I"%%a\include" !includes!"
call :IsFileNewerThan "%~dp0%SRC_DIR%\icon.rc" "%~dp0%RES_PATH%" && (
    set "dirty=1"
    echo %RES_PATH%
    rc /nologo /r /fo "%~dp0%RES_PATH%" "%~dp0%SRC_DIR%\icon.rc" || exit /b 1
)
for /r "%~dp0%SRC_DIR%" %%a in (*.cpp) do (
    set "b=%%~dpa"
    set "c=!b:*%SRC_DIR%=!"
    mkdir "%~dp0%OBJ_DIR%!c!." 2> nul
    set "obj=%~dp0%OBJ_DIR%!c!%%~na.obj"
    echo "!obj!">>"%~dp0%OBJLIST%"
    call :IsFileNewerThan "%%a" "!obj!" && (
        set "dirty=1"
        call :StartCompileJob "%%a" "!obj!" || goto Build_JobFailed
    )
    set /a "num_sources_compiled+=1"
)
for /r "%~dp0%SRC_DIR%" %%a in (*.c) do (
    set "b=%%~dpa"
    set "c=!b:*%SRC_DIR%=!"
    mkdir "%~dp0%OBJ_DIR%!c!." 2> nul
    set "obj=%~dp0%OBJ_DIR%!c!%%~na.c.obj"
    echo "!obj!">>"%~dp0%OBJLIST%"
    call :IsFileNewerThan "%%a" "!obj!" && (
        set "dirty=1"
        call :StartCompileJob "%%a" "!obj!" || goto Build_JobFailed
    )
    set /a "num_sources_compiled+=1"
)
:Build_WaitAllLoop
for %%a in ("%~dp0%OBJ_DIR%\*.job") do timeout /t 1 /nobreak>nul && goto Build_WaitAllLoop
for %%a in ("%~dp0%OBJ_DIR%\*.fail") do (type %%a && exit /b 1)
if not exist "%~dp0%EXE_PATH%" set "dirty=1"
if "!dirty!"=="1" (
    echo Linking ...
    echo %LDFLAGS%>"%~dp0%LDARGS%"
    echo /LIBPATH:"%VCToolsInstallDir%lib\x86">>"%~dp0%LDARGS%"
    echo /LIBPATH:"%WindowsSdkDir%Lib\%WindowsSDKLibVersion%ucrt\x86">>"%~dp0%LDARGS%"
    echo /LIBPATH:"%WindowsSdkDir%Lib\%WindowsSDKLibVersion%um\x86">>"%~dp0%LDARGS%"
    for /d %%a in (%~dp0%LIB_DIR%\*) do if exist "%%a\lib\windows" echo /LIBPATH:"%%a\lib\windows">>"%~dp0%LDARGS%"
    echo /OUT:"%~dp0%EXE_PATH%">>"%~dp0%LDARGS%"
    echo %LDLINKS%>>"%~dp0%LDARGS%"
    type "%~dp0%OBJLIST%">>"%~dp0%LDARGS%"
    link @"%~dp0%LDARGS%" || exit /b 1
)
echo Copying assets ...
xcopy "%~dp0%BUILD_DIR%" "%~dp0%EXE_DIR%" /s /e /i /y >nul
exit /b 0
:Build_JobFailed
for %%a in ("%~dp0%OBJ_DIR%\*.fail") do (type %%a && exit /b 1)
echo error: build failed.
exit /b 1

:Pack
if not exist "%~dp0%EXE_PATH%" (
    echo error: %EXE_PATH% does not exist. Build the project first.
    exit /b 1
)
echo Packaging ...
tar -acf "%~dp0%ZIP_PATH%" -C "%~dp0%EXE_DIR%" *
exit /b 0

:Run
if not exist "%~dp0%EXE_PATH%" (
    echo error: %EXE_PATH% does not exist. Build the project first.
    exit /b 1
)
echo Running ...
start "" /d "%~dp0%EXE_DIR%." /b /wait "%~dp0%EXE_PATH%"
if !errorlevel! neq 0 (
    echo error: exited with code !errorlevel!
    exit /b 1
)
exit /b 0

:IsFileNewerThan
if not exist "%~2" exit /b 0
if "%~t1" lss "%~t2" exit /b 1
xcopy /D /L /Y "%~1" "%~2" | FINDSTR /E /C:"%~nx1" >nul && exit /b 0
exit /b 1

:StartCompileJob
set "jobname=%RANDOM%"
set "jobfile=%~dp0%OBJ_DIR%\!jobname!.job"
set "jobfail=%~dp0%OBJ_DIR%\!jobname!.fail"
set "jobcmd=clang %CFLAGS% !includes! -o "%~2" "%~1"2>>"!jobfile!""
type nul>"!jobfile!"
:StartCompileJob_WaitLoop
set "jobs=0"
for %%a in ("%~dp0%OBJ_DIR%\*.fail") do exit /b 1
for %%a in ("%~dp0%OBJ_DIR%\*.job") do set /a "jobs+=1"
if !jobs! gtr %MAX_PARALLEL_JOBS% goto StartCompileJob_WaitLoop
set "a=%~1"
set "b=!a:*%SRC_DIR%=!"
set "c=!b:~1!"
set "num_sources_to_be_compiled=!num_sources_compiled!"
set /a "num_sources_to_be_compiled+=1"
echo !num_sources_to_be_compiled!/!num_sources! !c!
start "" /b cmd /c "(!jobcmd! || move "!jobfile!" "!jobfail!">nul) & del "!jobfile!"2>nul"
exit /b 0

:ExitError
cmd /c exit /b 1
:Exit
