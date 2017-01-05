function GenerateOutputFolder {

    <#
    .SYNOPSIS
    Generates an output folder for the Dockerfile and artifacts.
    
    .PARAMETER Path
    The path where all artifacts and the Dockerfile will be output to

    .PARAMETER Force
    Useful when you want to re-use a directory when testing functionality.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess",'')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string] $Path,

        [Parameter(Mandatory = $false)]
        [Switch] $Force

    )

    ### If the user didn't declare a path, then create one for them
    if (!$PSBoundParameters.Keys.Contains('Path')) {
        $Path = '{0}\{1}' -f $env:TEMP, (New-Guid).Guid
        Write-Verbose -Message ('User did not specify output path for discovery artifacts. Using auto-generated directory: {0}' -f $Path)
    }


    if ($PSBoundParameters.Keys.Contains('Force')) {
        if (Test-Path -Path $Path) {
            Write-Verbose -Message "User specified the Force Parameter. Removing existing items from $Path"
            Remove-Item -Path $Path -Recurse -Force
        }
        
        $null = New-Item -Path $Path -ItemType Directory
        Write-Verbose -Message "User specified path $Path has been created"

        return $Path 
    }
    elseif ((Test-Path -Path $Path) -and (Get-ChildItem -Path $Path)) {
        throw 'The directory specified by the -OutputPath parameter must be empty'
    }
    else {
        ### Create the directory if it doesn't exist
        try {
            (mkdir -Path $Path -ErrorAction Stop).FullName
        }
        catch {
            return $Path
        }
    }

}

