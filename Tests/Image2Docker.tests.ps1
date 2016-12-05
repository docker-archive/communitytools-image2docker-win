$ModuleRoot = Split-Path $PSScriptRoot -Parent

$PrivateFunctions = Get-ChildItem "$ModuleRoot\Functions\Private\" -Filter '*.ps1' -Recurse | Where-Object {$_.name -NotMatch "Tests.ps1"}
$PublicFunctions = Get-ChildItem "$ModuleRoot\Functions\Public\" -Filter '*.ps1' -Recurse | Where-Object {$_.name -NotMatch "Tests.ps1"}

$PrivateFunctionsTests = Get-ChildItem "$ModuleRoot\Functions\Private\" -Filter '*Tests.ps1' -Recurse 
$PublicFunctionsTests = Get-ChildItem "$ModuleRoot\Functions\Public\" -Filter '*Tests.ps1' -Recurse 

$Rules = Get-ScriptAnalyzerRule

$module = 'Image2Docker'

Remove-Module $module -ErrorAction Ignore

Import-Module "$ModuleRoot\$module.psd1"

$ModuleData = Get-Module $Module 
$AllFunctions = & $moduleData {Param($modulename) Get-command -CommandType Function -Module $modulename} $module

$PublicFunctionPath = "$ModuleRoot\Functions\Public\"
$PrivateFunctionPath = "$ModuleRoot\Functions\Private\"

if ($PrivateFunctions.count -gt 0) {
    foreach($PrivateFunction in $PrivateFunctions)
    {

    Describe "Testing Private Function  - $($PrivateFunction.BaseName) for Standard Processing" {
    
          It "Is valid Powershell (Has no script errors)" {

                $contents = Get-Content -Path $PrivateFunction.FullName -ErrorAction Stop
                $errors = $null
                $null = [System.Management.Automation.PSParser]::Tokenize($contents, [ref]$errors)
                $errors.Count | Should Be 0
            }
    
              
           } 
      
    }
 }

 
if ($PublicFunctions.count -gt 0) {

    foreach($PublicFunction in $PublicFunctions)
    {

    Describe "Testing Public Function  - $($PublicFunction.BaseName) for Standard Processing" {
       
          It "Is valid Powershell (Has no script errors)" {

                $contents = Get-Content -Path $PublicFunction.FullName -ErrorAction Stop
                $errors = $null
                $null = [System.Management.Automation.PSParser]::Tokenize($contents, [ref]$errors)
                $errors.Count | Should Be 0
            }
                  
            }
            
            $function = $AllFunctions.Where{ $_.Name -eq $PublicFunction.BaseName}
            $publicfunctionTests = $Publicfunctionstests.Where{$_.Name -match $PublicFunction.BaseName }

            foreach ($publicfunctionTest in $publicfunctionTests) {
                . $($PublicFunctionTest.FullName) $function
                }
       }
    }



Describe 'ScriptAnalyzer Rule Testing' {
        
        Context 'All Public Functions' {

            It 'Passes the Script Analyzer ' {
                (Invoke-ScriptAnalyzer -Path $PublicFunctionPath -Recurse ).Count | Should Be 0

                }
        }
         
         
}

Describe 'Current Tests' {

    Context 'Public-facing PowerShell commands' {
        It 'Has a ConvertTo-Dockerfile command' {
            (Get-Command -Module $Module -Name ConvertTo-Dockerfile).Count | Should Be 1
        }

        It 'Has a Get-WindowsArtifact command' {
            (Get-Command -Module $Module -Name Get-WindowsArtifact).Count | Should Be 1
        }
    }

    Context 'Private / internal PowerShell commands' {
        InModuleScope -ModuleName $Module -ScriptBlock {
            It 'Has a GenerateDockerfile command' {
                (Get-Command -Module $Module -Name GenerateDockerfile).Count | Should Be 1
            }
            It 'Has a GetImageType command' {
                (Get-Command -Module $Module -Name GetImageType).Count | Should Be 1
            }
        }
    }

    Context 'Artifact Discovery' {
            foreach ($artifact in Get-WindowsArtifact) {
            
            It "Has an $artifact Artifact" {
                Get-WindowsArtifact | Where-Object {$_ -match $artifact }| Should Match $artifact
            }
      }
  }
     Context 'Test ConvertTo-Dockerfile command' {
        It 'Should throw when -ImagePath parameter value is invalid' {
            { ConvertTo-Dockerfile -ImagePath c:\invalid\path.wim } | Should throw
        }
    }

}

Remove-Module $module