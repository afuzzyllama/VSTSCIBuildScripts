<#
    Script to check that agent is running the most current version of ImageMagick.  
    This script uses environment variables defined by the TFS build process.

    Will install ImageMagick at $env:AGENT_ROOTDIRECTORY\dependencies\ImageMagick
    This script will uninstall any previous versions of ImageMagick installed before installing the next version
#>
[cmdletbinding()]
param()

Add-Type -Assembly System.IO.Compression.FileSystem

$archiveContentFile = "$env:TEMPDIR\content.html"
$dependenciesDir = "$env:DEPENDENCIESDIR\dependencies\ImageMagick"

Write-Host "Checking for latest version of ImageMagick"

if(!(Test-Path -Path $env:TEMPDIR))
{
    New-Item -ItemType directory -Path $env:TEMPDIR | Out-Null
}

# Create the dependencies directory if it does not exist 
if(!(Test-Path -Path $dependenciesDir))
{
    New-Item -ItemType directory -Path $dependenciesDir | Out-Null
}

# Fetch the download page from imagemagick.org
wget -OutFile $archiveContentFile http://www.imagemagick.org/script/binary-releases.php

# Parse out the current version of the ImageMagick
$regex = "http://www.imagemagick.org/download/binaries/ImageMagick-[0-9]+\.[0-9]+\.[0-9]+-[0-9]+-portable-Q16-x86\.zip"
$currentDownloadLink = Select-String -Path $archiveContentFile -Pattern $regex -AllMatches | Select-Object -First 1 | %{$_.Matches} | %{$_.Value}

$regex = "ImageMagick-[0-9]+\.[0-9]+\.[0-9]+-[0-9]+-portable-Q16-x86"
$currentVersion = $currentDownloadLink | Select-String -Pattern $regex -AllMatches  | Select-Object -First 1 | %{$_.Matches} | %{$_.Value}

Remove-Item -Path $archiveContentFile

if(!($currentVersion))
{
    Write-Error -Category InvalidResult -Message "Cannot obtain the most current version of ImageMagick."
}
elseif(!(Test-Path -Path "$dependenciesDir\$currentVersion"))
{
    # If installing a new version, remove the directory link first
    if((Test-Path -Path "$dependenciesDir\latest"))
    {
        cmd /c rmdir /q "$dependenciesDir\latest"
    }

    # Uninstall ImageMagick
    Get-ChildItem -Path $dependenciesDir | ForEach-Object {
        Remove-Item -Recurse -Path "$dependenciesDir\$_"
    }
    
    # Download ImageMagick
    New-Item -ItemType directory -Path "$dependenciesDir\$currentVersion"
    wget -OutFile "$dependenciesDir\$currentVersion\$currentVersion.zip" $currentDownloadLink 

    # Install ImageMagick 
    [System.IO.Compression.ZipFile]::ExtractToDirectory("$dependenciesDir\$currentVersion\$currentVersion.zip", "$dependenciesDir\$currentVersion\ImageMagick")

    # Create a directory link to the latest version for easy referencing later on
    cmd /c mklink /D "$dependenciesDir\latest" "$dependenciesDir\$currentVersion"

    Write-Host "Installed: $currentVersion"
}
else
{
    Write-Host "Current version already installed: $currentVersion"
    
}
