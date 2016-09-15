$ErrorActionPreference = 'Stop'

Remove-Module -Name Image2Docker -ErrorAction Ignore
Import-Module -Name (Split-Path -Path $PSScriptRoot -Parent)

Clear-JunctionLinks

Get-WindowsArtifacts

$ImagePath = 'D:\data\Virtual Machines\Docker\docker-2016tp5\Virtual Hard Disks\docker-2016tp5.vhdx'

Remove-Item -Path C:\ArtofShell\* -Recurse -Force

ConvertTo-Dockerfile -ImagePath $ImagePath -OutputPath c:\ArtofShell\Apache -Artifact Apache -Verbose

ConvertTo-Dockerfile -ImagePath $ImagePath -OutputPath c:\ArtofShell\Apache-DNS -Artifact Apache, DNSServer -Verbose

ConvertTo-Dockerfile -ImagePath $ImagePath -OutputPath c:\ArtofShell\AddRemovePrograms -Artifact AddRemovePrograms -Verbose

ConvertTo-Dockerfile -ImagePath $ImagePath -OutputPath c:\ArtofShell\IIS -Artifact IIS -Verbose

