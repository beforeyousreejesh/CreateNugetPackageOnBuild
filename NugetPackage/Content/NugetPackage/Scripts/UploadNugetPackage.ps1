[CmdletBinding()]
Param
(
    [string]$source,
    [string]$apiKey
)

Set-StrictMode -Off

Write-Output "Publishing nuget package"

$Files_Dir=Get-ChildItem (Split-Path -Path $PSScriptRoot -Parent)

$NuPkg_File=$Files_Dir | where {$_.extension -eq ".nupkg"}

if(!$NuPkg_File)
{
   throw("Could not find nupkg file. Make sure that build this project in 'CreateNuget' build configuration")
}

if($NuPkg_File.Count -gt 1)
{
  throw("Found more than one nupkg file")
}

$Settings_File=$Files_Dir | where { $_.Name -eq "Settings.xml" }

if(!$Settings_File)
{
   throw("Could not find Settings.xml file. Might have deleted the file")
}

if($Settings_File.Count -gt 1)
{
  throw("Found more than one Settings.xml")
}

[xml]$Settings=Get-Content $Settings_File.FullName

if(!$source)
{
  $source=$Settings.Settings.Source
}

if(!$apiKey)
{
  $apiKey=$Settings.Settings.ApiKey 
}

$NugetExePath=Join-Path $PSScriptRoot "Nuget.exe"

if(!(Test-Path $NugetExePath))
{ 
    throw("Could not find Nuget.exe in $PSScriptRoot. Might have deleted it")
}

$Nuget_Nupkg_Path=$NuPkg_File.FullName

$NugetExePushOutPut=(Invoke-Expression -Command "& ""$NugetExePath"" push -Source ""$source"" -ApiKey ""$apiKey"" ""$Nuget_Nupkg_Path"" " | Out-String).Trim()

$NugetExePushOutPut