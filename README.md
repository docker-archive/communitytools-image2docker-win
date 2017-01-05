# Image2Docker

`Image2Docker` is a PowerShell module which ports existing Windows application workloads from virtual machines to Docker images. It supports multiple application types, but the initial focus is on IIS. You can use `Image2Docker` to extract [ASP.NET websites from a VM](https://blog.docker.com/2016/12/convert-asp-net-web-servers-docker-image2docker/), so you can run them in a Docker container with no application changes.

## Introduction

This project aims to provide a framework to simplify the creation of Dockerfiles for Windows Docker
images, based upon analysis of existing WIM or VHDX image files.

Microsoft Windows 10 and Windows Server 2016 introduce new capabilities for containerizing applications. 
There are two types of container formats supported on the Microsoft Windows platform:

- **Hyper-V Containers** - Containers with a dedicated kernel and stronger isolation from other containers
- **Windows Server Containers** - application isolation using process and namespace isolation, and a shared kernel with the container host

## Prerequisites

Windows Server 2016, or Windows 10 with the Anniversary Update is required to use `Image2Docker`. 

`Image2Docker` generates a [Dockerfile](https://docs.docker.com/engine/reference/builder/) which you can build into a Docker image. The system running the `ConvertTo-Dockerfile` command does not need Docker installed, but you will need [Docker setup on Windows](https://github.com/docker/labs/blob/master/windows/windows-containers/Setup.md) to build images and run containers.

## Installation

Installing this PowerShell module from the PowerShell Gallery is very easy. Simply invoke ``Install-Module -Name Image2Docker`` in an administrative prompt.
If you receive any errors, please validate the presence of the ``PowerShellGet`` module by running this command: ``Get-Command -Name PowerShellGet -ListAvailable``.
You can also validate the presence of the ``Install-Module`` command by running: ``Get-Command -Module PowerShellGet -Name Install-Module``.
If the ``PowerShellGet`` module or the ``Install-Module`` commands are not accessible, you may not be running a supported version of PowerShell. 
Make sure that you are running PowerShell 5.0 or later on a Windows 10 client operating system.

## Usage

After installing the ``Image2Docker`` PowerShell module, you will need one or more valid ``.vhdx`` or ``.wim`` files (the "source image").
To perform a scan of a valid VHDX or WIM image file, simply call the ``ConvertTo-Dockerfile`` command and specify the ``-ImagePath`` parameter, passing in the fully-qualified filesystem path to the source image.

```PowerShell
  # Perform scan of Windows source image
  ConvertTo-Dockerfile -ImagePath c:\docker\myimage.wim
```

To improve performance of the image scan, you may also specify the artifacts that will be discovered within the image.
This avoids the performance hit by preventing scanning for artifacts that are intentionally excluded from the scanning process.
To discover a list of supported artifacts, use the ``Get-WindowsArtifact`` command. This command will emit an array of supported artifacts.
Once you have identified one or more artifacts that you would like to scan for, simply add the ``Artifact`` parameter.

Example:  

```PowerShell
  # List out supported artifacts
  Get-WindowsArtifact

  # Perform scan and Dockerfile generation
  ConvertTo-Dockerfile -ImagePath c:\docker\myimage.vhdx -Artifact IIS, Apache

  # Extract a single wesbite from an IIS virtual machine
  ConvertTo-Dockerfile -ImagePath c:\vms\iis.vhd -Artifact IIS -ArtifactParam aspnet-webapi
```

To generate Dockerfile from a VHD, build a Docker image and run a container:

```PowerShell
  ConvertTo-Dockerfile -ImagePath c:\vms\iis.vhd -Artifact IIS -ArtifactParam aspnet-webapi -OutputPath c:\i2d2
  cd c:\i2d2
  docker build -t aspnet-webapi .
  docker run -d -p 80:80 aspnet-webapi
```

## Artifacts

This project supports discovery of custom artifacts.
Each artifact is represented by a folder that is contained within the ``.\Functions\Private\Artifacts`` subdirectory, containing at least two PowerShell script files that contain :

- ``Discover_<artifact>.ps1`` - This script should contain a function by the same name as the filename which will perform the discovery of the desired artifact and create a resulting manifest file. The function *must* accept the following input parameters: ``[string] $MountPath`` and ``[string] $OutputPath``. The script should write an arbitrary JSON "manifest" to the ``$OutputPath``.
- ``Generate_<artifact>.ps1`` - This script should contain a function by the same name as the filename which will generate the Dockerfile contents for the artifact. This should be the only output emitted from the command. Any output that is emitted from this command will be appended to the ``Dockerfile``. This function *must* support the input parameter: ``[string] $ManifestPath``. The script should read a JSON "manifest" contained within the ``$ManifestPath``.

It is also recommended that you also include within the Artifact directory a test script that validates the output from both the Discover and Generate functions for the artifact.

You can also include any files within the Artifact directory that may be used to aid in discovering, generating or validating the output for the Artifact.

You can add your own discovery artifacts to this project, by issuing a pull request. If you don't wish to share the artifacts publicly, you can simply place them into the module's ``.\Functions\Private\Artifacts`` directory on each system that will perform image scans.

## Supported Artifacts

This project currently supports discovery of the following artifacts:

- Microsoft Windows Server Roles and Features
- Microsoft Windows Add/Remove Programs (ARP)
- Microsoft Windows Server Domain Name Server (DNS)
- Microsoft Windows Internet Information Services (IIS)
  - HTTP Handlers in IIS configuration
  - IIS Websites and filesystem paths
  - ASP.NET web applications
- Microsoft SQL Server instances
- Apache Web Server


### Known Issues

1. Dism Error: 0x8000000a 
------------------------------------

You might sometimes receive an error from dism, similar to the following:

  Get-WindowsOptionalFeature : DismOpenSession failed. Error code = 0x8000000a


To work around this problem, specify the artifacts that you wish to discover, using the ``-Artifact`` parameter
on the ``ConvertTo-Dockerfile`` command.
