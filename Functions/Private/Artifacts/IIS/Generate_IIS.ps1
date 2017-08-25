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
    [string] $MountPath,

    [Parameter(Mandatory = $true)]
    [string] $ManifestPath,

    [Parameter(Mandatory = $false)]
    [string[]] $ArtifactParam        
)

function IncludePath([string[]] $pathParts) {
    if ($ArtifactParam -eq $null){
        return $true
    }
    ForEach ($param in $ArtifactParam){
        $parts = $param.Split('/', [System.StringSplitOptions]::RemoveEmptyEntries)        
        $comp = Compare-Object $parts $pathParts
        if ($comp -eq $null -Or $comp -isnot [System.Array]) {
            return $true
        }
        $indicators = $comp | Foreach-Object { $_.SideIndicator } | Select-Object -unique
        return ($indicators).Count -eq 1 
    }
    return $false
}

function ProcessDirectory([System.Text.StringBuilder] $DirectoryBuilder, 
                          [System.Text.StringBuilder] $CopyBuilder,
                          [System.Text.StringBuilder] $AclBuilder,
                          [string] $SourcePath,
                          [bool] $FirstDirectory) {
    Write-Verbose "Processing source directory: $SourcePath"  
    $targetPath = $SourcePath.Substring(2) # skip the local drive letter
    if ($FirstDirectory -eq $true) {
        $newPath = "RUN New-Item -Path 'C:$targetPath' -Type Directory -Force; ``" 
    }
    else {
        $newPath = "    New-Item -Path 'C:$targetPath' -Type Directory -Force; ``" 
    }
    $null = $DirectoryBuilder.AppendLine($newPath)

    $copy = 'COPY ["{0}", "{1}"]' -f (Split-Path $SourcePath -Leaf),($targetPath -Replace "\\","/")
    $null = $CopyBuilder.AppendLine($copy)

    $null = $AclBuilder.AppendLine('RUN $path=' + "'C:$targetPath'; ``")
    $null = $AclBuilder.AppendLine('    $acl = Get-Acl $path; `')
    $null = $AclBuilder.AppendLine('    $newOwner = [System.Security.Principal.NTAccount](''BUILTIN\IIS_IUSRS''); `')
    $null = $AclBuilder.AppendLine('    $acl.SetOwner($newOwner); `')
    $null = $AclBuilder.AppendLine('    dir -r $path | Set-Acl -aclobject  $acl')

    $fullSourcePath = $SourcePath
    if ($global:SourceType -eq [SourceType]::Image -or
        $global:SourceType -eq [SourceType]::Remote) {
        $fullSourcePath = $MountPath + $targetPath
    }
    Copy-Item $fullSourcePath $ManifestPath -Recurse -Force
}

$ArtifactName = Split-Path -Path $PSScriptRoot -Leaf

Write-Verbose -Message ('Generating result for {0} component' -f (Split-Path -Path $PSScriptRoot -Leaf))
$Manifest = '{0}\{1}.json' -f $ManifestPath, $ArtifactName 
$ResultBuilder = GetDockerfileBuilder

$Artifact = Get-Content -Path $Manifest -Raw | ConvertFrom-Json

if ($Artifact.Status -eq 'Present') {    
    Write-Verbose ('Copying {0} configuration files' -f $ArtifactName)
    $ConfigPath = $MountPath + "\" + "Windows\System32\inetsrv\config"
    if (Test-Path -Path $ConfigPath) {
        Copy-Item $ConfigPath $ManifestPath -Recurse    
    }
    $DockerfileTemplate = 'Dockerfile-IIS.template'
    if ($Artifact.AspNetStatus -eq 'Present') {
        $DockerfileTemplate = 'Dockerfile-ASPNET.template'
    }
    if ($Artifact.AspNet35Status -eq 'Present') {
        $DockerfileTemplate = 'Dockerfile-ASPNET-35.template'
    }
    $ResultBuilder = GetDockerfileBuilder($DockerfileTemplate)

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

    for ($i=0;$i -lt $Artifact.Websites.Count;$i++) {
        $Site = $Artifact.Websites[$i]
        $include = IncludePath($Site.Name)
        if ($include -ne $true){
            Write-Verbose "** Skipping site path: $($Site.Name)"
            continue
        }
  
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

        # process the main site path
        $DirectoryBuilder = New-Object System.Text.StringBuilder
        $CopyBuilder = New-Object System.Text.StringBuilder
        $AclBuilder = New-Object System.Text.StringBuilder
        ProcessDirectory -DirectoryBuilder $DirectoryBuilder -CopyBuilder $CopyBuilder -AclBuilder $AclBuilder -SourcePath $mainVirtualDir.PhysicalPath -FirstDirectory $true

        # creating the website creates the default app & vdir underneath it
        $sourcePath = $mainVirtualDir.PhysicalPath
        $targetPath = $sourcePath.Substring(2)
        $newSite = "RUN New-Website -Name '$($Site.Name)' -PhysicalPath 'C:$targetPath' -Port $($mainBinding.BindingInformation.split(':')[-2]) -Force; ``"
        $AppBuilder = New-Object System.Text.StringBuilder
        $null = $AppBuilder.AppendLine($newSite)

        # now create additional apps and vdirs
        ForEach ($application in $Site.Applications) {
            $appVirtualDir = $application.VirtualDirectories.where{$_.Path -eq '/' }            
            $appName = $application.Path.Substring(1) #remove initial '/'

            $include = IncludePath($Site.Name, $appName)
            if ($appName.Length -gt 0 -And $include -ne $true){
                Write-Verbose "** Skipping app path: $($Site.Name)$($application.Path)"
                continue
            }

            if ($appName.Length -gt 0) {
                Write-Verbose -Message ('Creating web app {0}' -f $appName)
                $sourcePath = $appVirtualDir.PhysicalPath
                $targetPath = $sourcePath.Substring(2)
                $newApp = "    New-WebApplication -Name '$appName' -Site '$($Site.Name)' -PhysicalPath 'C:$targetPath' -Force; ``"
                $null = $AppBuilder.AppendLine($newApp)                
                if ($sourcePath -ne $mainVirtualDir.PhysicalPath) {
                    ProcessDirectory -DirectoryBuilder $DirectoryBuilder -CopyBuilder $CopyBuilder -AclBuilder @AclBuilder -SourcePath $sourcePath                  
                }
            }

            $virtualDirectories = $application.VirtualDirectories.where{$_.Path -ne '/' } 
            ForEach ($virtualDir in $virtualDirectories) {
                $dirName = $virtualDir.Path.Substring(1) #remove initial '/'

                $include = IncludePath($Site.Name, $appName, $dirName)
                if ($dirName.Length -gt 0 -And $include -ne $true){
                    Write-Verbose "** Skipping vdir path: $($Site.Name)$($application.Path)$($virtualDir.Path)"
                    continue
                }

                Write-Verbose -Message ('Creating virtual directory {0}' -f $dirName)
                $sourcePath = $virtualDir.PhysicalPath
                $targetPath = $sourcePath.Substring(2)
                $newDir = ''
                if ($appName.Length -gt 0) {
                    $newDir = "    New-WebVirtualDirectory -Name '$dirName' -Application '$appName' -Site '$($Site.Name)' -PhysicalPath 'C:$targetPath'; ``"
                }
                else {
                    $newDir = "    New-WebVirtualDirectory -Name '$dirName' -Site '$($Site.Name)' -PhysicalPath 'C:$targetPath'; ``"
                }
                $null = $AppBuilder.AppendLine($newDir)

                if ($sourcePath -ne $mainVirtualDir.PhysicalPath) {           
                    ProcessDirectory -DirectoryBuilder $DirectoryBuilder -CopyBuilder $CopyBuilder -AclBuilder @AclBuilder -SourcePath $sourcePath
                }
            }
        }      

        $null = $ResultBuilder.AppendLine("# Set up website: $($Site.Name)") 
        
        $null = $ResultBuilder.AppendLine($DirectoryBuilder.ToString().Trim().TrimEnd('``'))
        $null = $ResultBuilder.AppendLine('') 

        $null = $ResultBuilder.AppendLine($AppBuilder.ToString().Trim().TrimEnd('``'))
        $null = $ResultBuilder.AppendLine('') 

        Write-Verbose -Message ('Writing instruction to expose port for site {0}' -f  $Site.Name)    
        $null = $ResultBuilder.AppendLine("EXPOSE $($mainBinding.BindingInformation.split(':')[-2])")
        $null = $ResultBuilder.AppendLine('')

        $null = $ResultBuilder.AppendLine($CopyBuilder.ToString().Trim().TrimEnd('``'))
        $null = $ResultBuilder.AppendLine('')   

        $null = $ResultBuilder.AppendLine($AclBuilder.ToString().Trim().TrimEnd('``'))
        $null = $ResultBuilder.AppendLine('')   
    }
}


return $ResultBuilder.ToString()

}