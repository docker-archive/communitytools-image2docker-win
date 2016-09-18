describe Image2Docker {
    $ModuleName = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Leaf
    Write-Verbose -Message ('Module name is {0}' -f $ModuleName)

    ### Remove the module if it's already imported, then re-import it (in case code changed)
    Remove-Module -Name $ModuleName -ErrorAction Ignore
    #Import-Module -Name (Split-Path -Path $PSScriptRoot -Parent)
    Import-Module -Name $PSScriptRoot\..\Image2Docker.psd1

    context 'Public-facing PowerShell commands' {
        it 'Has a ConvertTo-Dockerfile command' {
            (Get-Command -Module $ModuleName -Name ConvertTo-Dockerfile).Count | Should Be 1
        }

        it 'Has a Get-WindowsArtifacts command' {
            (Get-Command -Module $ModuleName -Name Get-WindowsArtifacts).Count | Should Be 1
        }
    }

    context 'Private / internal PowerShell commands' {
        InModuleScope -ModuleName $ModuleName -ScriptBlock {
            it 'Has a GenerateDockerfile command' {
                (Get-Command -Module $ModuleName -Name GenerateDockerfile).Count | Should Be 1
            }
            it 'Has a GetImageType command' {
                (Get-Command -Module $ModuleName -Name GetImageType).Count | Should Be 1
            }
        }
    }

    context 'Test ConvertTo-Dockerfile command' {
        it 'Should throw when -ImagePath parameter value is invalid' {
            { ConvertTo-Dockerfile -ImagePath c:\invalid\path.wim } | Should throw
        }
    }

    Remove-Module -Name $ModuleName
}
