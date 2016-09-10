=============
Introduction
=============

This project aims to simplify the creation of Dockerfiles for Microsoft Windows Server Hyper-V Container images.

The Microsoft Windows Server 2016 platform introduces new capabilities for containerizing applications. There are two types of container formats supported on the Microsoft Windows platform:

- **Hyper-V Containers** - Containers with a dedicated kernel and stronger isolation from other containers
- **Windows Containers** - application isolation using process and namespace isolation, and a shared kernel with the container host

=============
Prerequisites
=============

Windows 10 with the Anniversary Update is required on the system that is using this module.

=============
Installation
=============

Installing this PowerShell module from the PowerShell Gallery is very easy. Simply call ``Install-Module -Name Image2Docker``

=============
Artifacts
=============

This project supports discovery of custom artifacts.
Each artifact is represented by a folder in the ``.\Artifacts`` subdirectory, containing two PowerShell script files:

- ``Discover.ps1`` - This script performs discovery of the desired artifact and creates a manifest file 
- ``Generate.ps1`` - This script generates the Dockerfile contents for the artifact. This should be the only output emitted from the command. Any output that is emitted from this command will be appended to the ``Dockerfile``.

You can add your own discovery artifacts to this project, by issuing a pull request. 

=============
Supported Artifacts
=============

This project currently supports discovery of the following artifacts:

- Microsoft Windows Add/Remove Programs (ARP)
- Microsoft Windows Server Active Directory Domain Services (ADDS)
- Microsoft Windows Server Domain Name Server (DNS)
- Microsoft Windows Internet Information Services (IIS)
- Apache Web Server

