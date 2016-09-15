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

function GetVirtualDirectories {
    ### Helper function to obtain list of virtual directories
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $MountPath
    )

    $IISConfig = [xml](Get-Content -Path $MountPath\Windows\System32\inetsrv\config\applicationHost.config)

    return $IISConfig.configuration.'system.applicationHost'.sites.site.name
}

function GetHttpHandlerMappings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $MountPath
    )

    $IISConfig = [xml](Get-Content -Path $MountPath\Windows\System32\inetsrv\config\applicationHost.config)

    return $IISConfig.configuration.'system.webServer'.handlers.add.name
}

$ArtifactName = Split-Path -Path $PSScriptRoot -Leaf
Write-Verbose -Message ('Started discovering {0} artifact' -f $ArtifactName)

### Path to the manifest
$Manifest = '{0}\{1}.json' -f $OutputPath, $ArtifactName

### Create a HashTable to store the results (this will get persisted to JSON)
$ManifestResult = @{
    Name = 'IIS'
    Status = ''
    VirtualDirectories = GetVirtualDirectories -MountPath $MountPath
    HttpHandlers = GetHttpHandlerMappings -MountPath $MountPath
}

$IIS = Get-WindowsOptionalFeature -Name Web-Server -Path $MountPath 

if ($IIS.Status -eq 'Present') {
    Write-Verbose -Message 'IIS service is present on the system'
    $ManifestResult.Status = 'Present'
}
else {
    Write-Verbose -Message 'IIS service is NOT present on the system'
    $ManifestResult.Status = 'Absent'
}

### Write the result to the manifest file
$ManifestResult | ConvertTo-Json | Set-Content -Path $Manifest

Write-Verbose -Message ('Finished discovering {0} artifact' -f $ArtifactName)