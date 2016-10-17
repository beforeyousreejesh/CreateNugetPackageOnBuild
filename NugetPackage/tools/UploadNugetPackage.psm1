 Param
 (
   [parameter(Position=0,Mandatory=$true)]
   [string]$projectPath
 )

function Publish-Package
(
    [string]$source,
    [string]$apiKey
)
{  
   $createNugetPackagePath= Join-Path $projectPath "NugetPackage\Scripts\UploadNugetPackage.ps1"

   if($source  -and $apiKey)
   {
     & "$createNugetPackagePath -source $source -apiKey $apiKey"
   }
   elseif($source)
   {
     & "$createNugetPackagePath -source $source"
   }
   elseif($apiKey)
   {
     & "$createNugetPackagePath -apiKey $apiKey"
   }
   else
   {
     & "$createNugetPackagePath"
   }
}

Register-TabExpansion 'Publish-Package' @{
    'source' = { }
    'apiKey' = { }
}

Export-ModuleMember Publish-Package