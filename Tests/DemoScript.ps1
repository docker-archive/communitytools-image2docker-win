$ErrorActionPreference = 'Stop'

Remove-Module -Name Image2Docker -ErrorAction Ignore
#Import-Module -Name (Split-Path -Path $PSScriptRoot -Parent)
Import-Module -Name $PSScriptRoot\..\Image2Docker.psd1

Clear-JunctionLink

Get-WindowsArtifact

#$ImagePath = 'D:\data\Virtual Machines\Docker\docker-2016tp5\Virtual Hard Disks\docker-2016tp5.vhdx'
#$ImagePath = "D:\vhds\WindowsServer2016-TP5.2016-08-24.vhdx"
$ImagePath = "D:\data\Virtual Machines\Adaptiva\dc01\Virtual Hard Disks\dc01.vhdx"

Remove-Item -Path C:\ArtofShell\* -Recurse -Force -ErrorAction Ignore

#ConvertTo-Dockerfile -ImagePath $ImagePath -OutputPath c:\ArtofShell\Apache -Artifact Apache -Verbose

#ConvertTo-Dockerfile -ImagePath $ImagePath -OutputPath c:\ArtofShell\Apache-DNS -Artifact Apache, DNSServer -Verbose

#ConvertTo-Dockerfile -ImagePath $ImagePath -OutputPath c:\ArtofShell\AddRemovePrograms -Artifact AddRemovePrograms -Verbose

#ConvertTo-Dockerfile -ImagePath $ImagePath -OutputPath c:\ArtofShell\IIS -Artifact IIS -Verbose

#ConvertTo-Dockerfile -ImagePath $ImagePath -OutputPath c:\ArtofShell\DHCPServer -MountPath c:\mounttemp -Artifact DHCPServer -Verbose

ConvertTo-Dockerfile -ImagePath $ImagePath -OutputPath c:\ArtofShell\DHCPServer-DNSServer-IIS -MountPath c:\mounttemp -Artifact DHCPServer, DNSServer, IIS -Verbose

#ConvertTo-Dockerfile -ImagePath $ImagePath -OutputPath c:\ArtofShell\AllArtifacts -MountPath c:\mounttemp -Verbose