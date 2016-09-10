$ErrorActionPreference = 'Stop'

Remove-Module -Name DockerMigrate -ErrorAction Ignore
Import-Module -Name (Split-Path -Path $PSScriptRoot -Parent)

Clear-JunctionLinks

Get-WindowsArtifacts

$ImagePath = 'D:\data\Virtual Machines\Docker\docker-2016tp5\Virtual Hard Disks\docker-2016tp5.vhdx'

Remove-Item -Path C:\ArtofShell\* -Recurse -Force

Convert-WindowsImage -ImagePath $ImagePath -OutputPath c:\ArtofShell\Apache -Artifact Apache -Verbose

Convert-WindowsImage -ImagePath $ImagePath -OutputPath c:\ArtofShell\Apache-DNS -Artifact Apache, DNSServer -Verbose

Convert-WindowsImage -ImagePath $ImagePath -OutputPath c:\ArtofShell\AddRemovePrograms -Artifact AddRemovePrograms -Verbose

Convert-WindowsImage -ImagePath $ImagePath -OutputPath c:\ArtofShell\IIS -Artifact IIS -Verbose

