function Discover_IIS {
<#
.SYNOPSIS
Scans for presence of the Internet Information Services (IIS) Web Server 

.PARAMETER MountPath
The path where the Windows image was mounted to.

.PARAMETER OutputPath
The filesystem path where the discovery manifest will be emitted.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess",'')]
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $MountPath,
    [Parameter(Mandatory = $true)]
    [string] $OutputPath
)

$ArtifactName = Split-Path -Path $PSScriptRoot -Leaf
Write-Verbose -Message ('Started discovering {0} artifact' -f $ArtifactName)

### Path to the manifest
$Manifest = '{0}\{1}.json' -f $OutputPath, $ArtifactName

### Create a HashTable to store the results (this will get persisted to JSON)
$ManifestResult = @{
    FeatureName = ''
    Status = ''
}

$WindowsFeatures = Get-WindowsOptionalFeature -Path $MountPath

$IIS = $WindowsFeatures.Where{$_.FeatureName -eq 'IIS-WebServer'}

$EnabledFeatures = $WindowsFeatures.Where{$_.State -eq 'Enabled'}

$FeaturesToExport = $EnabledFeatures.Where{$_.FeatureName -match 'IIS'} | Sort-Object FeatureName | Select-Object -ExpandProperty FeatureName

if ($IIS.State -eq 'Enabled') {

    $IISConfig = [xml](Get-Content -Path $MountPath\Windows\System32\inetsrv\config\applicationHost.config)
    
    $AllSites = $IISConfig | Select-Xml -XPath "//sites" | Select-Object -ExpandProperty Node
    $siteDefaults = $AllSites.siteDefaults
    $applicationDefaults = $AllSites.applicationDefaults
    $virtualDirectoryDefaults = $AllSites.virtualDirectoryDefaults
    $sites = $AllSites.site
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
}
else {
    Write-Verbose -Message 'IIS service is NOT present on the system'
    $ManifestResult.Status = 'Absent'
}

### Write the result to the manifest file
$ManifestResult | ConvertTo-Json -Depth 3 | Set-Content -Path $Manifest

Write-Verbose -Message ('Finished discovering {0} artifact' -f $ArtifactName)
}


