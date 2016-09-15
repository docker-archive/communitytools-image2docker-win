<#
.SYNOPSIS
Generates Dockerfile contents for Microsoft SQL Server 

.PARAMETER ManifestPath
The filesystem path where the JSON manifests are stored.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $ManifestPath
)

$ArtifactName = Split-Path -Path $PSScriptRoot -Leaf

Write-Verbose -Message ('Generating result for {0} component' -f (Split-Path -Path $PSScriptRoot -Leaf))
$Manifest = '{0}\{1}.json' -f $ManifestPath, $ArtifactName 

$Artifact = Get-Content -Path $Manifest -Raw | ConvertFrom-Json

if ($Artifact.Status -eq 'Present') {
    $Result = '
RUN powershell.exe -ExecutionPolicy Bypass -Command setup.exe /INSTANCENAME= /IACCEPTSQLSERVERLICENSETERMS /QS /CONFIGURATIONFILE=sqlserver.ini 

ENTRYPOINT ["TBD"]'

    Write-Output -InputObject $Result
}

