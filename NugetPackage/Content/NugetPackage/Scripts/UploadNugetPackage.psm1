 Param
 (
   [parameter(Position=0,Mandatory=$true)]
   [string]$projectPath
 )

function PublishPackage
(
    [string]$source,
    [string]$apiKey
)
{  

  "$createNugetPackagePath -source $source -apiKey $apiKey"
}

Register-TabExpansion 'PublishPackage' @{
    'source' = { }
    'apiKey' = { }
}

Export-ModuleMember PublishPackage