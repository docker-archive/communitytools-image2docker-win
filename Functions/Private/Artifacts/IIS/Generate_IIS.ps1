Function Generate_IIS {
<#
.SYNOPSIS
Generates Dockerfile contents for Internet Information Services (IIS) feature 

.PARAMETER ManifestPath
The filesystem path where the JSON manifests are stored.

.PARAMETER ArtifactParam
Optional - one or more Website names to include in the output.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess",'')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments",'')]
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $ManifestPath,

    [Parameter(Mandatory = $false)]
    [string[]] $ArtifactParam
)

$ArtifactName = Split-Path -Path $PSScriptRoot -Leaf

Write-Verbose -Message ('Generating result for {0} component' -f (Split-Path -Path $PSScriptRoot -Leaf))
$Manifest = '{0}\{1}.json' -f $ManifestPath, $ArtifactName 

$Artifact = Get-Content -Path $Manifest -Raw | ConvertFrom-Json

if ($Artifact.Status -eq 'Present') {
    Write-Verbose ('Copying {0} configuration files' -f $ArtifactName)
    $ConfigPath = $MountPath + "\" + "Windows\System32\inetsrv\config"
    Copy-Item $ConfigPath $ManifestPath -Recurse

    $ResultBuilder = New-Object System.Text.StringBuilder

    Write-Verbose -Message ('Writing instruction to install IIS')
    $null = $ResultBuilder.AppendLine('# Install Windows features for IIS')
    $null = $ResultBuilder.Append('RUN Add-WindowsFeature Web-server')
    if ($Artifact.AspNetStatus -eq 'Present') {
        Write-Verbose -Message ('Writing instruction to install ASP.NET')
        $null = $ResultBuilder.Append(', NET-Framework-45-ASPNET, Web-Asp-Net45')
    }
    $null = $ResultBuilder.AppendLine('')
    $null = $ResultBuilder.AppendLine("RUN Enable-WindowsOptionalFeature -Online -FeatureName $($Artifact.FeatureName.Replace(';',','))")

    if ($Artifact.HttpHandlers.Count > 0) {
        Write-Verbose -Message ('Writing instruction to add HTTP handlers')
        $null = $ResultBuilder.Append('RUN ')
        foreach ($HttpHandler in $Artifact.HttpHandlers) {
             $null = $ResultBuilder.AppendLine('New-WebHandler -Name "{0}" -Path "{1}" -Verb "{2}" `' -f $HttpHandler.Name, $HttpHandler.Path, $HttpHandler.Verb)
        }
    }
    $null = $ResultBuilder.AppendLine('')

    for ($i=0;$i -lt $Artifact.Websites.Count;$i++) {
        $Site = $Artifact.Websites[$i]
        $SitePath = $Mount.Path + $Site.PhysicalPath
        Write-Verbose -Message ('Copying website files from {0} to {1}' -f $SitePath, $ManifestPath)
        Copy-Item $SitePath $ManifestPath -Recurse

        Write-Verbose -Message ('Writing instruction to copy files for {0} site' -f  $Site.Name)
        $null = $ResultBuilder.AppendLine("# Set up website: $($Site.Name)")        
        $copy = "COPY {0} {1}" -f (Split-Path $Site.PhysicalPath -Leaf),($Site.PhysicalPath -Replace "\\","/")
        $null = $ResultBuilder.AppendLine($copy)

        Write-Verbose -Message ('Writing instruction to create site {0}' -f  $Site.Name)
        $newSite = 'RUN New-Website -Name ''{0}'' -PhysicalPath "C:{1}" -Port {2} -Force' -f ($Site.Name -replace "'","''"), $Site.PhysicalPath, $Site.binding.bindingInformation.split(':')[-2]
        $null = $ResultBuilder.AppendLine($newSite)

        Write-Verbose -Message ('Writing instruction to expose port for site {0}' -f  $Site.Name)
        $null = $ResultBuilder.AppendLine("EXPOSE $($Site.binding.bindingInformation.split(':')[-2])")
        $null = $ResultBuilder.AppendLine('')
    }
        
    $null = $ResultBuilder.AppendLine('CMD /Wait-Service.ps1 -ServiceName W3SVC -AllowServiceRestart')
}


Write-Output $ResultBuilder.ToString() -NoEnumerate

}

