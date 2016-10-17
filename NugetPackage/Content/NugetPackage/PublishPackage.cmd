@ECHO OFF
SET PSScriptRoot=%~dp0
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& '%PSScriptRoot%Scripts\UploadNugetPackage.ps1'"