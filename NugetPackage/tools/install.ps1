param($installPath, $toolsPath, $package, $project)

#uncomment this line to test in local
#Add-Type -AssemblyName "Microsoft.Build" 

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

$projFile = $project.FullName

if(!(Test-Path $projFile))
{
    throw ("Project file not found at [{0}]" -f $projFile)
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

$postBuildEventValue += "`n`r`n`r$eventProp"

$project.Properties.Item("PostBuildEvent").Value = $postBuildEventValue.Trim()

$nuGetExe = $project.ProjectItems.Item("NugetPackage").ProjectItems.Item("Scripts").ProjectItems.Item("NuGet.exe")
$nuGetExe.Properties.Item("BuildAction").Value = 0

#Nuspec content wild card is not including nuspec file (weird!). So adding it as txt file and renaming (bad approah i know but no other way)
$projectName=$project.Name
$project.ProjectItems.Item("NugetPackage").ProjectItems.Item("Sample.txt").Properties.Item("FileName").Value="$projectName.nuspec"
$project.Save()

$DTE.ExecuteCommand("File.SaveAll")
CheckoutProjFileIfUnderSourceControl
EnsureProjectFileIsWriteable

$projectMSBuild = [Microsoft.Build.Construction.ProjectRootElement]::Open($projFile)

$releaseBuild=($projectMSBuild.PropertyGroups | where { $_.Condition.Trim() -like "`'`$(Configuration)|`$(Platform)`' == `'Release|*`'"}) | Select-Object -First 1

if(!$releaseBuild)
{ 
   throw ("Realse configuration could not find")
}

RemoveExistingCreateNugetPropertyGroups -projectRootElement $projectMSBuild


$CreateNugetBuildPropGroup=$projectMSBuild.CreatePropertyGroupElement();
$CreateNugetBuildPropGroup.Condition= " `'`$(Configuration)|`$(Platform)`' == `'$BuildName|AnyCPU`' "
$projectMSBuild.InsertAfterChild($CreateNugetBuildPropGroup,$releaseBuild)

foreach($releaseProp in $releaseBuild.Properties)
{
  if($releaseProp.Name -eq "OutputPath")
  {
    #Assigning this into variable in order to avoid displaying in output window
    $tempProp1=$CreateNugetBuildPropGroup.AddProperty($releaseProp.Name,"bin\$BuildName\")
    continue
  }

  $tempProp1=$CreateNugetBuildPropGroup.AddProperty($releaseProp.Name,$releaseProp.Value)
}

$projectMSBuild.Save()
$DTE.ExecuteCommand("File.SaveAll")

[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()

