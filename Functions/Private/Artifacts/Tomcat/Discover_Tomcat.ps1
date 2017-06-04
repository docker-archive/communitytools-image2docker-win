function Discover_Tomcat {
<#
.SYNOPSIS
Scans for the Tomcat Web Server 

.PARAMETER MountPath
The path where the Windows image was mounted to.

.PARAMETER OutputPath
The filesystem path where the discovery manifest will be emitted.

.PARAMETER ArtifactParam
Optional - one or more Website names to include in the output.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess",'')]
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $MountPath,

    [Parameter(Mandatory = $true)]
    [string] $OutputPath,

    [Parameter(Mandatory = $true)]
    [string] $ImageWindowsVersion,

    [Parameter(Mandatory = $false)]
    [string[]] $ArtifactParam
)


$ArtifactName = Split-Path -Path $PSScriptRoot -Leaf
Write-Verbose -Message ('Started discovering {0} artifact' -f $ArtifactName)

### Path to the Tomcat manifest
$Manifest = '{0}\{1}.json' -f $OutputPath, $ArtifactName

### Create a HashTable to store the results (this will get persisted to JSON)
$ManifestResult = @{
    Name = 'Tomcat'
    Status = ''
    Path = ''
}

# Check for existence of the JDK framework:
$JDKPath = "$MountPath"
if (Test-Path -Path $JDKPath) {
    $JDKPath = Get-ChildItem -Path $JDKPath -Recurse -Include java.exe -Exclude $MountPath\Windows\*
    if ($JDKPath.Count -ge 1) {
        for ($i=0; $i -lt $JDKPath.Count; $i++) {
            # Write-Verbose -Message ('JavaPath "{0}"' -f $JDKPath[$i].FullName)
            if (! $JDKPath[$i].FullName.Contains("jre")) { 
                $ManifestResult.JDKStatus = 'Present'
                $JDKExecutable = $JDKPath[$i].FullName
                $JDKHome = $JDKPath[$i].DirectoryName;
                if ($JDKHome.EndsWith("\bin")) {
                    $JDKHome = $JDKHome.Remove($JDKHome.Length-4,4);
                }
                break;
            }
        }
        Write-Verbose -Message ('Discovered Java (java.exe) at "{0}"' -f $JDKExecutable)
        $JavaReleaseFile = $JDKHome+"\release" 
        if (Test-Path -Path $JavaReleaseFile) {
            # JAVA_VERSION="1.8.0_131"
            # Write-Verbose -Message ('Reading "{0}" for Version Information' -f $JavaReleaseFile)
            $ManifestResult.JDKVersion = (Get-Content $JavaReleaseFile)[0]
            if ($ManifestResult.JDKVersion.StartsWith("JAVA_VERSION=")) {
                $ManifestResult.JDKVersion = $ManifestResult.JDKVersion.Remove(0,"JAVA_VERSION=".Length+1);
                $ManifestResult.JDKVersion = $ManifestResult.JDKVersion.Remove($ManifestResult.JDKVersion.Length-1,1);
                Write-Verbose -Message ('Determined that JDK is with version "{0}"' -f $ManifestResult.JDKVersion)
            }
        } else {
            Write-Verbose -Message "Unable to determine JDK version, defaulting to 1.8.1_131"
            $ManifestResult.JDKVersion = "1.8.1_131"
        }
    }
}

if (!$ManifestResult.JDKStatus -eq 'Present') {
    Write-Verbose -Message 'JDK is NOT present on the system'
}

$TomcatPath = "$MountPath\*tomcat*\*"
if (Test-Path -Path $TomcatPath) {
    $Tomcat = Get-ChildItem -Path $TomcatPath -Recurse -Include catalina.bat -Exclude $MountPath\Windows\*
}

if ($Tomcat.Count -ge 1) {
    Write-Verbose -Message ('Discovered Tomcat Web Server (catalina.bat) at "{0}"' -f $Tomcat[0].FullName)
    $ManifestResult.Status = 'Present'
    $ManifestResult.Path = $Tomcat[0].FullName

    ### Discover the Port that Catalina is exposed on
    $ServerXMLPath = $ManifestResult.Path;
    if ($ServerXMLPath.EndsWith("\bin\catalina.bat")) {
        $ServerXMLPath = $ServerXMLPath.Remove($ServerXMLPath.Length - "\bin\catalina.bat".Length, "\bin\catalina.bat".Length)
        $ServerXMLPath += "\conf\server.xml";
        $ManifestResult.ServerXMLPath = $ServerXMLPath;
        [xml]$ServerXmlDocument = Get-Content -Path $ServerXMLPath
        $ManifestResult.CatalinaPort = $ServerXmlDocument.SelectSingleNode('/Server/Service[@name="Catalina"]/Connector[@protocol="HTTP/1.1"]').GetAttribute("port")
        Write-Verbose -Message ('Determined that Catalia is port {0} by examining server.xml {1}' -f $ManifestResult.CatalinaPort, $ServerXMLPath)
    }

}
else {
    $ManifestResult.Status = 'Absent'
}

### Write the result to the manifest file
$ManifestResult | ConvertTo-Json | Set-Content -Path $Manifest

Write-Verbose -Message ('Finished discovering {0} artifact' -f $ArtifactName)
}


