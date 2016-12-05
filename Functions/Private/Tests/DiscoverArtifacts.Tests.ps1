Describe 'DiscoverArtifacts Tests' {

   Context 'Parameters for DiscoverArtifacts'{

        It 'Has a Parameter called Artifact' {
            $Function.Parameters.Keys.Contains('Artifact') | Should Be 'True'
            }
        It 'Artifact Parameter is Identified as Mandatory being True' {
            [String]$Function.Parameters.Artifact.Attributes.Mandatory | Should be 'True'
            }
        It 'Artifact Parameter is of String[] Type' {
            $Function.Parameters.Artifact.ParameterType.FullName | Should be 'System.String[]'
            }
        It 'Artifact Parameter is member of ParameterSets' {
            [String]$Function.Parameters.Artifact.ParameterSets.Keys | Should Be '__AllParameterSets'
            }
        It 'Artifact Parameter Position is defined correctly' {
            [String]$Function.Parameters.Artifact.Attributes.Position | Should be '0'
            }
        It 'Does Artifact Parameter Accept Pipeline Input?' {
            [String]$Function.Parameters.Artifact.Attributes.ValueFromPipeline | Should be 'False'
            }
        It 'Does Artifact Parameter Accept Pipeline Input by PropertyName?' {
            [String]$Function.Parameters.Artifact.Attributes.ValueFromPipelineByPropertyName | Should be 'False'
            }
        It 'Does Artifact Parameter use advanced parameter Validation? ' {
            $Function.Parameters.Artifact.Attributes.TypeID.Name -contains 'ValidateNotNullOrEmptyAttribute' | Should Be 'False'
            $Function.Parameters.Artifact.Attributes.TypeID.Name -contains 'ValidateNotNullAttribute' | Should Be 'False'
            $Function.Parameters.Artifact.Attributes.TypeID.Name -contains 'ValidateScript' | Should Be 'False'
            $Function.Parameters.Artifact.Attributes.TypeID.Name -contains 'ValidateRangeAttribute' | Should Be 'False'
            $Function.Parameters.Artifact.Attributes.TypeID.Name -contains 'ValidatePatternAttribute' | Should Be 'False'
            }
        It 'Has Parameter Help Text for Artifact '{
            $function.Definition.Contains('.PARAMETER Artifact') | Should Be 'True'
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
        It 'Has a Parameter called ArtifactParam' {
            $Function.Parameters.Keys.Contains('ArtifactParam') | Should Be 'True'
            }
        It 'ArtifactParam Parameter is Identified as Mandatory being False' {
            [String]$Function.Parameters.ArtifactParam.Attributes.Mandatory | Should be 'False'
            }
        It 'ArtifactParam Parameter is of String[] Type' {
            $Function.Parameters.ArtifactParam.ParameterType.FullName | Should be 'System.String[]'
            }
        It 'ArtifactParam Parameter is member of ParameterSets' {
            [String]$Function.Parameters.ArtifactParam.ParameterSets.Keys | Should Be '__AllParameterSets'
            }
        It 'ArtifactParam Parameter Position is defined correctly' {
            [String]$Function.Parameters.ArtifactParam.Attributes.Position | Should be '2'
            }
        It 'Does ArtifactParam Parameter Accept Pipeline Input?' {
            [String]$Function.Parameters.ArtifactParam.Attributes.ValueFromPipeline | Should be 'False'
            }
        It 'Does ArtifactParam Parameter Accept Pipeline Input by PropertyName?' {
            [String]$Function.Parameters.ArtifactParam.Attributes.ValueFromPipelineByPropertyName | Should be 'False'
            }
        It 'Does ArtifactParam Parameter use advanced parameter Validation? ' {
            $Function.Parameters.ArtifactParam.Attributes.TypeID.Name -contains 'ValidateNotNullOrEmptyAttribute' | Should Be 'False'
            $Function.Parameters.ArtifactParam.Attributes.TypeID.Name -contains 'ValidateNotNullAttribute' | Should Be 'False'
            $Function.Parameters.ArtifactParam.Attributes.TypeID.Name -contains 'ValidateScript' | Should Be 'False'
            $Function.Parameters.ArtifactParam.Attributes.TypeID.Name -contains 'ValidateRangeAttribute' | Should Be 'False'
            $Function.Parameters.ArtifactParam.Attributes.TypeID.Name -contains 'ValidatePatternAttribute' | Should Be 'False'
            }
        It 'Has Parameter Help Text for ArtifactParam '{
            $function.Definition.Contains('.PARAMETER ArtifactParam') | Should Be 'True'
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


