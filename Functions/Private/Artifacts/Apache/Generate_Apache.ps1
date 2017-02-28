function Generate_Apache {
<#
.SYNOPSIS
Generates Dockerfile contents for Apache Web Server component 

.PARAMETER ManifestPath
The filesystem path where the JSON manifests are stored.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $MountPath,
    
    [Parameter(Mandatory = $true)]
    [string] $ManifestPath
)

    $ArtifactName = Split-Path -Path $PSScriptRoot -Leaf

    Write-Verbose -Message ('Generating result for {0} component' -f (Split-Path -Path $PSScriptRoot -Leaf))
    $Manifest = '{0}\{1}.json' -f $ManifestPath, $ArtifactName

    $Artifact = Get-Content -Path $Manifest -Raw | ConvertFrom-Json

    $ResultBuilder = GetDockerfileBuilder
    if ($Artifact.Status -eq 'Present') {
        $null = $ResultBuilder.AppendLine('LABEL Description="Apache" Vendor="Docker Inc." Version="2.4.23"')
        
        $null = $ResultBuilder.AppendLine('RUN mkdir $env:SystemDrive\Apache; ``')
        $null = $ResultBuilder.AppendLine('    Invoke-WebRequest -Uri https://www.apachelounge.com/download/VC14/binaries/httpd-2.4.23-win64-VC14.zip -OutFile $env:TEMP\apache.zip; ``')
        $null = $ResultBuilder.AppendLine('    Expand-Archive -Path $env:TEMP\apache.zip -DestinationPath c:\apache; ``')
        $null = $ResultBuilder.AppendLine('    Remove-Item -Path $env:TEMP\Apache.zip')
        
        $null = $ResultBuilder.AppendLine('ENTRYPOINT ["c:\apache\apache24\bin\httpd.exe", "-w"]')
        
        Write-Verbose -Message ('Artifact is present: {0}. Adding text to Dockerfile {1}.' -f $ArtifactName, $Result)
    }

    return $ResultBuilder.ToString()
}

