FROM microsoft/windowsservercore


RUN powershell.exe -ExecutionPolicy Bypass -Command \ 
    Enable-WindowsOptionalFeature -Online -FeatureName Web-Server, IIS-WebServerManagementTools; \
New-Website -Name "Default Web Site" -PhysicalPath "%SystemDrive%\inetpub\wwwroot" \
New-WebHandler -Name "TRACEVerbHandler" -Path "*" -Verb "TRACE" \
New-WebHandler -Name "OPTIONSVerbHandler" -Path "*" -Verb "OPTIONS" \
New-WebHandler -Name "StaticFile" -Path "*" -Verb "*" \


