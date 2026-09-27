@echo off

echo Packaging for release ...
tar -acf "%~dp0out\McOsu.zip" -C "%~dp0out\bin" *

