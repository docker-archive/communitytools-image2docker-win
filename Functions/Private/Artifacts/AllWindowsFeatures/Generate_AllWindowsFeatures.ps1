function Generate_AllWindowsFeatures {
<#
.SYNOPSIS
Generates Dockerfile contents for DHCP Server component 

.PARAMETER ManifestPath
The filesystem path where the JSON manifests are stored.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $MountPath,
    
    [Parameter(Mandatory = $true)]
    [string] $ManifestPath
)

    $ArtifactName = Split-Path -Path $PSScriptRoot -Leaf

    Write-Verbose -Message ('Generating result for {0} component' -f $ArtifactName)
    $Manifest = '{0}\{1}.json' -f $ManifestPath, $ArtifactName

    $Artifact = Get-Content -Path $Manifest -Raw | ConvertFrom-Json
    $FeatureNames = $Artifact.FeatureName.replace(';',',')

    $ResultBuilder = GetDockerfileBuilder
    $null = $ResultBuilder.AppendLine("RUN Enable-WindowsOptionalFeature -Online -FeatureName $FeatureNames -All")

    return $ResultBuilder.ToString()
}

