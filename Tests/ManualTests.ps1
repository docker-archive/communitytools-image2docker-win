### ES
### These are manual tests using curated VMs. 
### We could plausibly use Packer to build test VMs for 2012 upwards, using trial licences, but it would be a lengthy process.
### And we couldn't do it for 2003 and 2008.
### Hence the manual tests.

$ErrorActionPreference = 'Stop'

$InputPath = 'E:\VMs\'
if ((Test-Path -Path $InputPath) -eq $false){
    Write-Verbose 'Input folder not found. Quitting.'
    return
}

Remove-Module -Name Image2Docker -Force -ErrorAction Ignore
Import-Module -Name $PSScriptRoot\..\Image2Docker.psd1

# setup output folder:
$OutputPath = 'c:\i2d2\_manual'
if (Test-Path -Path $OutputPath) {
    Remove-Item -Path $OutputPath -Recurse -Force
}
$null = New-Item -Path $OutputPath -ItemType Directory

# test IIS VMs:
$ImageFiles = @('win2003-iis.vhd', 'win2008-iis.vhdx', 'win2012-iis.vhdx', 'win2016-iis.vhd')
foreach ($File in $ImageFiles) {
    $os = $File.Split('-')[0]
    docker kill "$os-manual"
    docker rm "$os-manual"
    docker rmi -f "i2d2/$os-manual"
    ConvertTo-Dockerfile -ImagePath "$InputPath\$File" -OutputPath "$OutputPath\$os" -Artifact IIS -Verbose -Force
    cd "$OutputPath\$os"
    docker build -t "i2d2/$os-manual" .
    docker run -d --publish-all --name "$os-manual" "i2d2/$os-manual"
}

Write-Verbose 'Everything seems OK.'