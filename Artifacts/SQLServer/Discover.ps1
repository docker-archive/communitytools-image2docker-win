<#
.SYNOPSIS
Scans for presence of the MSMQ Windows feature 

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

function GetSQLInstances 
    ### Helper function to retrieve an array of SQL instances
    [CmdletBinding()]
    param (

    )
}

$ArtifactName = Split-Path -Path $PSScriptRoot -Leaf
Write-Verbose -Message ('Started discovering {0} artifact' -f $ArtifactName)

### Path to the manifest
$Manifest = '{0}\{1}.json' -f $OutputPath, $ArtifactName

### Create a HashTable to store the results (this will get persisted to JSON)
$ManifestResult = @{
    Name = 'SQLServer'
    Instances = @()
}


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
$PathList = Get-ChildItem -Path 'HKLM:\$TempKey\Microsoft\Microsoft SQL Server\Instance Names\SQL'

### Obtain DisplayName property from each registry item
foreach ($Item in $PathList) {
    $InstanceName = Get-ItemProperty -Path $Software.PSPath -Name DisplayName -ErrorAction Ignore
    if ($DisplayName -and $DisplayName -ne '') {
        $SoftwareList += $DisplayName
        Write-Verbose -Message ('Found a new SQL Server instance: {0}' -f $DisplayName)
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

### Write the result to the manifest file
$ManifestResult | ConvertTo-Json | Set-Content -Path $Manifest

Write-Verbose -Message ('Finished discovering {0} artifact' -f $ArtifactName)