function Generate_SQLServer {
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
### NOTE: You will need to set up a SQL Server answer file for each instance
RUN powershell.exe -ExecutionPolicy Bypass -Command \
'
    $SetupTemplate = 'setup.exe /INSTANCENAME={0} /IACCEPTSQLSERVERLICENSETERMS /QS /CONFIGURATIONFILE=sqlserver.ini; \{1}'

    foreach ($SqlInstance in $Artifact.SqlInstances) {
        $Result += $SetupTemplate -f $SqlInstance.Name, "`r`n"
    }

    Write-Output -InputObject $Result
}


}

