@echo off
if [%1]==[] goto no_target
sdcc --no-xinit-opt --code-loc 0x2000 %1.c
mode COM4:38400,N,8,1 >nul
type %1.ihx > COM4:
timeout /t 1 /nobreak >nul
echo J>COM4:
echo --- Done ---
exit /b
:no_target
echo *** No target

