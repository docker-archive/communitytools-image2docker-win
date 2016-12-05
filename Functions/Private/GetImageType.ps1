function GetImageType {

    <#
    .SYNOPSIS
    Retrieves the type of the image.

    .PARAMETER Path
    The path to the image file that will be inspected.

    .OUTPUTS
    This command emits a value from the [ImageType] enumeration
    #>
    [CmdletBinding()]
    param (
        [ValidateScript({
            if (Test-Path -Path $PSItem) { $true }
            else { throw 'File does not exist or permission denied.' }
        })]
        [string] $Path
    )

    $Path = Resolve-Path -Path $Path

    try {
        Write-Verbose -Message ('Reading image file: {0}' -f $Path)
        $Image = Get-WindowsImage -ImagePath $Path -ErrorAction Stop
        if ($Image) {
            Write-Verbose -Message 'Image file appears to be a valid WIM or VHDX file.'
        }
        Write-Verbose -Message ('Image file {0} contains {1} images' -f $Path, $Image.Count)

        ### If the file name ends with 'wim', or it has more than one image, then it's a WIM
        if ($Image.Count -gt 1 -or ($Path -match 'wim$' -and ($Image.ImageName.Length -ge 1))) {
            Write-Verbose -Message 'This image appears to be a valid Windows Image Format (WIM) file.'
            return [ImageType]::WIM
        }

        ### If the file only has a single image, and doesn't have an image name, it might be a VHDX
        if ($Image.Count -eq 1 -and $Image.ImageName -eq '') {
            Write-Verbose -Message 'This image appears to be a valid Virtual Hard Drive (VHDX) file.'
            return [ImageType]::VHDX
        }
        
        return [ImageType]::Unknown
    }
    catch {
        Write-Error -Message ('Error occurred while attempting to inspect the image file. {0}' -f $PSItem.Exception.Message)
        throw $PSItem
    }

}

