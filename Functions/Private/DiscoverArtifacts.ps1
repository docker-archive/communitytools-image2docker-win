function DiscoverArtifacts {

    <#
    .SYNOPSIS
    Performs discovery of artifacts specified by user

     .PARAMETER Artifact
    This specifies which artifact/s that you are looking to discover

    .PARAMETER OutputPath
    This specifies where you want to output discovered items to.

    .PARAMETER ArtifactParam
    This is used for passing parameters to the resulting Generate functions.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $MountPath,

        [Parameter(Mandatory = $true)]
        [string[]] $Artifact,

        [Parameter(Mandatory = $true)]
        [string] $OutputPath,

        [Parameter(Mandatory = $true)]
        [string] $ImageWindowsVersion,

        [Parameter(Mandatory = $false)]
        [string[]] $ArtifactParam
    )

    ### Perform discovery of artifacts
    
    if (!$ArtifactParam) {
        foreach ($item in $Artifact) {
        & "Discover_$item" -OutputPath $OutputPath -MountPath $MountPath -ImageWindowsVersion $ImageWindowsVersion
        }
    }
    else {
        foreach ($item in $Artifact) {
        & "Discover_$item" -OutputPath $OutputPath -MountPath $MountPath -ImageWindowsVersion $ImageWindowsVersion -ArtifactParam $ArtifactParam
        }
    }

}

