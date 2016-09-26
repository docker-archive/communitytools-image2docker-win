FROM microsoft/windowsservercore


RUN powershell.exe -ExecutionPolicy Bypass -Command \ 
    Enable-WindowsOptionalFeature -Online -FeatureName Web-Server, IIS-WebServerManagementTools; \
New-Website -Name "Default Web Site" -PhysicalPath "%SystemDrive%\inetpub\wwwroot" \
New-Website -Name "Mano's Site" -PhysicalPath "C:\inetpub\wwwroot\ManoSite" \

ADD wwwroot %SystemDrive%\inetpub\wwwroot
ADD ManoSite C:\inetpub\wwwroot\ManoSite


