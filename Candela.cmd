@echo off
rem Launches Candela with administrator rights (needed to apply or restore the fix).
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"%~dp0App.ps1\"'"

