Describe 'Generate_AddRemovePrograms Tests' {

   Context 'Parameters for Generate_AddRemovePrograms'{

        It 'Has a Parameter called ManifestPath' {
            $Function.Parameters.Keys.Contains('ManifestPath') | Should Be 'True'
            }
        It 'ManifestPath Parameter is Identified as Mandatory being True' {
            [String]$Function.Parameters.ManifestPath.Attributes.Mandatory | Should be 'True'
            }
        It 'ManifestPath Parameter is of String Type' {
            $Function.Parameters.ManifestPath.ParameterType.FullName | Should be 'System.String'
            }
        It 'ManifestPath Parameter is member of ParameterSets' {
            [String]$Function.Parameters.ManifestPath.ParameterSets.Keys | Should Be '__AllParameterSets'
            }
        It 'ManifestPath Parameter Position is defined correctly' {
            [String]$Function.Parameters.ManifestPath.Attributes.Position | Should be '0'
            }
        It 'Does ManifestPath Parameter Accept Pipeline Input?' {
            [String]$Function.Parameters.ManifestPath.Attributes.ValueFromPipeline | Should be 'False'
            }
        It 'Does ManifestPath Parameter Accept Pipeline Input by PropertyName?' {
            [String]$Function.Parameters.ManifestPath.Attributes.ValueFromPipelineByPropertyName | Should be 'False'
            }
        It 'Does ManifestPath Parameter use advanced parameter Validation? ' {
            $Function.Parameters.ManifestPath.Attributes.TypeID.Name -contains 'ValidateNotNullOrEmptyAttribute' | Should Be 'False'
            $Function.Parameters.ManifestPath.Attributes.TypeID.Name -contains 'ValidateNotNullAttribute' | Should Be 'False'
            $Function.Parameters.ManifestPath.Attributes.TypeID.Name -contains 'ValidateScript' | Should Be 'False'
            $Function.Parameters.ManifestPath.Attributes.TypeID.Name -contains 'ValidateRangeAttribute' | Should Be 'False'
            $Function.Parameters.ManifestPath.Attributes.TypeID.Name -contains 'ValidatePatternAttribute' | Should Be 'False'
            }
        It 'Has Parameter Help Text for ManifestPath '{
            $function.Definition.Contains('.PARAMETER ManifestPath') | Should Be 'True'
            }
    }
    Context "Function $($function.Name) - Help Section" {

            It "Function $($function.Name) Has show-help comment block" {

                $function.Definition.Contains('<#') | should be 'True'
                $function.Definition.Contains('#>') | should be 'True'
            }

            It "Function $($function.Name) Has show-help comment block has a.SYNOPSIS" {

                $function.Definition.Contains('.SYNOPSIS') -or $function.Definition.Contains('.Synopsis') | should be 'True'

            }

            It "Function $($function.Name) Is an advanced function" {

                $function.CmdletBinding | should be 'True'
                $function.Definition.Contains('param') -or  $function.Definition.Contains('Param') | should be 'True'
            }
    
    }

 }


