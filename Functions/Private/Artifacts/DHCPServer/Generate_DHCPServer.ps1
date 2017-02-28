function Generate_DHCPServer {
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

    $ResultBuilder = GetDockerfileBuilder
    if ($Artifact.Status -eq 'Present') {        
        $null = $ResultBuilder.AppendLine('RUN Enable-WindowsOptionalFeature -Online -FeatureName DHCPServer')
        $null = $ResultBuilder.AppendLine('EXPOSE 67 2535')
        $null = $ResultBuilder.AppendLine('CMD /Wait-Service.ps1 -ServiceName DHCPServer -AllowServiceRestart')
    }

    return $ResultBuilder.ToString()
}

