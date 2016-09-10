describe DockerMigrate {
    $ModuleName = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Leaf
    Write-Verbose -Message ('Module name is {0}' -f $ModuleName)

    ### Remove the module if it's already imported, then re-import it (in case code changed)
    Remove-Module -Name DockerMigrate -ErrorAction Ignore
    Import-Module -Name (Split-Path -Path $PSScriptRoot -Parent)

    context 'Public-facing PowerShell commands' {
        it 'Has a Convert-WindowsImage command' {
            (Get-Command -Module DockerMigrate -Name Convert-WindowsImage).Count | Should Be 1
        }

        it 'Has a Get-WindowsArtifacts command' {
            (Get-Command -Module DockerMigrate -Name Get-WindowsArtifacts).Count | Should Be 1
        }
    }

    context 'Private / internal PowerShell commands' {
        InModuleScope -ModuleName DockerMigrate -ScriptBlock {
            it 'Has a GenerateDockerfile command' {
                (Get-Command -Module $ModuleName -Name GenerateDockerfile).Count | Should Be 1
            }
            it 'Has a GetImageType command' {
                (Get-Command -Module $ModuleName -Name GetImageType).Count | Should Be 1
            }
        }
    }

    context 'Test Convert-WindowsImage command' {
        it 'Should throw when -ImagePath parameter value is invalid' {
            { Convert-WindowsImage -ImagePath c:\invalid\path.wim } | Should throw
        }
    }

    Remove-Module -Name DockerMigrate
}
