
function Completion_Artifact  {
 
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    
    Function Get-Artifacts {
     $artifacts = Get-ChildItem -Path $modulepath\Functions\Private\Artifacts -Directory | Select-Object -ExpandProperty BaseName 
     $artifacts
    }
        
      ### Create fresh completion results for Artifacts
        Get-Artifacts | Where-Object { $PSItem -match $wordToComplete } | ForEach-Object {
            $CompletionText = $PSItem;
            $ToolTip = $PSItem;
            $ListItemText = $PSItem;
            $CompletionResultType = [System.Management.Automation.CompletionResultType]::ParameterValue;

            New-Object -TypeName System.Management.Automation.CompletionResult -ArgumentList @($CompletionText, $ListItemText, $CompletionResultType, $ToolTip);
        }
   
}

Microsoft.PowerShell.Core\Register-ArgumentCompleter -CommandName ConvertTo-DockerFile -ParameterName Artifact -ScriptBlock $Function:Completion_Artifact

