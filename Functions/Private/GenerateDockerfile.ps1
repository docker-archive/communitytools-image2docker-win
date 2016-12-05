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

    Write-Verbose -Message 'Generating Dockerfile based on discovered artifacts'
    ### Verify that the Dockerfile template is available
    $DockerfileTemplate = '{0}\Resources\Dockerfile-template' -f $ModulePath

    if (!(Test-Path -Path $DockerfileTemplate)) {
        throw 'Couldn''t find the Dockerfile template. Please make sure this exists under: {0}' -f $DockerfileTemplate
    }

    ### Get the Dockerfile template
    $Dockerfile = Get-Content -Raw -Path $DockerfileTemplate
    
    foreach ($item in $Artifact) {
        If (! $ArtifactParam) {
            $Result = & "Generate_$item" -ManifestPath $ArtifactPath 
            $Dockerfile += '{0}{1}' -f $Result, "`r`n"
        }
        else {
            $Result = & "Generate_$item" -ManifestPath $ArtifactPath -ArtifactParam $ArtifactParam
            $Dockerfile += '{0}{1}' -f $Result, "`r`n"
        }
        
}

    $DockerfilePath = '{0}\Dockerfile' -f $ArtifactPath
    Set-Content -Path $DockerfilePath -Value $Dockerfile

}

