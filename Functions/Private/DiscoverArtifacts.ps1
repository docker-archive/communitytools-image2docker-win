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
        [string] $OutputPath,

        [Parameter(Mandatory = $false)]
        [string[]] $ArtifactParam
    )

    ### Perform discovery of artifacts
    
    if (!$ArtifactParam) {
        foreach ($item in $Artifact) {
        & "Discover_$item" -OutputPath $OutputPath -MountPath $Mount.Path
        }
    }
    else {
        foreach ($item in $Artifact) {
        & "Discover_$item" -OutputPath $OutputPath -MountPath $Mount.Path -ArtifactParam $ArtifactParam
        }
    }
}