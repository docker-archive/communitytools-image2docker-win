function Discover_DHCPServer {
<#
.SYNOPSIS
Scans for presence of DHCP Server component in a Windows Server image. 

.PARAMETER MountPath
The path where the Windows image was mounted to.

.PARAMETER OutputPath
The filesystem path where the discovery manifest will be emitted.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess",'')]
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

$DHCPServer = Get-WindowsOptionalFeature -Path $MountPath -FeatureName DHCPServer

$ManifestResult = @{
    Name = 'DHCPServer'
    Status = ''
}

if ($DHCPServer.State -eq 'Enabled') {
    $ManifestResult.Status = 'Present'
    Write-Verbose -Message ('{0} was found installed on the image' -f $ArtifactName)
}
else {
    $ManifestResult.Status = 'Absent'    
    Write-Verbose -Message ('{0} was NOT found installed on the image' -f $ArtifactName)
}

### Write the result to the manifest file
$ManifestResult | ConvertTo-Json | Set-Content -Path $Manifest

Write-Verbose -Message ('Finished discovering {0} artifact' -f $ArtifactName)
}

