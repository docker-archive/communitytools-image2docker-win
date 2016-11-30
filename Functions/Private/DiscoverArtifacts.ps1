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
       & "Discover_$item" -OutputPath $OutputPath -MountPath $Mount.Path
    }
}