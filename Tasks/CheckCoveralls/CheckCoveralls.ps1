[cmdletbinding()]
param()

Add-Type -Assembly System.IO.Compression.FileSystem

$dependenciesDir = "$env:DEPENDENCIESDIR\Coveralls.NET"

# Create the dependencies directory if it does not exist 
if(!(Test-Path -Path $dependenciesDir))
{
    New-Item -ItemType directory -Path $dependenciesDir | Out-Null
}

$currentVersion = "0.7.0-beta.1"
$currentDownloadLink = "https://github.com/csMACnz/coveralls.net/releases/download/0.7.0-beta.1/coveralls.net.0.7.0-beta0001.nupkg"

if(!(Test-Path -Path "$dependenciesDir\$currentVersion"))
{
    # If installing a new version, remove the directory link first
    if((Test-Path -Path "$dependenciesDir\latest"))
    {
        cmd /c rmdir /q "$dependenciesDir\latest"
    }

    # Uninstall Coveralls.NET
    Get-ChildItem -Path $dependenciesDir | ForEach-Object {
        Remove-Item -Recurse -Path "$dependenciesDir\$_"
    }
    
    # Download 
    New-Item -ItemType directory -Path "$dependenciesDir\$currentVersion"
    wget -OutFile "$dependenciesDir\$currentVersion\Coveralls.NET.$currentVersion.nupkg" $currentDownloadLink 

    # Install
    [System.IO.Compression.ZipFile]::ExtractToDirectory("$dependenciesDir\$currentVersion\Coveralls.NET.$currentVersion.nupkg", "$dependenciesDir\$currentVersion\Coveralls.NET")

    # Create a directory link to the latest version for easy referencing later on
    cmd /c mklink /D "$dependenciesDir\latest" "$dependenciesDir\$currentVersion"

    Write-Host "Installed: $currentVersion"
}
else
{
    Write-Host "Current version already installed: $currentVersion"
}
