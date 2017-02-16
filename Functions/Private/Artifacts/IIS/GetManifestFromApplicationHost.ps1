function GetManifestFromApplicationHost {
<#
.SYNOPSIS
Scans for presence of the Internet Information Services (IIS) Web Server 

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

$ApplicationHostPath = "$MountPath\Windows\System32\inetsrv\config\applicationHost.config"

if (Test-Path -Path $ApplicationHostPath) {

    $IISConfig = [xml](Get-Content -Path $ApplicationHostPath)
    
    $AllSites = $IISConfig | Select-Xml -XPath "//sites" | Select-Object -ExpandProperty Node
    $siteDefaults = $AllSites.siteDefaults
    $applicationDefaults = $AllSites.applicationDefaults
    $virtualDirectoryDefaults = $AllSites.virtualDirectoryDefaults
    $sites = $AllSites.site

    $Websites = New-Object System.Collections.ArrayList
    ForEach ($site in $sites) { 

        $applications = New-Object System.Collections.ArrayList
        ForEach ($application in $site.application) {
            $virtualDirectories =  New-Object System.Collections.ArrayList
            ForEach ($virtualDirectory in $application.virtualDirectory){
                $virtualDirectories.add([PSCustomObject]@{ 
                    Path = $virtualDirectory.path;
                    PhysicalPath = $virtualDirectory.physicalPath.replace('%SystemDrive%\','\').replace('C:\','\').Replace('c:\','\');
                }) | Out-Null
            }
            $applications.add([PSCustomObject]@{ 
                Path = $application.path;
                ApplicationPool = $application.ApplicationPool;
                VirtualDirectories = $virtualDirectories;
            }) | Out-Null
        }

        $bindings = New-Object System.Collections.ArrayList
        ForEach ($binding in $site.bindings.binding) {
            $bindings.add([PSCustomObject]@{ 
                Protocol = $binding.Protocol;
                BindingInformation = $binding.bindingInformation
            }) | Out-Null
        }

        $Websites.add([PSCustomObject]@{ 
                    Name = $site.name;
                    ID = $site.id;
                    Applications = $applications;
                    Bindings = $bindings;                    
            }) | Out-Null
    }

    $AllApplicationPools = $IISConfig | Select-Xml -XPath "//applicationPools" | Select-Object -ExpandProperty Node
    $ApplicationPools = $AllApplicationPools.add.name
    $ApplicationPoolDefaults = $allApplicationPools.applicationPoolDefaults
    $appPools = [PSCustomObject]@{
                        applicationPools = $ApplicationPools
                        applicationPoolDefaults = [PSCustomObject]@{managedRuntimeVersion = $ApplicationPoolDefaults.managedRuntimeVersion;
                                                                    processModel = [PSCustomObject]@{ identityType = $ApplicationPoolDefaults.processModel.identityType }
                }
        }
    $HandlerList = $IISConfig | Select-Xml -XPath "//handlers" | Select-Object -ExpandProperty Node | Select-Object -ExpandProperty add

    $DefaultHandlers = [xml](Get-Content $PSScriptRoot\DefaultHandlers.xml) | Select-Xml -XPath "//handlers" | Select-Object -ExpandProperty Node | Select-Object -ExpandProperty add
    $handlers = New-object System.Collections.ArrayList

    $AspNetInstalled = $false    
    foreach ($Handler in $HandlerList) {
        if (-not $DefaultHandlers.name -match $handler.Name) {

            $handlers.Add([PSCustomObject]@{
                Name = $Handler.name
                Path = $Handler.path
                Verb = $Handler.verb
                }) | Out-Null
        }
        if ($Handler.path.Contains('.aspx')) {
            $AspNetInstalled = $true
        }
    }

    #feature selection not valid for 2008 and below:
    if ([decimal]$ImageWindowsVersion -gt 6.1) {
            $WindowsFeatures = Get-WindowsOptionalFeature -Path $Mount.Path
            $IIS = $WindowsFeatures.Where{$_.FeatureName -eq 'IIS-WebServer'}
            $EnabledFeatures = $WindowsFeatures.Where{$_.State -eq 'Enabled'}
            $FeaturesToExport = $EnabledFeatures.Where{$_.FeatureName -match 'IIS'-or 
                                                    $_.FeatureName -match 'ASPNET' -or 
                                                    $_.FeatureName -match 'Asp-Net' -and 
                                                    $_.FeatureName -NotMatch 'Management'} | Sort-Object FeatureName | Select-Object -ExpandProperty FeatureName 
        
            $ManifestResult.FeatureName = $FeaturesToExport  -join ';'  
            if ($ManifestResult.FeatureName -like '*ASPNET*' -or $ManifestResult.FeatureName -like '*Asp-Net*'){
            $AspNetInstalled = $true
            }        
    }
      
    $ManifestResult.Status = 'Present'
    $ManifestResult.Websites = $Websites
    $ManifestResult.ApplicationPools = $appPools
    $ManifestResult.HttpHandlers = $handlers
    $ManifestResult.SiteDefaults = $siteDefaults
    $ManifestResult.ApplicationDefaults = $applicationDefaults
    $ManifestResult.VirtualDirectoryDefaults = $virtualDirectoryDefaults

    if ($AspNetInstalled -eq $true){        
        $ManifestResult.AspNetStatus = 'Present'
    } 

    #TODO 
    $ManifestResult.AspNet35Status = 'Absent'
}

return $ManifestResult 
}