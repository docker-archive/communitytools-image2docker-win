function Generate_Tomcat {
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
        if ($Artifact.JDKStatus -eq 'Present') {
            $null = $ResultBuilder.AppendLine('')
            $null = $ResultBuilder.AppendLine('# Install Chocolatey')
            $null = $ResultBuilder.AppendLine("RUN powershell -NoProfile -ExecutionPolicy Bypass -Command `"`$env:ChocolateyUseWindowsCompression='false'; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))`"") 
            $null = $ResultBuilder.AppendLine('')
            $null = $ResultBuilder.AppendLine("# JDK Version $($Artifact.JDKVersion)")
            if ($Artifact.JDKVersion.StartsWith("1.8")) {
                $null = $ResultBuilder.AppendLine('RUN choco install -y jdk8')
            } 
            if ($Artifact.JDKVersion.StartsWith("1.7")) {
                $null = $ResultBuilder.AppendLine('RUN choco install -y jdk7')
            } 
        }

        $Source = $Artifact.Path;
        if ( $Source.EndsWith("\bin\catalina.bat")) {
            $Source = $Source.Remove($Source.length - 17, 17);
            Write-Verbose -Message ('Creating Zip of Directory {0}' -f ($Source))
            $ArchiveName = Split-Path -Path $Source -Leaf
        }
        $TomcatZipPath = '{0}\{1}.zip' -f $ArtifactPath, $ArchiveName
        Add-Type -assembly "system.io.compression.filesystem"
        [io.compression.zipfile]::CreateFromDirectory($Source, $TomcatZipPath) 
        $null = $ResultBuilder.AppendLine('')
        $null = $ResultBuilder.AppendLine("# Create the Tomcat Folder from Archive")
        $null = $ResultBuilder.AppendLine("COPY $ArchiveName.zip c:\temp\")
        $null = $ResultBuilder.AppendLine("RUN powershell -Command Expand-Archive -Path c:\temp\$ArchiveName.zip -DestinationPath c:\$ArchiveName")

        # Now you can start tomcat...
        $null = $ResultBuilder.AppendLine("ENV CATALINA_HOME c:\$($ArchiveName)")
        $null = $ResultBuilder.AppendLine("CMD c:\$($ArchiveName)\bin\catalina.bat run")
        Write-Verbose -Message 'Writing instruction to expose catalina port'
        $null = $ResultBuilder.AppendLine("EXPOSE $($Artifact.CatalinaPort)")
        $null = $ResultBuilder.AppendLine('')

        Write-Verbose -Message ('Artifact is present: {0}. Adding text to Dockerfile {1}.' -f $ArtifactName, $Result)
    }

    return $ResultBuilder.ToString()
}

