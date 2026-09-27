@echo off
setlocal enableextensions enabledelayedexpansion

set NAME=McEngine
set BUILD=out

set SRC=src
set LIB=libraries

set CXX=clang++
set CC=clang
set LD=link

:: -std=c++23
set CXXFLAGS=-O3 -m32 -Wall -c -fmessage-length=0 -Wno-sign-compare -Wno-unused-local-typedefs -Wno-reorder -Wno-switch -Wno-deprecated-declarations -Wno-vla-cxx-extension -Wno-unused-but-set-variable -fno-stack-check -fno-stack-protector -mno-stack-arg-probe
set CFLAGS=-O3 -m32 -Wall -c -fmessage-length=0 -fno-stack-check -fno-stack-protector -mno-stack-arg-probe

:: -D__GXX_EXPERIMENTAL_CXX0X__ -D__cplusplus=201103L
set PFLAGS=-DNOMINMAX -DWIN32

set LDFLAGS=/INCREMENTAL:NO /NOIMPLIB /NOEXP /NOLOGO
set LDLIBS=user32.lib kernel32.lib comdlg32.lib Advapi32.lib ucrt.lib vcruntime.lib msvcrt.lib Comctl32.lib gdi32.lib Shell32.lib ^
bass.lib bass_fx.lib dxgi.lib d3d11.lib d3dcompiler.lib freetype.lib libjpeg.lib "%FULLPATH%out\tmp\resources.res"



set STARTTIME=%time%

set FULLPATH=%~dp0

echo Creating %FULLPATH%%BUILD%\ directory ...
if not exist "%FULLPATH%%BUILD%\." mkdir "%FULLPATH%%BUILD%\."
if not exist "%FULLPATH%%BUILD%\obj" mkdir "%FULLPATH%%BUILD%\obj"
if not exist "%FULLPATH%%BUILD%\bin" mkdir "%FULLPATH%%BUILD%\bin"
if not exist "%FULLPATH%%BUILD%\tmp" mkdir "%FULLPATH%%BUILD%\tmp"

set LDARGSFILE=%FULLPATH%out\tmp\link-args.txt
set LDARGSFILE2=%FULLPATH%out\tmp\link-args2.txt
type nul>"%LDARGSFILE%"
type nul>"%LDARGSFILE2%"

echo Collecting C++ files ...
set /a NUMCPPFILES = 0
for /r "%FULLPATH%%SRC%" %%i in (*.cpp) do (
	set CPPFILE!NUMCPPFILES!=%%i
	set /a NUMCPPFILES += 1
)

echo Collecting C files ...
set /a NUMCFILES = 0
for /r "%FULLPATH%%SRC%" %%i in (*.c) do (
	set CFILE!NUMCFILES!=%%i
	set /a NUMCFILES += 1
)

echo Collecting %SRC% include paths ...
set /a NUMINCLUDEPATHS = 0
for /d /r "%FULLPATH%%SRC%" %%i in (*) do (
	set INCLUDEPATH!NUMINCLUDEPATHS!=%%i
	set /a NUMINCLUDEPATHS += 1
)

echo Collecting library include paths ...
for /d %%i in ("%FULLPATH%%LIB%"\*) do (
	if exist "%%i\include" (
		set INCLUDEPATH!NUMINCLUDEPATHS!=%%i\include
		set /a NUMINCLUDEPATHS += 1
	)
)

set JOBLIST="%FULLPATH%out\tmp\jobs.txt"

if not exist "%JOBLIST%" (
	type nul>"%JOBLIST%"
	echo Writing compiler job list ...
	for /l %%i in (0,1,%NUMCPPFILES%) do (
		if %%i lss %NUMCPPFILES% (
			set CPPFILEPATH=!CPPFILE%%i!
			for %%a in ("!CPPFILEPATH!") do set CPPFILENAME=%%~na

			set INCLUDEPATHS=
			for /l %%j in (0,1,%NUMINCLUDEPATHS%) do (
				if %%j lss %NUMINCLUDEPATHS% (
					set VAR=!INCLUDEPATHS!"-I!INCLUDEPATH%%j!"
					set "INCLUDEPATHS=!VAR! "
				)
			)

			echo !CPPFILEPATH!^|%FULLPATH%%BUILD%\obj\%%i_cpp_!CPPFILENAME!.obj^|%CXX% %CXXFLAGS% %PFLAGS% !INCLUDEPATHS! -o "%FULLPATH%%BUILD%\obj\%%i_cpp_!CPPFILENAME!.obj" "!CPPFILEPATH!">>"%JOBLIST%"
		)
	)
	for /l %%i in (0,1,%NUMCFILES%) do (
		if %%i lss %NUMCFILES% (
			set CFILEPATH=!CFILE%%i!
			for %%a in ("!CFILEPATH!") do set CFILENAME=%%~na

			echo !CFILEPATH!^|%FULLPATH%%BUILD%\obj\%%i_c_!CFILENAME!.obj^|%CC% %CFLAGS% -o "%FULLPATH%%BUILD%\obj\%%i_c_!CFILENAME!.obj" "!CFILEPATH!">>"%JOBLIST%"
		)
	)
)

if not exist "%FULLPATH%out\tmp\resources.res" (
	rc /nologo /r /fo "%FULLPATH%out\tmp\resources.res" "%FULLPATH%out\tmp\resources.res"
)

echo Running compile jobs ...
python run-jobs.py "%JOBLIST%" || goto :BUILD_FAILED

if not "%LDFLAGS%"=="" (
	echo %LDFLAGS%>> "%LDARGSFILE%"
)

echo Collecting library search paths ...
for /d %%i in ("%FULLPATH%%LIB%"\*) do (
	if exist "%%i/lib/windows" (
		echo /LIBPATH:"%%i/lib/windows">> "%LDARGSFILE%"
	)
)

echo /OUT:"%FULLPATH%%BUILD%/bin/%NAME%.exe">> "%LDARGSFILE%"

echo Collecting object files ...
set /a NUMOFILES = 0
for /r "%FULLPATH%%BUILD%\obj" %%i in (*.obj) do (
	rem echo %%i
	echo "%%i">> "%LDARGSFILE%"
	set /a NUMOFILES += 1
)

echo %LDLIBS%>> "%LDARGSFILE%"

echo /LIBPATH:"C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Tools\MSVC\14.51.36231\lib\x86">>"%LDARGSFILE%"
echo /LIBPATH:"C:\Program Files (x86)\Windows Kits\10\Lib\10.0.28000.0\ucrt\x86">>"%LDARGSFILE%"
echo /LIBPATH:"C:\Program Files (x86)\Windows Kits\10\Lib\10.0.28000.0\um\x86">>"%LDARGSFILE%"
echo /MACHINE:X86>>"%LDARGSFILE%"

for /f "tokens=*" %%i in ('type "%LDARGSFILE%"') do (
	set line=%%i
	set linewithbackslashesconvertedtoforwardslashes=!line:\=/!
	echo !linewithbackslashesconvertedtoforwardslashes!>> "%LDARGSFILE2%"
)

echo Linking %NUMOFILES% object file(s) ...
link @"%LDARGSFILE2%"

echo Copying files ...
xcopy "%~dp0build" "%FULLPATH%%BUILD%\bin" /s /e /i /y >nul

:END
set ERRORLEVELBACKUP=%ERRORLEVEL%

set ENDTIME=%time%
set TIMEOPTIONS="tokens=1-4 delims=:.,"
for /f %TIMEOPTIONS% %%a in ("%STARTTIME%") do set start_h=%%a&set /a start_m=100%%b %% 100&set /a start_s=100%%c %% 100&set /a start_ms=100%%d %% 100
for /f %TIMEOPTIONS% %%a in ("%ENDTIME%") do set end_h=%%a&set /a end_m=100%%b %% 100&set /a end_s=100%%c %% 100&set /a end_ms=100%%d %% 100
set /a hours=%end_h%-%start_h%
set /a mins=%end_m%-%start_m%
set /a secs=%end_s%-%start_s%
set /a ms=%end_ms%-%start_ms%
if %ms% lss 0 set /a secs = %secs% - 1 & set /a ms = 100%ms%
if %secs% lss 0 set /a mins = %mins% - 1 & set /a secs = 60%secs%
if %mins% lss 0 set /a hours = %hours% - 1 & set /a mins = 60%mins%
if %hours% lss 0 set /a hours = 24%hours%
if 1%ms% lss 100 set ms=0%ms%

if %ERRORLEVELBACKUP% neq 0 goto BUILD_FAILED
goto BUILD_SUCCEEDED



:BUILD_FAILED
echo Build Failed. (took %mins%:%secs%)
if /i "%comspec% /c ``%~0` `" equ "%cmdcmdline:"=`%" pause
exit /b %ERRORLEVEL%



:BUILD_SUCCEEDED
echo Build Finished. (took %mins%:%secs%)
if /i "%comspec% /c ``%~0` `" equ "%cmdcmdline:"=`%" pause
exit /b 0
