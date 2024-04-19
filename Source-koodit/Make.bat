@echo off
if [%1]==[] goto no_target
C:\MCS51\ASL\bin\asl -L -cpu 8051 -i C:\MCS51\ASL\include %1.asm
C:\MCS51\ASL\bin\p2hex %1.p
exit /b
:no_target
echo *** No target
