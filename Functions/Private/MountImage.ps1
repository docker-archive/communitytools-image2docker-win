function MountImage {
    <#
    .SYNOPSIS
    Mounts a valid WIM or VHDX image to a directory.

    .PARAMETER ImagePath
    The filesystem path to the image file.

    .PARAMETER MountPath
    The directory that the image file will be mounted to.

    NOTE: This parameter is optional. If omitted, a directory will be dynamically created as the mount point.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $ImagePath,
        [AllowNull()]
        [AllowEmptyString()]
        [Parameter(Mandatory = $false)]
        [string] $MountPath
    )

    ### If the user hasn't specified a mount path 
    if (!$PSBoundParameters.Keys.Contains('MountPath') -or [string]::IsNullOrEmpty($MountPath)) {
        $MountPath = '{0}\{1}-mount' -f $env:TEMP, (New-Guid).Guid
        Write-Verbose -Message ('User didn''t specify a mount path. Using: {0}' -f $MountPath)
    }

    ### Create the directory if it does not exist.
    if (!(Test-Path -Path $MountPath)) {
        mkdir -Path $MountPath -Force
    }

    ### Mount the WIM or VHDX image
    Mount-WindowsImage -ImagePath $ImagePath -Path $MountPath -Index 1
    Write-Verbose -Message ('Finished mounting image {0} at mount point {1}' -f $ImagePath, $MountPath)
}