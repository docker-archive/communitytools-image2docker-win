function Get-WindowsArtifacts {
    <#
    .SYNOPSIS
    Returns a list of supported artifacts for discovery in a Windows image.
    
    .EXAMPLE

    $Artifacts = Get-WindowsArtifacts

    This will return all of the discoverable artifacts and assign the result to the Artifacts Variable
    
    #>
    [CmdletBinding()]
    param (
    )

    $ArtifactList = Get-ChildItem -Path $ModulePath\Functions\Private\Artifacts -Directory
    Write-Verbose -Message ('Searching for artifacts in filesystem path: {0}\Artifacts' -f $ModulePath)
    
    foreach ($Artifact in $ArtifactList) {
        $ChildItems = (Get-ChildItem -Path $Artifact.FullName).Name
        Write-Verbose -Message ('Child items for "{0}" artifact: {1}' -f $Artifact.FullName, ($ChildItems -join ', '))

        if ($ChildItems -contains "Discover_$Artifact.ps1" -and $ChildItems -contains "Generate_$Artifact.ps1") {
            Write-Output -InputObject $Artifact.Name
            Write-Verbose -Message ('Valid artifact found: {0}' -f $Artifact.Name)
        }
    }
}