<#
.SYNOPSIS
Scans for presence of the Internet Information Services (IIS) Web Server 

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

function GetWebsites {
    ### Helper function to obtain list of virtual directories
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $MountPath
    )

    $IISConfig = [xml](Get-Content -Path $MountPath\Windows\System32\inetsrv\config\applicationHost.config)
    $Sites = $IISConfig.configuration.'system.applicationHost'.sites
    $Websites = ForEach ($site in $sites) { 
        [PSCustomObject]@{ 
            Name = $site.site.name; 
            PhysicalPath = $site.site.application.virtualDirectory.physicalPath;
            }
        }
    return $Websites 
}

function GetHttpHandlerMappings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $MountPath
    )

    $IISConfig = [xml](Get-Content -Path $MountPath\Windows\System32\inetsrv\config\applicationHost.config)

    $HandlerList = $IISConfig.configuration.'system.webServer'.handlers.add

    foreach ($Handler in $HandlerList) {
        Write-Output -InputObject ([PSCustomObject]@{
            Name = $Handler.name
            Path = $Handler.path
            Verb = $Handler.verb
            })
    }
}

$ArtifactName = Split-Path -Path $PSScriptRoot -Leaf
Write-Verbose -Message ('Started discovering {0} artifact' -f $ArtifactName)

### Path to the manifest
$Manifest = '{0}\{1}.json' -f $OutputPath, $ArtifactName

### Create a HashTable to store the results (this will get persisted to JSON)
$ManifestResult = @{
    Name = 'IIS'
    Status = ''
}

$IIS = Get-WindowsOptionalFeature -FeatureName IIS-WebServer -Path $MountPath 

if ($IIS.State -eq 'Enabled') {
    Write-Verbose -Message 'IIS service is present on the system'
    $ManifestResult.Status = 'Present'
    $ManifestResult.Websites = GetWebsites -MountPath $MountPath
    $ManifestResult.HttpHandlers = GetHttpHandlerMappings -MountPath $MountPath
}
else {
    Write-Verbose -Message 'IIS service is NOT present on the system'
    $ManifestResult.Status = 'Absent'
}

### Write the result to the manifest file
$ManifestResult | ConvertTo-Json | Set-Content -Path $Manifest

Write-Verbose -Message ('Finished discovering {0} artifact' -f $ArtifactName)