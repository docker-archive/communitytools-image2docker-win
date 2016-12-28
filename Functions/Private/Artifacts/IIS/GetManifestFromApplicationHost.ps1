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

    [Parameter(Mandatory = $false)]
    [string[]] $ArtifactParam
)

$ManifestResult = @{
    FeatureName = ''
    Status = ''
}

$WindowsFeatures = Get-WindowsOptionalFeature -Path $MountPath
$IIS = $WindowsFeatures.Where{$_.FeatureName -eq 'IIS-WebServer'}
$EnabledFeatures = $WindowsFeatures.Where{$_.State -eq 'Enabled'}
$FeaturesToExport = $EnabledFeatures.Where{$_.FeatureName -match 'IIS'-or 
                                           $_.FeatureName -match 'ASPNET' -or 
                                           $_.FeatureName -match 'Asp-Net' -and 
                                           $_.FeatureName -NotMatch 'Management'} | Sort-Object FeatureName | Select-Object -ExpandProperty FeatureName 

if ($IIS.State -eq 'Enabled') {

    $IISConfig = [xml](Get-Content -Path $MountPath\Windows\System32\inetsrv\config\applicationHost.config)
    
    $AllSites = $IISConfig | Select-Xml -XPath "//sites" | Select-Object -ExpandProperty Node
    $siteDefaults = $AllSites.siteDefaults
    $applicationDefaults = $AllSites.applicationDefaults
    $virtualDirectoryDefaults = $AllSites.virtualDirectoryDefaults
    $sites = $AllSites.site
    if ($ArtifactParam) {
        $sites = $sites.where{$_.name -in $ArtifactParam }
    }
    $Websites = New-Object System.Collections.ArrayList
    ForEach ($site in $sites) {        
       $Websites.add([PSCustomObject]@{ 
                    Name = $site.name;
                    ID = $site.id;
                    ApplicationPool = $site.application.ApplicationPool
                    PhysicalPath = $site.application.virtualDirectory.physicalPath.replace('%SystemDrive%\','\').replace('C:\','\').Replace('c:\','\');
                    Binding = [PSCustomObject]@{ Protocol = $site.bindings.binding.Protocol;
                                                 BindingInformation = $site.bindings.binding.bindingInformation } }) | Out-Null
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
        
    foreach ($Handler in $HandlerList) {
        if (-not $DefaultHandlers.name -match $handler.Name) {

     $handlers.Add([PSCustomObject]@{
            Name = $Handler.name
            Path = $Handler.path
            Verb = $Handler.verb
            }) | Out-Null
    }
}
    Write-Verbose -Message 'IIS service is present on the system'
    $ManifestResult.FeatureName = $FeaturesToExport  -join ';'    
    $ManifestResult.Status = 'Present'
    $ManifestResult.Websites = $Websites
    $ManifestResult.ApplicationPools = $appPools
    $ManifestResult.HttpHandlers = $handlers
    $ManifestResult.SiteDefaults = $siteDefaults
    $ManifestResult.ApplicationDefaults = $applicationDefaults
    $ManifestResult.VirtualDirectoryDefaults = $virtualDirectoryDefaults

    if ($ManifestResult.FeatureName -like '*ASPNET*' -or $ManifestResult.FeatureName -like '*Asp-Net*'){
        $ManifestResult.AspNetStatus = 'Present'
    }
    else {
        $ManifestResult.AspNetStatus = 'Absent'
    }
}
else {
    $ManifestResult.Status = 'Absent'
    $ManifestResult.AspNetStatus = 'Absent'
}

return $ManifestResult 
}