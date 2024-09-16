@echo off
if [%1]==[] goto no_target
sdcc --no-xinit-opt --code-loc 0x2000 %1.c
echo --- Done ---
exit /b
:no_target
echo *** No target

