function GenerateDockerfile {
    <#
    .SYNOPSIS
    This function is responsible for generating a Dockerfile, based on a template.

    .PARAMETER ArtifactPath
    The filesystem path to the artifacts 
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $ArtifactPath,
        [Parameter(Mandatory = $false)]
        [string[]] $Artifact
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
        $Result = & $ModulePath\Artifacts\$item\Generate.ps1 -ManifestPath $ArtifactPath
        $Dockerfile += '{0}{1}' -f $Result, "`r`n"
    }

    $DockerfilePath = '{0}\Dockerfile' -f $ArtifactPath
    Set-Content -Path $DockerfilePath -Value $Dockerfile
}