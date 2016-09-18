function DiscoverArtifacts {
    <#
    .SYNOPSIS
    Performs discovery of artifacts specified by user
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]] $Artifact,
        [Parameter(Mandatory = $true)]
        [string] $OutputPath        
    )

    ### Perform discovery of artifacts
    foreach ($item in $Artifact) {
        $DiscoveryScript = '{0}\Artifacts\{1}\Discover.ps1' -f $ModulePath, $item
        Write-Verbose -Message ('Invoking artifact discovery scripts: {0}' -f $DiscoveryScript)
        . $DiscoveryScript -OutputPath $OutputPath -MountPath $Mount.Path
    }
}