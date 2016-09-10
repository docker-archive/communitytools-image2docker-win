<#
.SYNOPSIS
Scans for the Apache Web Server 

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

### Path to the Apache manifest
$Manifest = '{0}\{1}.json' -f $OutputPath, $ArtifactName

### Create a HashTable to store the results (this will get persisted to JSON)
$ManifestResult = @{
    Name = 'Apache'
    Status = ''
    Path = ''
}

$Apache = Get-ChildItem -Path $MountPath\Apache\* -Recurse -Include httpd.exe

if ($Apache.Count -ge 1) {
    Write-Verbose -Message ('Discovered Apache Web Server (httpd.exe) at "{0}"' -f $Apache[0].FullName)
    $ManifestResult.Status = 'Present'
    $ManifestResult.Path = $Apache[0].FullName
}
else {
    $ManifestResult.Status = 'Absent'
}

### Write the result to the manifest file
$ManifestResult | ConvertTo-Json | Set-Content -Path $Manifest

Write-Verbose -Message ('Finished discovering {0} artifact' -f $ArtifactName)