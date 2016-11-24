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
    Dockerfile will be stored. If you do not specify a path, a temporary directory will be created for you within the $env:Temp location.

    .PARAMETER MountPath
    The filesystem path to the directory where the image will be mounted to for discovery.
    The folder will be created if it does not exist.
    If you do not specify a path, a temporary directory will be created for you within the $env:Temp location and will be removed 
    
    .PARAMETER Artifact
    Specify the discovery artifacts that will be scanned during the ConvertTo-Dockerfile command.

    You can use tab completion to find all of the supported artifacts that can be discovered.

    .PARAMETER ArtifactParam
    This paramater is used in conjunction with the artifact paramater and currently is used when specifying a Single IIS Web App.

    Please see the examples for how to use this parameter.

    .PARAMETER Force
    This Parameter is for use when you want to use a folder that you have either already used for creating a Dockerfile from an image 
    
    .EXAMPLE

    ConvertTo-Dockerfile -ImagePath E:\VMVirtualHardDisks\WebServer.VHDX -OutputPath C:\Docker\IIS\ -MountPath C:\Image\ -Artifact IIS -Verbose

    With this example we will be mounting a VHDX for a Virtual Machine called WebServer and the image will be mounted at the C:\Image\ location. We have specified that we want to only return the IIS Artifact from this machine so this will only perform the discovery of IIS related items and will output the required items to the OutputPath directory which in this case we have specified this to be C:\Docker\IIS\ and we will return all verbose output when running this command.

    .EXAMPLE    
    
    ConvertTo-Dockerfile -ImagePath E:\VMVirtualHardDisks\WebServer.VHDX -OutputPath C:\Docker\WebServer\ -Verbose

    With this example we will be mounting a VHDX for a Virtual Machine called WebServer. 
    As we have not specifiec a MountPath the Image will be mounted into a folder in the Temp path location and will be removed when this command finishes. 
    As we have not specified a specific Artifact from this machine, this function will return artifacts for all of the available artifacts that this tool can attempt to discover and will output the required items to the OutputPath directory which in this case we have specified this to be C:\Docker\WebServer\
    
    .EXAMPLE    
    
    ConvertTo-Dockerfile -ImagePath E:\VMVirtualHardDisks\WebServer.VHDX 

    With this example we will be mounting a VHDX for a Virtual Machine called WebServer. 
    As we have not specifiec a MountPath the Image will be mounted into a folder in the Temp path location and will be removed when this command finishes.
    
    As we have not specified a specific Artifact from this machine, this function will return artifacts for all of the available artifacts that this tool can attempt to discover and as we have not specified an OutputPath this command will create a folder in the $env:temp folder where all of the artifacts, required files and the resulting Dockerfile will be output to.
    
    .EXAMPLE

    ConvertTo-Dockerfile -ImagePath E:\VMVirtualHardDisks\WebServer.VHDX -OutputPath C:\Docker\IIS_SingleApp\ -MountPath C:\Image\ -Artifact IIS_SingleApp -ArtifactParam 'Default Web Site' -Force  -Verbose

    With this example we will be mounting a VHDX for a Virtual Machine called WebServer and the image will be mounted at the C:\Image\ location.
    We have specified that we want to only return the IIS_SingleApp Artifact and for this we have provided the name of the WebApp that we want to return via the ArtifactParam Parameter, in this case we have specified that we want to return the 'Default Web Site' that is created when the IIS feature is activated on a new server.

    We have also specified the Force Parameter which will remove any existing files and folders that are in the OutputPath directory and will reuse this directory for the output from this command.

    #>


    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({if (!(Test-Path -Path $PSItem)) { return $false } else { return $true } })]
        [string] $ImagePath,

        [Parameter(Mandatory = $false)]
        [string] $OutputPath,

        [Parameter(Mandatory = $false)]
        [string] $MountPath,

        [Parameter(Mandatory = $false)]
        [string[]] $Artifact,

        [Parameter(Mandatory = $false)]
        [string[]] $ArtifactParam,

        [Parameter(Mandatory = $false)]
        [Switch] $Force

    )

    ### If the user doesn't specify an output path, then generate one
    if (!$PSBoundParameters.Keys.Contains('OutputPath')) {
        $OutputPath = GenerateOutputFolder
    } 
    elseif(($PSBoundParameters.Keys.Contains('OutputPath')) -and ($PSBoundParameters.Keys.Contains('Force')))
    {
        $OutputPath = GenerateOutputFolder -Path $OutputPath -Force
    }
    else {
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
    if (!$PSBoundParameters.Keys.Contains('ArtifactParam')) {
         DiscoverArtifacts -Artifact $Artifact -OutputPath $OutputPath
    }
    else {
        DiscoverArtifacts -Artifact $Artifact -OutputPath $OutputPath -ArtifactParam $ArtifactParam
    }

    ### Generate Dockerfile
    if (!$PSBoundParameters.Keys.Contains('ArtifactParam')) {
        GenerateDockerfile -ArtifactPath $OutputPath -Artifact $Artifact
    }
    else {
        GenerateDockerfile -ArtifactPath $OutputPath -Artifact $Artifact -ArtifactParam $ArtifactParam
    }
    Write-Verbose -Message 'Finished generating the Dockerfile'

    ### Dismount the image when inspection is completed
    $null = Dismount-WindowsImage -Path $Mount.Path -Discard
    Write-Verbose -Message ('Finished dismounting the Windows image from {0}' -f $Mount.Path)
}
