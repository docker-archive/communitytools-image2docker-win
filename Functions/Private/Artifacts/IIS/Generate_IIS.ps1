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
$ResultBuilder = New-Object System.Text.StringBuilder

$Artifact = Get-Content -Path $Manifest -Raw | ConvertFrom-Json

if ($Artifact.Status -eq 'Present') {
    $DockerfileTemplate = 'Dockerfile-IIS.template'
    Write-Verbose ('Copying {0} configuration files' -f $ArtifactName)
    $ConfigPath = $Mount.Path + "\" + "Windows\System32\inetsrv\config"
    if (Test-Path -Path $ConfigPath) {
        Copy-Item $ConfigPath $ManifestPath -Recurse    
    }
    if ($Artifact.AspNetStatus -eq 'Present') {
        $DockerfileTemplate = 'Dockerfile-ASPNET.template'
    }
    if ($Artifact.AspNet35Status -eq 'Present') {
        $DockerfileTemplate = 'Dockerfile-ASPNET-35.template'
    }
    $Dockerfile = Get-Content -Raw -Path "$ModulePath\Resources\$DockerfileTemplate"
    $null = $ResultBuilder.AppendLine($Dockerfile.Trim())

    if ($Artifact.FeatureName.length -gt 0) {
        $null = $ResultBuilder.AppendLine("RUN Enable-WindowsOptionalFeature -Online -FeatureName $($Artifact.FeatureName.Replace(';',','))")
        $null = $ResultBuilder.AppendLine('')
    }

    if ($Artifact.HttpHandlers.Count > 0) {
        Write-Verbose -Message ('Writing instruction to add HTTP handlers')
        $null = $ResultBuilder.Append('RUN ')
        foreach ($HttpHandler in $Artifact.HttpHandlers) {
             $null = $ResultBuilder.AppendLine('New-WebHandler -Name "{0}" -Path "{1}" -Verb "{2}" `' -f $HttpHandler.Name, $HttpHandler.Path, $HttpHandler.Verb)
        }
        $null = $ResultBuilder.AppendLine('')
    }    

    $null = $ResultBuilder.AppendLine('')
    for ($i=0;$i -lt $Artifact.Websites.Count;$i++) {
        $WebSiteBuilder = New-Object System.Text.StringBuilder
        $Site = $Artifact.Websites[$i]
        $null = $WebSiteBuilder.AppendLine("# Set up website: $($Site.Name)")    

        if ($Site.Applications -is [system.array]){
            $mainApp = $Site.Applications.where{$_.Path -eq '/' }
        }
        else {
            $mainApp = $Site.Applications
        }
        if ($mainApp.VirtualDirectories -is [system.array]){
            $mainVirtualDir = $mainApp.VirtualDirectories.where{$_.Path -eq '/' }
        }
        else {
            $mainVirtualDir = $mainApp.VirtualDirectories
        }        
        $mainBinding = $Site.Bindings[0]

        Write-Verbose -Message ('Writing instruction to create site {0}' -f  $Site.Name)

        # create empty paths for all the site directories
        $newPath = "RUN New-Item -Path 'C:$($mainVirtualDir.PhysicalPath)' -Type Directory; ``" 
        $null = $WebSiteBuilder.AppendLine($newPath)

        $sourcePaths = $Site.Applications.VirtualDirectories.PhysicalPath
        ForEach ($sourcePath in $sourcePaths) {
            if ($sourcePath -ne $mainVirtualDir.PhysicalPath) {           
                $newPath = "    New-Item -Path 'C:$sourcePath' -Type Directory -Force; ``" 
                $null = $WebSiteBuilder.AppendLine($newPath)
            }
        }  

        $null = $ResultBuilder.AppendLine($WebSiteBuilder.ToString().Trim().TrimEnd('``'))
        $null = $ResultBuilder.AppendLine('')  
        $WebSiteBuilder = New-Object System.Text.StringBuilder     

        # creating the website creates the default app & vdir underneath it
        $newSite = "RUN New-Website -Name '$($Site.Name)' -PhysicalPath 'C:$($mainVirtualDir.PhysicalPath)' -Port $($mainBinding.BindingInformation.split(':')[-2]) -Force; ``"
        $null = $WebSiteBuilder.AppendLine($newSite)

        # now create additional apps and vdirs
        ForEach ($application in $Site.Applications) {
            $appVirtualDir = $application.VirtualDirectories.where{$_.Path -eq '/' }            
            $appName = $application.Path.Substring(1) #remove initial '/'

            if ($appName.Length -gt 0) {
                Write-Verbose -Message ('Creating web app {0}' -f $appName)
                $newApp = "    New-WebApplication -Name '$appName' -Site '$($Site.Name)' -PhysicalPath 'C:$($appVirtualDir.PhysicalPath)' -Force; ``"
                $null = $WebSiteBuilder.AppendLine($newApp)
            }

            $virtualDirectories = $application.VirtualDirectories.where{$_.Path -ne '/' } 
            ForEach ($virtualDir in $virtualDirectories) {
                $dirName = $virtualDir.Path.Substring(1) #remove initial '/'
                Write-Verbose -Message ('Creating virtual directory {0}' -f $dirName)
                $newDir = ''
                if ($appName.Length -gt 0) {
                    $newDir = "    New-WebVirtualDirectory -Name '$dirName' -Application '$appName' -Site '$($Site.Name)' -PhysicalPath 'C:$($virtualDir.PhysicalPath)'; ``"
                }
                else {
                    $newDir = "    New-WebVirtualDirectory -Name '$dirName' -Site '$($Site.Name)' -PhysicalPath 'C:$($virtualDir.PhysicalPath)'; ``"
                }
                $null = $WebSiteBuilder.AppendLine($newDir)
            }
        }      
        $null = $ResultBuilder.AppendLine($WebSiteBuilder.ToString().Trim().TrimEnd('``'))
        $null = $ResultBuilder.AppendLine('') 

        Write-Verbose -Message ('Writing instruction to expose port for site {0}' -f  $Site.Name)    
        $null = $ResultBuilder.AppendLine("EXPOSE $($mainBinding.BindingInformation.split(':')[-2])")
        $null = $ResultBuilder.AppendLine('')

        $sourcePaths = $Site.Applications.VirtualDirectories.PhysicalPath
        ForEach ($sourcePath in $sourcePaths) {
            $SitePath = $Mount.Path + $sourcePath
            Write-Verbose -Message ('Copying website files from {0} to {1}' -f $SitePath, $ManifestPath)
            Copy-Item $SitePath $ManifestPath -Recurse -Force

            Write-Verbose -Message ('Writing instruction to copy files for {0} site' -f  $Site.Name)            
            $copy = "COPY {0} {1}" -f (Split-Path $sourcePath -Leaf),($sourcePath -Replace "\\","/")
            $null = $ResultBuilder.AppendLine($copy)
        }

        $null = $ResultBuilder.AppendLine('')   
    }
}


Write-Output $ResultBuilder.ToString() -NoEnumerate

}

