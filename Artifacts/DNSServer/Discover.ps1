<#
.SYNOPSIS
Scans for presence of DNS Server component in a Windows image. 

.PARAMETER MountPath
The path where the Windows image was mounted to.

.PARAMETER OutputPath
The filesystem path where the discovery manifest will be emitted.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $MountPath,
    [Parameter(Mandatory = $true)]
    [string] $OutputPath
)

$ArtifactName = Split-Path -Path $PSScriptRoot -Leaf
Write-Verbose -Message ('Started discovering {0} artifact' -f $ArtifactName)

$Manifest = '{0}\{1}.json' -f $OutputPath, $ArtifactName
$DNSServer = (Get-WindowsOptionalFeature -Path $MountPath).Where({ $PSItem.Name -match 'DNS-Server-Full-Role|DNS'})


$ManifestResult = @{
    Name = 'DNS-Server'
    Status = $DNSServer
}

### Write the result to the manifest file
$ManifestResult | ConvertTo-Json | Set-Content -Path $Manifest

Write-Verbose -Message ('Finished discovering {0} artifact' -f $ArtifactName)