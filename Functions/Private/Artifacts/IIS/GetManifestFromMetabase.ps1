function GetManifestFromMetabase {
<#
.SYNOPSIS
Scans for presence of the Internet Information Services (IIS) Web Server on Windows Server 2003 images.

.PARAMETER MountPath
The path where the Windows image was mounted to.

.PARAMETER OutputPath
The filesystem path where the discovery manifest will be emitted.

.PARAMETER ArtifactParam
Optional - one or more Website names to include in the output.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess",'')]
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $MountPath,

    [Parameter(Mandatory = $true)]
    [string] $OutputPath,

    [Parameter(Mandatory = $true)]
    [string] $ImageWindowsVersion,

    [Parameter(Mandatory = $false)]
    [string[]] $ArtifactParam
)

$ManifestResult = @{
    FeatureName = ''
    Status = 'Absent'
    AspNetStatus = 'Absent'
    AspNet35Status = 'Absent'
}

$MetabasePath = "$MountPath\Windows\System32\inetsrv\MetaBase.xml"

if (Test-Path -Path $MetabasePath) {

    $IISConfig = [xml](Get-Content -Path $MetabasePath)
    
    $AspNetInstalled = $false
    ForEach ($svc in $IISConfig.configuration.MBProperty.IIsWebService) {
        if ($svc.ApplicationDependencies.Contains('ASP.NET')) {
            $AspNetInstalled = $true
            break
        }
    }

    $Sites = New-Object System.Collections.ArrayList
    ForEach ($site in $IISConfig.configuration.MBProperty.IIsWebServer) {  
        if ($site.ServerBindings -ne $null){
            $Sites.add([PSCustomObject]@{ 
                Name = $site.ServerComment;
                ID = $site.Location;
                Bindings = $site.ServerBindings  }) | Out-Null
        }
    }
    Write-Verbose -Message "Found: $($Sites.Count) sites"
    
    $apps = $IISConfig.configuration.MBProperty.IIsWebVirtualDir
    if ($ArtifactParam) {
        $apps = $apps.where{$_.AppFriendlyName -in $ArtifactParam }
    }

    $Websites = New-Object System.Collections.ArrayList
    ForEach ($app in $apps) { 
        if ($app.Path -ne $null){
            $siteID = $app.Location.Substring(0, $app.Location.ToLower().IndexOf('/root'))
            $site = $Sites.where({$_.ID -eq $siteID})
            $Websites.add([PSCustomObject]@{ 
                Name = $app.AppFriendlyName;
                ID = $app.Location;
                ApplicationPool = $app.AppPoolId;
                PhysicalPath = $app.Path.replace('%SystemDrive%\','\').replace('C:\','\').Replace('c:\','\');
                Binding = [PSCustomObject]@{ Protocol = 'http'; #TODO - discover protocol from metabase
                BindingInformation = "*" + $site.Bindings } }) | Out-Null
            }
        }
    

    $Websites = New-Object System.Collections.ArrayList
    $iis = $IISConfig.configuration.MBProperty
    ForEach ($site in $iis.IIsWebServer.where{$_.ServerBindings -ne $null}) { 
        $siteId = $site.Location
        $applications = New-Object System.Collections.ArrayList
        
        # in IIS 6 the app for the website is the root virtual directory
        $mainApp = $iis.IIsWebVirtualDir.where{$_.Location -eq "$SiteId/root"}
        $virtualDirectories =  New-Object System.Collections.ArrayList
        $mainVirtualDir = [PSCustomObject]@{ 
                    Path = '/';
                    PhysicalPath = $mainApp.Path.replace('%SystemDrive%\','\').replace('C:\','\').Replace('c:\','\');
                }
        $virtualDirectories.add($mainVirtualDir) | Out-Null   

        # virtual directories are IIsWebVirtualDir elements with no app name
        ForEach ($virtualDirectory in $iis.IIsWebVirtualDir.where{
            $_.Location.StartsWith("$SiteId/root/") -and
            $_.AppFriendlyName -eq $null}){
                $virtualDirectories.add([PSCustomObject]@{ 
                    Path = '/' + $virtualDirectory.Location.Substring("$SiteId/root/".Length);
                    PhysicalPath = $virtualDirectory.Path.replace('%SystemDrive%\','\').replace('C:\','\').Replace('c:\','\');
                }) | Out-Null
            }             
        $applications.add([PSCustomObject]@{ 
                Path = '/';
                ApplicationPool = ''; # TODO
                VirtualDirectories = $virtualDirectories;
            }) | Out-Null

        # apps are IisWebDirectory elements with an app name
        ForEach ($application in $iis.IIsWebDirectory.where{
            $_.Location.StartsWith("$SiteId/root/") -and
            $_.AppFriendlyName -ne $null}){
            $path = $application.Location.Substring("$SiteId/root/".Length)
            $virtualDirectories =  New-Object System.Collections.ArrayList
            $virtualDirectories.add([PSCustomObject]@{ 
                    Path = '/';
                    PhysicalPath = "$($mainVirtualDir.PhysicalPath)\$path"
                }) | Out-Null  
            $applications.add([PSCustomObject]@{ 
                Path = '/' + $path;
                ApplicationPool = $application.AppPoolId;
                VirtualDirectories = $virtualDirectories;
            }) | Out-Null
        }

        $bindings = New-Object System.Collections.ArrayList
        $bindings.add([PSCustomObject]@{ 
            Protocol = 'http'; #TODO - discover protocol from metabase
            BindingInformation = $site.ServerBindings
        }) | Out-Null

        $Websites.add([PSCustomObject]@{ 
                    Name = $site.ServerComment;
                    ID = $siteId;
                    Applications = $applications;
                    Bindings = $bindings;
            }) | Out-Null
    }

    $ManifestResult.FeatureName = ''    
    $ManifestResult.Status = 'Present'
    $ManifestResult.Websites = $Websites
    $ManifestResult.ApplicationPools = New-object System.Collections.ArrayList
    $ManifestResult.HttpHandlers = New-object System.Collections.ArrayList
    $ManifestResult.SiteDefaults = New-object System.Collections.ArrayList
    $ManifestResult.ApplicationDefaults =New-object System.Collections.ArrayList
    $ManifestResult.VirtualDirectoryDefaults = New-object System.Collections.ArrayList

    if ($AspNetInstalled -eq $true){        
        $ManifestResult.AspNetStatus = 'Present'
    }

    #TODO 
    $ManifestResult.AspNet35Status = 'Absent'
}

return $ManifestResult 
}