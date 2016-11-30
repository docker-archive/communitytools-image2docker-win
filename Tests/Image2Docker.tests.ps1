Describe Image2Docker {
    $ModuleName = 'Image2Docker'
    WrIte-Verbose -Message ('Module name is {0}' -f $ModuleName)

    ### Remove the module if It's already imported, then re-import It (in case code changed)
    Remove-Module -Name $ModuleName -ErrorAction Ignore
    #Import-Module -Name (SplIt-Path -Path $PSScriptRoot -Parent)
    Import-Module -Name $PSScriptRoot\..\Image2Docker.psd1

    Context 'Public-facing PowerShell commands' {
        It 'Has a ConvertTo-Dockerfile command' {
            (Get-Command -Module $ModuleName -Name ConvertTo-Dockerfile).Count | Should Be 1
        }

        It 'Has a Get-WindowsArtifacts command' {
            (Get-Command -Module $ModuleName -Name Get-WindowsArtifacts).Count | Should Be 1
        }
    }

    Context 'Private / internal PowerShell commands' {
        InModuleScope -ModuleName $ModuleName -ScriptBlock {
            It 'Has a GenerateDockerfile command' {
                (Get-Command -Module $ModuleName -Name GenerateDockerfile).Count | Should Be 1
            }
            It 'Has a GetImageType command' {
                (Get-Command -Module $ModuleName -Name GetImageType).Count | Should Be 1
            }
        }
    }

    Context 'Artifact Discovery' {
            foreach ($artifact in Get-WindowsArtifacts) {
            
            It "Has an $artifact Artifact" {
                Get-WindowsArtifacts | Where-Object {$_ -match $artifact }| Should Match $artifact
            }
      }
  }
     Context 'Test ConvertTo-Dockerfile command' {
        It 'Should throw when -ImagePath parameter value is invalid' {
            { ConvertTo-Dockerfile -ImagePath c:\invalid\path.wim } | Should throw
        }
    }

    Remove-Module -Name $ModuleName
}
