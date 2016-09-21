Introduction
=============

This project aims to provide a framework to simplify the creation of Dockerfiles for Microsoft Windows Server Hyper-V Container 
images, based upon analysis of existing WIM or VHDX image files.

The Microsoft Windows Server 2016 platform introduces new capabilities for containerizing applications. 
There are two types of container formats supported on the Microsoft Windows platform:

- **Hyper-V Containers** - Containers with a dedicated kernel and stronger isolation from other containers
- **Windows Containers** - application isolation using process and namespace isolation, and a shared kernel with the container host

Prerequisites
=============

Windows 10 with the Anniversary Update is required on the system that is using this module. You may also be able to use Windows Server 2016 to run this module. 

Installation
=============

Installing this PowerShell module from the PowerShell Gallery is very easy. Simply call ``Install-Module -Name Image2Docker``.
If you receive any errors, please validate the presence of the ``PowerShellGet`` module by running this command: ``Get-Command -Name PowerShellGet -ListAvailable``.
You can also validate the presence of the ``Install-Module`` command by running: ``Get-Command -Module PowerShellGet -Name Install-Module``.
If the ``PowerShellGet`` module or the ``Install-Module`` commands are not accessible, you may not be running a supported version of PowerShell. 
Make sure that you are running PowerShell 5.0 or later on a Windows 10 client operating system.

Usage
=============

After installing the ``Image2Docker`` PowerShell module, you will need one or more valid ``.vhdx`` or ``.wim`` files (the "source image").
To perform a scan of a valid VHDX or WIM image file, simply call the ``ConvertTo-Dockerfile`` command and specify the ``-ImagePath`` parameter, passing in the fully-qualified filesystem path to the source image.

::

  ### Perform scan of Windows source image
  ConvertTo-Dockerfile -ImagePath c:\docker\myimage.wim

To improve performance of the image scan, you may also specify the artifacts that will be discovered within the image.
This avoids the performance hit by preventing scanning for artifacts that are intentionally excluded from the scanning process.
To discover a list of supported artifacts, use the ``Get-WindowsArtifacts`` command. This command will emit an array of supported artifacts.
Once you have identified one or more artifacts that you would like to scan for, simply add the ``

Example:  

::

  ### List out supported artifacts
  Get-WindowsArtifacts

  ### Perform scan and Dockerfile generation
  ConvertTo-Dockerfile -ImagePath c:\docker\myimage.vhdx -Artifact IIS, Apache

Artifacts
=============

This project supports discovery of custom artifacts.
Each artifact is represented by a folder in the ``.\Artifacts`` subdirectory, containing two PowerShell script files:

- ``Discover.ps1`` - This script performs discovery of the desired artifact and creates a manifest file. This script *must* accept the following input parameters: ``[string] $MountPath`` and ``[string] $OutputPath``. The script should write an arbitrary JSON "manifest" to the ``$OutputPath``.
- ``Generate.ps1`` - This script generates the Dockerfile contents for the artifact. This should be the only output emitted from the command. Any output that is emitted from this command will be appended to the ``Dockerfile``. This script *must* support the input parameter: ``[string] $ManifestPath``. The script should read a JSON "manifest" to the ``$ManifestPath``.

You can add your own discovery artifacts to this project, by issuing a pull request. If you don't wish to share the artifacts publicly, you can simply place them into the module's ``.\Artifacts`` directory on each system that will perform image scans.

Supported Artifacts
===================

This project currently supports discovery of the following artifacts:

- Microsoft Windows Add/Remove Programs (ARP)
- Microsoft Windows Server Active Directory Domain Services (ADDS)
- Microsoft Windows Server Domain Name Server (DNS)
- Microsoft Windows Internet Information Services (IIS)
  - HTTP Handlers in IIS configuration
  - IIS Websites and filesystem paths
- Microsoft SQL Server instances
- Apache Web Server

Known Issues
=============

1. Dism Error: 0x8000000a 
------------------------------------

You might sometimes receive an error from dism, similar to the following:

  Get-WindowsOptionalFeature : DismOpenSession failed. Error code = 0x8000000a


To work around this problem, specify the artifacts that you wish to discover, using the ``-Artifact`` parameter
on the ``ConvertTo-Dockerfile`` command.
