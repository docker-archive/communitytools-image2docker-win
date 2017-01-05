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
}

return $ManifestResult 
}