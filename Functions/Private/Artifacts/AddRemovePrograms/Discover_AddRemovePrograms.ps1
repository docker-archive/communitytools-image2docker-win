function Discover_AddRemovePrograms {
<#
.SYNOPSIS
Scans for Add/Remove Programs entries

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
Write-Verbose -Message ('Starting discovery for {0} artifact' -f $ArtifactName)

### Determine the path where the manifest file will be stored
$ManifestPath = '{0}\{1}.json' -f $OutputPath, $ArtifactName

### Create a temporary key to mount the SOFTWARE registry hive on
$TempKey = (New-Guid).Guid

### Mount the SOFTWARE hive
$RegistryMount = @{
    FilePath = 'reg.exe'
    ArgumentList = 'load "HKLM\{0}" "{1}\Windows\System32\Config\SOFTWARE"' -f $TempKey, $MountPath
    Wait = $true
}
Start-Process @RegistryMount
Write-Verbose -Message ('Finished loading the SOFTWARE registry hive from {0}' -f $MountPath)

### Define empty array to hold installed software items
$SoftwareList = @()

### Obtain registry paths for installed software
$PathList = @()
$PathList += Get-ChildItem -Path HKLM:\$TempKey\Microsoft\Windows\CurrentVersion\Uninstall
$PathList += Get-ChildItem -Path HKLM:\$TempKey\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall

### Obtain DisplayName property from each registry item
foreach ($Software in $PathList) {
    #$DisplayName = (Get-ItemProperty -Path $Software.PSPath -Name DisplayName -ErrorAction Ignore).DisplayName
    $DisplayName = ($Software.PSChildName) -replace "\n","" -replace "\r",""
    if ($DisplayName -and $DisplayName -ne '') {
        $SoftwareList += $DisplayName
        Write-Verbose -Message ('Added new Add/Remove Programs software item: {0}' -f $DisplayName)
    }
}

### Unmount the SOFTWARE registry hive from the mounted image
$RegistryUnmount = @{
    FilePath = 'reg.exe'
    ArgumentList = 'unload "HKLM\{0}"' -f $TempKey
    Wait = $true
}
Start-Process @RegistryUnmount
Write-Verbose -Message 'Finished unmounting the registry hive'

### Write out the discovery results to the manifest file
$SoftwareList | ConvertTo-Json | Set-Content -Path $ManifestPath
Write-Verbose -Message ('Finished discovery for {0} artifact' -f (Split-Path -Path $PSScriptRoot -Leaf))

}

