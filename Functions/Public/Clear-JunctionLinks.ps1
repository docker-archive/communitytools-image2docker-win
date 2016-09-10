function Clear-JunctionLinks {
    [CmdletBinding()]
    param (
    )

    $ItemList = Get-ChildItem -Path $env:TEMP -Directory | Where-Object -FilterScript { $PSItem.LinkType -eq 'Junction' }

    foreach ($Item in $ItemList) {
        Dismount-WindowsImage -Path $Item.FullName -Discard
        Write-Verbose -Message ('Dismounted Windows image from directory: {0}' -f $Item.FullName)
    }
}