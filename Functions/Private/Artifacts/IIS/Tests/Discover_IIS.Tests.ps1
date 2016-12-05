Describe 'Discover_IIS Tests' {

   Context 'Parameters for Discover_IIS'{

        It 'Has a Parameter called MountPath' {
            $Function.Parameters.Keys.Contains('MountPath') | Should Be 'True'
            }
        It 'MountPath Parameter is Identified as Mandatory being True' {
            [String]$Function.Parameters.MountPath.Attributes.Mandatory | Should be 'True'
            }
        It 'MountPath Parameter is of String Type' {
            $Function.Parameters.MountPath.ParameterType.FullName | Should be 'System.String'
            }
        It 'MountPath Parameter is member of ParameterSets' {
            [String]$Function.Parameters.MountPath.ParameterSets.Keys | Should Be '__AllParameterSets'
            }
        It 'MountPath Parameter Position is defined correctly' {
            [String]$Function.Parameters.MountPath.Attributes.Position | Should be '0'
            }
        It 'Does MountPath Parameter Accept Pipeline Input?' {
            [String]$Function.Parameters.MountPath.Attributes.ValueFromPipeline | Should be 'False'
            }
        It 'Does MountPath Parameter Accept Pipeline Input by PropertyName?' {
            [String]$Function.Parameters.MountPath.Attributes.ValueFromPipelineByPropertyName | Should be 'False'
            }
        It 'Does MountPath Parameter use advanced parameter Validation? ' {
            $Function.Parameters.MountPath.Attributes.TypeID.Name -contains 'ValidateNotNullOrEmptyAttribute' | Should Be 'False'
            $Function.Parameters.MountPath.Attributes.TypeID.Name -contains 'ValidateNotNullAttribute' | Should Be 'False'
            $Function.Parameters.MountPath.Attributes.TypeID.Name -contains 'ValidateScript' | Should Be 'False'
            $Function.Parameters.MountPath.Attributes.TypeID.Name -contains 'ValidateRangeAttribute' | Should Be 'False'
            $Function.Parameters.MountPath.Attributes.TypeID.Name -contains 'ValidatePatternAttribute' | Should Be 'False'
            }
        It 'Has Parameter Help Text for MountPath '{
            $function.Definition.Contains('.PARAMETER MountPath') | Should Be 'True'
            }
        It 'Has a Parameter called OutputPath' {
            $Function.Parameters.Keys.Contains('OutputPath') | Should Be 'True'
            }
        It 'OutputPath Parameter is Identified as Mandatory being True' {
            [String]$Function.Parameters.OutputPath.Attributes.Mandatory | Should be 'True'
            }
        It 'OutputPath Parameter is of String Type' {
            $Function.Parameters.OutputPath.ParameterType.FullName | Should be 'System.String'
            }
        It 'OutputPath Parameter is member of ParameterSets' {
            [String]$Function.Parameters.OutputPath.ParameterSets.Keys | Should Be '__AllParameterSets'
            }
        It 'OutputPath Parameter Position is defined correctly' {
            [String]$Function.Parameters.OutputPath.Attributes.Position | Should be '1'
            }
        It 'Does OutputPath Parameter Accept Pipeline Input?' {
            [String]$Function.Parameters.OutputPath.Attributes.ValueFromPipeline | Should be 'False'
            }
        It 'Does OutputPath Parameter Accept Pipeline Input by PropertyName?' {
            [String]$Function.Parameters.OutputPath.Attributes.ValueFromPipelineByPropertyName | Should be 'False'
            }
        It 'Does OutputPath Parameter use advanced parameter Validation? ' {
            $Function.Parameters.OutputPath.Attributes.TypeID.Name -contains 'ValidateNotNullOrEmptyAttribute' | Should Be 'False'
            $Function.Parameters.OutputPath.Attributes.TypeID.Name -contains 'ValidateNotNullAttribute' | Should Be 'False'
            $Function.Parameters.OutputPath.Attributes.TypeID.Name -contains 'ValidateScript' | Should Be 'False'
            $Function.Parameters.OutputPath.Attributes.TypeID.Name -contains 'ValidateRangeAttribute' | Should Be 'False'
            $Function.Parameters.OutputPath.Attributes.TypeID.Name -contains 'ValidatePatternAttribute' | Should Be 'False'
            }
        It 'Has Parameter Help Text for OutputPath '{
            $function.Definition.Contains('.PARAMETER OutputPath') | Should Be 'True'
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


