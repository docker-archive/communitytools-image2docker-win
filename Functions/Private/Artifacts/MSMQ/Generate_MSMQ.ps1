function Generate_MSMQ {
<#
.SYNOPSIS
Generates Dockerfile contents for Microsoft Message Queue (MSMQ) Server feature 

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
    $Result = "RUN Enable-WindowsOptionalFeature -Online -FeatureName $($Artifact.FeatureName.Replace(';',',')) ;"
    $Result += [System.Environment]::NewLine
    $Result += 'EXPOSE 135 389 1801

CMD /Wait-Service.ps1 -ServiceName MSMQ -AllowServiceRestart'

    Write-Output -InputObject $Result
}


}

