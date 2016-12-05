Describe 'MountImage Tests' {

   Context 'Parameters for MountImage'{

        It 'Has a Parameter called ImagePath' {
            $Function.Parameters.Keys.Contains('ImagePath') | Should Be 'True'
            }
        It 'ImagePath Parameter is Identified as Mandatory being True' {
            [String]$Function.Parameters.ImagePath.Attributes.Mandatory | Should be 'True'
            }
        It 'ImagePath Parameter is of String Type' {
            $Function.Parameters.ImagePath.ParameterType.FullName | Should be 'System.String'
            }
        It 'ImagePath Parameter is member of ParameterSets' {
            [String]$Function.Parameters.ImagePath.ParameterSets.Keys | Should Be '__AllParameterSets'
            }
        It 'ImagePath Parameter Position is defined correctly' {
            [String]$Function.Parameters.ImagePath.Attributes.Position | Should be '0'
            }
        It 'Does ImagePath Parameter Accept Pipeline Input?' {
            [String]$Function.Parameters.ImagePath.Attributes.ValueFromPipeline | Should be 'False'
            }
        It 'Does ImagePath Parameter Accept Pipeline Input by PropertyName?' {
            [String]$Function.Parameters.ImagePath.Attributes.ValueFromPipelineByPropertyName | Should be 'False'
            }
        It 'Does ImagePath Parameter use advanced parameter Validation? ' {
            $Function.Parameters.ImagePath.Attributes.TypeID.Name -contains 'ValidateNotNullOrEmptyAttribute' | Should Be 'False'
            $Function.Parameters.ImagePath.Attributes.TypeID.Name -contains 'ValidateNotNullAttribute' | Should Be 'False'
            $Function.Parameters.ImagePath.Attributes.TypeID.Name -contains 'ValidateScript' | Should Be 'False'
            $Function.Parameters.ImagePath.Attributes.TypeID.Name -contains 'ValidateRangeAttribute' | Should Be 'False'
            $Function.Parameters.ImagePath.Attributes.TypeID.Name -contains 'ValidatePatternAttribute' | Should Be 'False'
            }
        It 'Has Parameter Help Text for ImagePath '{
            $function.Definition.Contains('.PARAMETER ImagePath') | Should Be 'True'
            }
        It 'Has a Parameter called MountPath' {
            $Function.Parameters.Keys.Contains('MountPath') | Should Be 'True'
            }
        It 'MountPath Parameter is Identified as Mandatory being False' {
            [String]$Function.Parameters.MountPath.Attributes.Mandatory | Should be 'False'
            }
        It 'MountPath Parameter is of String Type' {
            $Function.Parameters.MountPath.ParameterType.FullName | Should be 'System.String'
            }
        It 'MountPath Parameter is member of ParameterSets' {
            [String]$Function.Parameters.MountPath.ParameterSets.Keys | Should Be '__AllParameterSets'
            }
        It 'MountPath Parameter Position is defined correctly' {
            [String]$Function.Parameters.MountPath.Attributes.Position | Should be '1'
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


