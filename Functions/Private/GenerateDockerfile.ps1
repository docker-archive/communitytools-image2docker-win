function GenerateDockerfile {

    <#
    .SYNOPSIS
    This function is responsible for generating a Dockerfile, based on a template.

    .PARAMETER ArtifactPath
    The filesystem path to the artifacts

    .PARAMETER ArtifactParam
    This is used for passing parameters to the resulting Generate functions.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess",'')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $MountPath,

        [Parameter(Mandatory = $true)]
        [string] $ArtifactPath,
        
        [Parameter(Mandatory = $false)]
        [string[]] $Artifact,

        [Parameter(Mandatory = $false)]
        [string[]] $ArtifactParam

    )

    Write-Verbose -Message ('Generating Dockerfile based on discovered artifacts in :{0}' -f $MountPath)

    $Dockerfile = ''
    if (! $ArtifactParam) {
        $Dockerfile = & "Generate_$Artifact" -MountPath $MountPath -ManifestPath $ArtifactPath 
    }
    else {
        $Dockerfile = & "Generate_$Artifact" -MountPath $MountPath -ManifestPath $ArtifactPath -ArtifactParam $ArtifactParam            
    }

    $DockerfilePath = '{0}\Dockerfile' -f $ArtifactPath
    Set-Content -Path $DockerfilePath -Value $Dockerfile.Trim()
}