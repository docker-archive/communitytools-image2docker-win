function GenerateOutputFolder {
    <#
    .SYNOPSIS
    Generates an output folder for the Dockerfile and artifacts.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string] $Path
    )

    ### If the user didn't declare a path, then create one for them
    if (!$PSBoundParameters.Keys.Contains('Path')) {
        $Path = '{0}\{1}' -f $env:TEMP, (New-Guid).Guid
        Write-Verbose -Message ('User did not specify output path for discovery artifacts. Using auto-generated directory: {0}' -f $Path)
    }


    if ((Test-Path -Path $Path) -and (Get-ChildItem -Path $Path)) {
        throw 'The directory specified by the -OutputPath parameter must be empty'
    }

    ### Create the directory if it doesn't exist
    try {
        (mkdir -Path $Path -ErrorAction Stop).FullName
    }
    catch {
        return $Path
    }
}