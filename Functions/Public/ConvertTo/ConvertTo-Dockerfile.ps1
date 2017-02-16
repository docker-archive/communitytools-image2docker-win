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
    This paramater is used in conjunction with the artifact paramater and currently is used when specifying IIS Websites.

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

    ConvertTo-Dockerfile -ImagePath E:\VMVirtualHardDisks\WebServer.VHDX -OutputPath C:\Docker\IIS_SingleSite\ -MountPath C:\Image\ -Artifact IIS -ArtifactParam 'Default Web Site' -Force  -Verbose

    With this example we will be mounting a VHDX for a Virtual Machine called WebServer and the image will be mounted at the C:\Image\ location.
    We have specified that we want to only return the IIS Artifact and for this we have provided the name of the WebSite that we want to return via the ArtifactParam Parameter, in this case we have specified that we want to return the 'Default Web Site' that is created when the IIS feature is activated on a new server.

    We have also specified the Force Parameter which will remove any existing files and folders that are in the OutputPath directory and will reuse this directory for the output from this command.

    #>


    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateScript({if (!(Test-Path -Path $PSItem)) { return $false } else { return $true } })]
        [string] $ImagePath,

        [Parameter(Mandatory = $false)]
        [string] $OutputPath,

        [Parameter(Mandatory = $false)]
        [string] $MountPath,

        [Parameter(Mandatory = $true)]
        [string] $Artifact,

        [Parameter(Mandatory = $false)]
        [string[]] $ArtifactParam,

        [Parameter(Mandatory = $false)]
        [Switch] $Force,

        [Parameter(Mandatory = $false)]
        [Switch] $Local
    )

    # TODO - validat eLOcal & ImagePath

    ### If the user doesn't specify an output path, then generate one
    if (!$PSBoundParameters.Keys.Contains('OutputPath')) {
        $OutputPath = GenerateOutputFolder
    } 
    elseif(($PSBoundParameters.Keys.Contains('OutputPath')) -and ($PSBoundParameters.Keys.Contains('Force'))) {
        $OutputPath = GenerateOutputFolder -Path $OutputPath -Force
    }
    else {
        $OutputPath = GenerateOutputFolder -Path $OutputPath
    }

    # load the source - local drive, or VHD
    if ($Local) {
        $MountPath = $env:SystemDrive
        $version = [Environment]::OSVersion.Version
        $ImageWindowsVersion = "$($version.Major).$($version.Minor)"
        Write-Verbose -Message "Using local drive: $MountPath"
    }
    else {
        # Verify the image type before proceeding
        $ImageType = GetImageType -Path $ImagePath
        Write-Verbose -Message ('Image type is: {0}' -f $ImageType)

        try {
            # Mount the image to a directory
            $Mount = MountImage -ImagePath $ImagePath -MountPath $MountPath
            $MountPath = $Mount.Path
            Write-Verbose -Message ('Finished mounting image to: {0}' -f $MountPath)
        }
        catch {
            throw 'Fatal error: couldn''t mount image file: {0}' -f $PSItem
        }
    
        # Get the Windows version in the image, returns Major.Minor - e.g. 6.2 is Server 2012
        # https://en.wikipedia.org/wiki/List_of_Microsoft_Windows_versions
        $info = Get-WindowsImage -Index 1 -ImagePath $ImagePath
        $ImageWindowsVersion = "$($info.MajorVersion).$($info.MinorVersion)"
    }

    Write-Verbose -Message ('Starting conversion process')
    try {
        ### Perform artifact discovery
        if (!$PSBoundParameters.Keys.Contains('Artifact')) {
            $Artifact = Get-WindowsArtifact
        }
        if (!$PSBoundParameters.Keys.Contains('ArtifactParam')) {
            DiscoverArtifacts -MountPath $MountPath -Artifact $Artifact -OutputPath $OutputPath -ImageWindowsVersion $ImageWindowsVersion
        }
        else {
            DiscoverArtifacts -MountPath $MountPath -Artifact $Artifact -OutputPath $OutputPath -ImageWindowsVersion $ImageWindowsVersion -ArtifactParam $ArtifactParam
        }

        ### Generate Dockerfile
        if (!$PSBoundParameters.Keys.Contains('ArtifactParam')) {
            GenerateDockerfile -MountPath $MountPath -ArtifactPath $OutputPath -Artifact $Artifact
        }
        else {
            GenerateDockerfile -MountPath $MountPath -ArtifactPath $OutputPath -Artifact $Artifact -ArtifactParam $ArtifactParam
        }
        Write-Verbose -Message 'Finished generating the Dockerfile'
    }
    finally {
        if ($Mount) {
            ### Dismount the image when inspection is completed
            $null = Dismount-WindowsImage -Path $MountPath -Discard
            Write-Verbose -Message ('Finished dismounting the Windows image from {0}' -f $MountPath)
        }
    }
}

