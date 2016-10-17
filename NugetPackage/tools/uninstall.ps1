param($installPath, $toolsPath, $package, $project)

Set-StrictMode -Off

$BuildName="CreateNuget"

function CheckoutProjFileIfUnderSourceControl(){

    $sourceControl = Get-Interface $project.DTE.SourceControl ([EnvDTE80.SourceControl2])
    if($sourceControl.IsItemUnderSCC($project.FullName) -and $sourceControl.IsItemCheckedOut($project.FullName)){
        $sourceControl.CheckOutItem($project.FullName)
    }
}

function EnsureProjectFileIsWriteable(){
    $projItem = Get-ChildItem $project.FullName
    if($projItem.IsReadOnly) {
        "The project file is read-only. Please checkout the project file and re-install this package" | Write-Host -ForegroundColor Red
        throw;
    }
}

function RemoveExistingCreateNugetPropertyGroups($projectRootElement){
    $pgsToRemove = @()
    foreach($pg in $projectRootElement.PropertyGroups){
        if($pg.Condition -like "*$BuildName*") {

            $pgsToRemove += $pg
        }
    }

    foreach($pg in $pgsToRemove){
        $pg.Parent.RemoveChild($pg)
    }
}

$DTE.ExecuteCommand("File.SaveAll")

$eventProp=@'
if $(ConfigurationName) == CreateNuget (
ECHO Create a NuGet package for this project and place the .nupkg file in the NugetPackage folder.
ECHO If build failed please refer output window for actual error.
ECHO Creating NuGet package ...
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& '$(ProjectDir)NugetPackage\Scripts\CreateNugetPackage.ps1' -ProjectFilePath '$(ProjectPath)' -OutputDirectory '$(TargetDir)' -BuildConfiguration '$(ConfigurationName)' -BuildPlatform '$(PlatformName)'"
)
'@

$postBuildEventValue = $project.Properties.Item("PostBuildEvent").Value

$postBuildEventValue=$postBuildEventValue.Replace($eventProp,[string]::Empty)

$project.Properties.Item("PostBuildEvent").Value = $postBuildEventValue.Trim()
$projectName=$project.Name
$project.ProjectItems.Item("NugetPackage").ProjectItems.Item("$projectName.nuspec").Remove()
$project.Save()

$projFile = $project.FullName

if(!(Test-Path $projFile))
{
    throw ("Project file not found at [{0}]" -f $projFile)
}

$DTE.ExecuteCommand("File.SaveAll")
CheckoutProjFileIfUnderSourceControl
EnsureProjectFileIsWriteable

$projectMSBuild = [Microsoft.Build.Construction.ProjectRootElement]::Open($projFile)


RemoveExistingCreateNugetPropertyGroups -projectRootElement $projectMSBuild

# removing created files
$NugetFolder= $project.ProjectItems.Item("NugetPackage").Properties.Item("FullPath").Value

Remove-Item $NugetFolder"Lib" -Recurse
Remove-Item $NugetFolder"*" -Include *.nupkg,*.nuspec

$projectMSBuild.Save()
#$DTE.ExecuteCommand("File.SaveAll")

[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()