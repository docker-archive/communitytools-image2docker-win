Function Generate_IIS {
<#
.SYNOPSIS
Generates Dockerfile contents for Internet Information Services (IIS) feature 

.PARAMETER ManifestPath
The filesystem path where the JSON manifests are stored.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess",'')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments",'')]
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
    Write-Verbose ('Copying {0} configuration files' -f $ArtifactName)
    $ConfigPath = $MountPath + "\" + "Windows\System32\inetsrv\config"
    Copy-Item $ConfigPath $ManifestPath -Recurse
    $Result = "RUN Enable-WindowsOptionalFeature -Online -FeatureName $($Artifact.FeatureName.Replace(';',',')) ; ``"
    $EndOfLine = "`r`n"
    $Add = "`r`n"
    $Expose = 'EXPOSE '
    $ExposePorts = New-Object System.Collections.ArrayList
    $ExposeText = ''
    [int]$SiteCount = $Artifact.Websites.Count;
    for ($i=0;$i -lt $SiteCount;$i++) {
        Write-Verbose -Message ('Creating new website for {0} site' -f $Artifact.Websites[$i].Name)
        $SitePath = $MountPath + $Artifact.Websites[$i].PhysicalPath
        $Result += $EndOfLine
        $Result += 'New-Item -Path {0} -ItemType directory -Force; `' -f $Artifact.Websites[$i].PhysicalPath
        $Result += $EndOfLine
        $Result += 'New-Website -Name ''{0}'' -PhysicalPath "{1}" -Port {2} -Force; `' -f ($Artifact.Websites[$i].Name -replace "'","''"), $Artifact.Websites[$i].PhysicalPath, $Artifact.Websites[$i].binding.bindingInformation.split(':')[-2] 
        $ExposePorts.Add($Artifact.Websites[$i].binding.bindingInformation.split(':')[-2]) | Out-Null  
        Write-Verbose -Message ('Copying files for {0} site' -f $Artifact.Websites[$i].Name)
        Copy-Item $SitePath $ManifestPath -Recurse
        $Add += "ADD {0} {1}`r`n" -f (Split-Path $Artifact.Websites[$i].PhysicalPath -Leaf),($Artifact.Websites[$i].PhysicalPath -Replace "\\","/") 
    }

$Result += $EndOfLine
    ### Add IIS HTTP handlers to the Dockerfile
    foreach ($HttpHandler in $Artifact.HttpHandlers) {
        $Result += 'New-WebHandler -Name "{0}" -Path "{1}" -Verb "{2}" `' -f $HttpHandler.Name, $HttpHandler.Path, $HttpHandler.Verb
        $Result += $EndOfLine   
}
    $Add += "ADD config Windows/System32/inetsrv/"

$ExposeText += $EndOfLine
$ExposePorts.ForEach{$ExposeText += "$Expose $_ $EndOfLine" }    
$endOutput = ($Result + $Add + $ExposeText)
Write-Output $endOutput -NoEnumerate
    
}

}

