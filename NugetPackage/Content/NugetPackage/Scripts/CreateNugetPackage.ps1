[CmdletBinding()]
Param
(
   [Parameter(Mandatory=$True)]
   [ValidateScript({Test-Path $_})]
   [string]$ProjectFilePath,
	
   [Parameter(Mandatory=$True)]
   [ValidateScript({Test-Path $_})]
   [string]$OutputDirectory,

   [Parameter(Mandatory=$True)]
   [ValidateSet('CreateNuget','CreateAndPublishNuget')]
   [string]$BuildConfiguration,

   [Parameter(Mandatory=$True)]
   [string]$BuildPlatform
)

Set-StrictMode -Off

Write-Output "Project file path passed is '$ProjectFilePath'"
Write-Output "Output directory passed is '$OutputDirectory'"
Write-Output "Build configuration passed is '$BuildConfiguration'"
Write-Output "Build platform passed is '$BuildPlatform'"

$NuSpec_File_Dir=Get-ChildItem (Split-Path -Path $PSScriptRoot -Parent)
$NuSpec_File=$NuSpec_File_Dir | where {$_.extension -eq ".nuspec"}

if(!$NuSpec_File)
{
   throw("Could not find nuspec file")
}

if($NuSpec_File.Count -gt 1)
{
  throw("Found more than one nuspec file")
}

[xml]$XmlDocument=Get-Content $ProjectFilePath


$asseblyDetails =$XmlDocument.Project.PropertyGroup | where {$_.Configuration -and !([System.String]::IsNullOrEmpty($_.Configuration.innertext))}

$asseblyType=$asseblyDetails.OutputType
$assemblyName=$asseblyDetails.AssemblyName

 if($asseblyType.Equals("Library",[System.StringComparison]::OrdinalIgnoreCase))
 {
    $assemblyName="$assemblyName.dll"
 }
 else
 {
    $assemblyName="$assemblyName.exe"
 }

$assemblyPath= Join-Path $OutputDirectory $assemblyName

 if(!(Test-path $assemblyPath -PathType Leaf))
 {
    throw("Could not find[{0}] " -f $assemblyPath)
 }

 $copyPath=Join-Path (Split-Path $PSScriptRoot -Parent) "Lib"

 if(!(Test-Path -Path  $copyPath -PathType Container))
 {
    Write-Output "Could not find path for copyng file. So creating folder"

    New-Item -ItemType Directory -Path $copyPath -Force -ErrorAction Stop
 }


 Copy-Item $assemblyPath $copyPath -Force

 $assemblyPdbFilePath=[System.IO.Path]::ChangeExtension($assemblyPath,"pdb")

 if(Test-Path -Path $assemblyPdbFilePath -PathType Leaf)
 {
    Write-Output "Copying sysmbol file(pdb) file to $copyPath"

    Copy-Item $assemblyPdbFilePath $copyPath -Force
 }
 else
 {
    Write-Output "Could not find sysmbol file(pdb) file so getting rid of it"
 }

 $assemblyXmlFilePath=[System.IO.Path]::ChangeExtension($assemblyPath,"xml")

 if(Test-Path $assemblyXmlFilePath -PathType Leaf)
 {
     Write-Output "Copying documentation file(xml) file to $copyPath"

     Copy-Item $assemblyXmlFilePath $copyPath -Force
 }
 else
 {  
     Write-Output "Could not find documentation file(xml) file. So getting rid of it"
 }

 $NugetExePath=Join-Path $PSScriptRoot "Nuget.exe"

 if(!(Test-Path $NugetExePath))
 {
    throw("Could not find Nuget.Exe")
 }

 Write-Output "Trying to update Nuget.exe"
 $NugetExeSelfUpdateOutPut=(Invoke-Expression -Command "& ""$NugetExePath"" update -self" | Out-String).Trim()

 Write-Output $NugetExeSelfUpdateOutPut

 Write-Output "Getting current version of Nuget.exe"
 $aboutOutput = Invoke-Expression -Command "& ""$NugetExePath"""

 Write-Output $aboutOutput[0]
 $NuSpec_File_Path=$NuSpec_File.FullName
 $Nuget_Output_path=Split-Path $PSScriptRoot -Parent
 $NugetExePackOutPut=(Invoke-Expression -Command "& ""$NugetExePath"" pack ""$NuSpec_File_Path"" -outputdirectory ""$Nuget_Output_path""" | Out-String).Trim()
 $NugetExePackOutPut