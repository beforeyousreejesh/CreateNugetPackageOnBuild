param($installPath, $toolsPath, $package, $project)

$projectPath=$project.Properties.Item("FullPath").Value

Import-Module (Join-Path $toolsPath UploadNugetPackage.psm1) -ArgumentList $projectPath
