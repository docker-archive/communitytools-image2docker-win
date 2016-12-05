function Discover_AllWindowsFeatures {
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

$WindowsFeatures = Get-WindowsOptionalFeature -Path $MountPath | Where-Object State -EQ Enabled

$ManifestResult = @{
    FeatureName = ''
    Status = ''
}
$DefaultEnabledFeatures = (Get-Content $PSScriptRoot\DefaultFeatures.txt).Split(';')
$EnabledFeatures = New-Object System.Collections.ArrayList

$wind
foreach ($WindowsFeature in $WindowsFeatures) {
     if ($DefaultEnabledFeatures -notcontains $WindowsFeature.FeatureName) {
            $EnabledFeatures.Add($WindowsFeature.FeatureName) | Out-Null 
        }
    }

$ManifestResult.FeatureName = $EnabledFeatures -join ';'
$ManifestResult.Status = 'Enabled'   
### Write the result to the manifest file
$ManifestResult | ConvertTo-Json | Set-Content -Path $Manifest

Write-Verbose -Message ('Finished discovering {0} artifact' -f $ArtifactName)
}

