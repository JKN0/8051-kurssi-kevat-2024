@echo off
set port=COM4
if [%1]==[] goto no_target
C:\MCS51\ASL\bin\asl -L -cpu 8051 -i C:\MCS51\ASL\include %1.asm
C:\MCS51\ASL\bin\p2hex %1.p
mode %port%:38400,N,8,1 >nul
type %1.hex > %port%:
timeout /t 1 /nobreak >nul
echo J>%port%:
echo --- Done ---
exit /b
:no_target
echo *** No target

