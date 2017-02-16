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
        [string] $ArtifactPath,
        
        [Parameter(Mandatory = $false)]
        [string[]] $Artifact,

        [Parameter(Mandatory = $false)]
        [string[]] $ArtifactParam

    )

    Write-Verbose -Message ('Generating Dockerfile based on discovered artifacts in :{0}' -f $Mount.Path)

    $Dockerfile = ''
    if (! $ArtifactParam) {
        $Dockerfile = & "Generate_$Artifact" -ManifestPath $ArtifactPath 
    }
    else {
        $Dockerfile = & "Generate_$Artifact" -ManifestPath $ArtifactPath -ArtifactParam $ArtifactParam            
    }

    $DockerfilePath = '{0}\Dockerfile' -f $ArtifactPath
    Set-Content -Path $DockerfilePath -Value $Dockerfile.Trim()
}