function CleanupMountPath {
    <#
    .SYNOPSIS
    Cleans up the mount directory, after the image has been dismounted.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $MountPath 
    )

    Remove-Item -Path 
}