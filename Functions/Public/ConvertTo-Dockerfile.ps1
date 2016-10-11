function ConvertTo-Dockerfile {
    <#
    .SYNOPSIS
    Scans and converts a valid WIM or VHDX file into a Dockerfile.

    .DESCRIPTION
    This command is the main entrypoint into this PowerShell module.

    .PARAMETER ImagePath
    The filesystem path to the valid WIM or VHDX file that will be inspected for artifacts.

    NOTE: You will need administrative permissions in order to mount and inspect image files.

    .PARAMETER OutputPath
    An optional parameter that specifies the filesystem path where artifacts and the resulting
    Dockerfile will be stored. If you do not specify a path, a temporary directory will be created for you.

    .PARAMETER Artifact
    Specify the discovery artifacts that will be scanned during the ConvertTo-Dockerfile command.

    You can obtain the supported list of artifacts by running the Get-WindowsArtifacts command in the same module.

    .PARAMETER MountPath
    The filesystem path to the directory where the image will be mounted to for discovery.
    The folder will be created if it does not exist.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if (!(Test-Path -Path $PSItem)) {
                return $false
            }
            else { return $true }
         })]
        [string] $ImagePath,
        [Parameter(Mandatory = $false)]
        [string] $OutputPath,
        [Parameter(Mandatory = $false)]
        [string] $MountPath,
        [Parameter(Mandatory = $false)]
        [string[]] $Artifact
    )

    ### If the user doesn't specify an output path, then generate one
    if (!$PSBoundParameters.Keys.Contains('OutputPath')) {
        $OutputPath = GenerateOutputFolder
    } else {
        $OutputPath = GenerateOutputFolder -Path $OutputPath
    }

    Write-Verbose -Message ('Starting conversion process')

    ### Verify the image type before proceeding
    $ImageType = GetImageType -Path $ImagePath
    Write-Verbose -Message ('Image type is: {0}' -f $ImageType)

            try {
            ### Mount the image to a directory

            $Mount = MountImage -ImagePath $ImagePath -MountPath $MountPath
            Write-Verbose -Message ('Finished mounting image to: {0}' -f $Mount.Path)
        }
        catch {
            throw 'Fatal error: couldn''t mount image file: {0}' -f $PSItem
        }

    ### Perform artifact discovery
    if (!$PSBoundParameters.Keys.Contains('Artifact')) {
        $Artifact = Get-WindowsArtifacts
    }
    DiscoverArtifacts -Artifact $Artifact -OutputPath $OutputPath

    ### Generate Dockerfile
    GenerateDockerfile -ArtifactPath $OutputPath -Artifact $Artifact
    Write-Verbose -Message 'Finished generating the Dockerfile'

    ### Dismount the image when inspection is completed
    $null = Dismount-WindowsImage -Path $Mount.Path -Discard
    Write-Verbose -Message ('Finished dismounting the Windows image from {0}' -f $Mount.Path)
}
