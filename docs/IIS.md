# IIS

Image2Docker can inspect web servers and extract a Dockerfile containing some or all of the websites configured on the server. 

ASP.NET is supported, and the generated Dockerfile will be correctly set up to run .NET 2.0, 3.5 or 4.x sites.

## Usage

Use the `IIS` artifact to inspect a web server. To extract all websites from a virtual machine disk image into a Dockerfile, run:

```
ConvertTo-Dockerfile `
 -ImagePath c:\iis.vhd `
 -OutputPath c:\i2d2\iis `
 -Artifact IIS
```

### Selective Extraction

You can limit the extraction using the `ArtifactParam` parameter, which restricts the output to a single wesbite, web application or virtual directory. 

Specify the path to the source content using the following format:

| Format                            | Example                   | Dockerfile contents                                                   |
| --------------------------------- | ------------------------- | --------------------------------------------------------------------- |
| `{website}`                       | 'UpgradeSample'           | Named site with all apps and virtual directories                      |
| `{website}/{vdir}`                | 'UpgradeSample/img'       | Named site with only the named virtual directory                      |
| `{website}/{application}`         | 'UpgradeSample/v1.0'      | Named site with the named application and all its virtual directories |
| `{website}/{application}/{vdir}`  | 'UpgradeSample/v1.0/img'  | Named site with the named application the named virtual directory     |

If you had the following structure in IIS on the source server:

```
IIS 
│
└── Default Web Site <website>
│   │   
│   └── img <vdir>
│   │
│   └── app1 <app>
│       │ 
│       └── img <vdir>
│
└── UpgradeSample <website>
    │
    └── v1.0 <app>
    │   │ 
    │   └── img <vdir>
    │   
    └── v1.1 <app>
    │   
    └── v1.2 <app>
```

You can extract the whole configuration into a Dockerfile if you omit `ArtifactParam`. 

To extract just the `v1.2` web application, run:

```
ConvertTo-Dockerfile `
 -ImagePath c:\iis.vhd `
 -OutputPath c:\i2d2\iis `
 -Artifact IIS `
 -ArtifactParam UpgradeSample/v1.2
```

## Source Types

IIS discovery supports running on VHD and WIM disk images, on the local machine and on a remote machine. 

The machine where you run `ConvertTo-Dockerfile` needs to have PowerShell 5.0 installed. It does not need to have Docker installed - you can generate Dockerfiles on one machine and then build them on another.

### Disk Images

The disk image must be available locally, PowerShell does not support mounting images on a network share. 

Use the `ImagePath` parameter, specifying the location of the disk image:

```
ConvertTo-Dockerfile `
 -ImagePath c:\iis.vhd `
 -OutputPath c:\i2d2\iis `
 -Artifact IIS
```

### Local machine

PowerShell 5.0 is installed by default on Windows Server 2016, but it is available for Windows Server 2008R2 onwards. Install [Windows Management Framework 5.0](https://www.microsoft.com/en-us/download/details.aspx?id=50395) on older systems before installing `Image2Docker`. 

Use the `Local` parameter:

```
ConvertTo-Dockerfile `
 -Local `
 -OutputPath c:\i2d2\iis `
 -Artifact IIS
```

### Remote machine

IIS discovery uses the filesystem almost exclusively, so you can run it against a remote shared drive. The system drive needs to be shared, and the user running `ConvertTo-Dockerfile` needs read permission on the `Windows` directory, and any directories where IIS content is stored.

Use the `RemotePath` parameter:

```
ConvertTo-Dockerfile `
 -RemotePath \\192.168.1.11\c$ `
 -OutputPath c:\i2d2\iis `
 -Artifact IIS
```

Using a remote path means `Image2Docker` can't discover the Windows features installed on the machine, so any optional IIS features installed will not be extracted into the Dockerfile.

## Base Images

IIS discovery will choose the most appropriate base image for the workload it extracts:

* [microsoft/iis:windowsservercore](https://hub.docker.com/r/microsoft/iis/) - for websites which don't use ASP.NET
* [microsoft/aspnet:windowsservercore](https://hub.docker.com/r/microsoft/aspnet/) - for websites which use ASP.NET (2.0 and 4.x)
* [microsoft/aspnet:3.5-windowsservercore](https://hub.docker.com/r/microsoft/aspnet/) - for websites which use ASP.NET 3.5

They are all based on Windows Server Core, which is the Windows 2016 kernel. We pin to the latest version of the base image, so you should check for updates to `Image2Docker` before you run it. 

## Sample Dockerfiles 

From a remote Windows 2008R2 server, extracting a single ASP.NET website:

```
ConvertTo-Dockerfile -RemotePath \\192.168.1.11\c -OutputPath c:\i2d2\2008-remote -Artifact IIS -ArtifactParam iis-env
```

Produces:

```
# escape=`
FROM microsoft/aspnet:windowsservercore-10.0.14393.693
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

RUN Remove-Website 'Default Web Site';

# Set up website: iis-env
RUN New-Item -Path 'C:\iis\iis-env' -Type Directory -Force; 

RUN New-Website -Name 'iis-env' -PhysicalPath 'C:\iis\iis-env' -Port 8090 -Force; 

EXPOSE 8090

COPY ["iis-env", "/iis/iis-env"]
```

From a local VHD containing a Windows 2003R2 server with .NET 3.5, extracting a nested website:

```
ConvertTo-Dockerfile -ImagePath E:\VMs\win2003-iis.vhd -OutputPath c:\i2d2\2003-vhd -Artifact IIS -ArtifactParam UpgradeSample 
```

Produces:

```
# escape=`
FROM microsoft/aspnet:3.5-windowsservercore-10.0.14393.693
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

RUN Remove-Website 'Default Web Site';

# Set up website: UpgradeSample
RUN New-Item -Path 'C:\UpgradeSample' -Type Directory -Force; `
    New-Item -Path 'C:\images' -Type Directory -Force; `
    New-Item -Path 'C:\UpgradeSample\v1.0' -Type Directory -Force; `
    New-Item -Path 'C:\UpgradeSample\v1.1' -Type Directory -Force; `
    New-Item -Path 'C:\UpgradeSample\v1.2' -Type Directory -Force; 

RUN New-Website -Name 'UpgradeSample' -PhysicalPath 'C:\UpgradeSample' -Port 8082 -Force; `
    New-WebVirtualDirectory -Name 'img' -Site 'UpgradeSample' -PhysicalPath 'C:\images'; `
    New-WebApplication -Name 'v1.0' -Site 'UpgradeSample' -PhysicalPath 'C:\UpgradeSample\v1.0' -Force; `
    New-WebApplication -Name 'v1.1' -Site 'UpgradeSample' -PhysicalPath 'C:\UpgradeSample\v1.1' -Force; `
    New-WebApplication -Name 'v1.2' -Site 'UpgradeSample' -PhysicalPath 'C:\UpgradeSample\v1.2' -Force; 

EXPOSE 8082

COPY ["UpgradeSample", "/UpgradeSample"]
COPY ["images", "/images"]
COPY ["v1.0", "/UpgradeSample/v1.0"]
COPY ["v1.1", "/UpgradeSample/v1.1"]
COPY ["v1.2", "/UpgradeSample/v1.2"]
```