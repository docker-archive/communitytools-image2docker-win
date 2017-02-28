function GetDockerfileBuilder {
<#
.SYNOPSIS
Renders the content of the Dockerfile template

.PARAMETER TemplateName
Name of the template file.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess",'')]
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string] $TemplateName
)

    if ($TemplateName -eq $null -Or $TemplateName.Length -eq 0) {
        $TemplateName = 'Dockerfile.template'
    }
    
    $ResultBuilder = New-Object System.Text.StringBuilder
    $Dockerfile = Get-Content -Raw -Path "$ModulePath\Resources\$TemplateName"   

    $null = $ResultBuilder.AppendLine($Dockerfile.Trim())
    $null = $ResultBuilder.AppendLine('')

    RETURN $ResultBuilder
}