<#
.SYNOPSIS
Generates Dockerfile contents for Internet Information Services (IIS) feature 

.PARAMETER ManifestPath
The filesystem path where the JSON manifests are stored.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $ManifestPath
)

$ArtifactName = Split-Path -Path $PSScriptRoot -Leaf

Write-Verbose -Message ('Generating result for {0} component' -f (Split-Path -Path $PSScriptRoot -Leaf))
$Manifest = '{0}\{1}.json' -f $ManifestPath, $ArtifactName 

$Artifact = Get-Content -Path $Manifest -Raw | ConvertFrom-Json

if ($Artifact.Status -eq 'Present') {
    $Result = '
RUN powershell.exe -ExecutionPolicy Bypass -Command \ 
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebserverRole, IIS-WebServer, IIS-WebServerManagementTools;'
    $Add = "`r`n"
    [int]$SiteCount = $Artifact.Websites.name.Length;
    for ($i=0;$i -lt $SiteCount;$i++){
        Write-Verbose -Message ('Creating new website for {0} site' -f $Artifact.Websites.Name[$i])
        $SitePath = ($Artifact.Websites.MountPath + '\' + (Split-Path $Artifact.Websites.PhysicalPath[$i] -NoQualifier)) -replace '\\%SystemDrive%\\', "\"
        $Result += '\{1}New-Item -Path {0} -ItemType directory; \{1}' -f $Artifact.Websites.PhysicalPath[$i], "`r`n"
        $Result += 'New-Website -Name ''{0}'' -PhysicalPath "{1}";' -f ($Artifact.Websites.Name[$i] -replace "'","''"), $Artifact.Websites.PhysicalPath[$i], "`r`n"
        Write-Verbose -Message ('Copying files for {0} site' -f $Artifact.Websites.Name[$i])
        Copy-Item $SitePath $ManifestPath
        $Add += "ADD {0} {1}`r`n" -f (Split-Path $Artifact.Websites.PhysicalPath[$i] -Leaf),$Artifact.Websites.PhysicalPath[$i] 
    }

    ### Add IIS HTTP handlers to the Dockerfile
    foreach ($HttpHandler in $Artifact.HttpHandlers) {
        $Result += 'New-WebHandler -Name "{0}" -Path "{1}" -Verb "{2}" \{3}' -f $HttpHandler.Name, $HttpHandler.Path, $HttpHandler.Verb, "`r`n" 
    }

    Write-Output -InputObject ($Result + $Add)
    
}

