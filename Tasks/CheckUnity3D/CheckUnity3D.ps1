<#
    Script to check that agent is running the most current version of Unity3D.  
    This script uses environment variables defined by the TFS build process.

    Will install the Unity3D with Windows build support at $env:DEPENDENCIESDIR\Unity
    This script will uninstall any previous versions of Unity3D installed before installing the next version
#>
[cmdletbinding()]
param()

$archiveContentFile = "$env:TEMPDIR\content.html"
$dependenciesDir = "$env:DEPENDENCIESDIR\Unity"

Write-Host "Checking for latest version of Unity3D"

if(!(Test-Path -Path $env:TEMPDIR))
{
    New-Item -ItemType directory -Path $env:TEMPDIR | Out-Null
}

# Create the dependencies directory if it does not exist 
if(!(Test-Path -Path $dependenciesDir))
{
    New-Item -ItemType directory -Path $dependenciesDir | Out-Null
}

# Fetch the download archieve page from unity3d.com
wget -OutFile $archiveContentFile https://unity3d.com/get-unity/download/archive

# Parse out the current version of the Unity3D editor
$regex = "http://netstorage.unity3d.com/unity/[a-z0-9]+/Windows32EditorInstaller/UnitySetup32-[0-9]+\.[0-9]+\.[0-9]+f[0-9]+\.exe"
$currentDownloadLink = Select-String -Path $archiveContentFile -Pattern $regex -AllMatches | Select-Object -First 1 | %{$_.Matches} | %{$_.Value}

$regex = "http://netstorage.unity3d.com/unity/[a-z0-9]+"
$currentRevision = $currentDownloadLink | Select-String -Pattern $regex -AllMatches | Select-Object -First 1 | %{$_.Matches} | %{$_.Value}

$lastSlashPos = $currentRevision.LastIndexOf("/");
$currentRevision = $currentRevision.Substring($lastSlashPos + 1)

$regex = "UnitySetup32-[0-9]+\.[0-9]+\.[0-9]+f[0-9]+"
$currentVersion = $currentDownloadLink | Select-String -Pattern $regex -AllMatches  | Select-Object -First 1 | %{$_.Matches} | %{$_.Value}

$regex = "[0-9]+\.[0-9]+\.[0-9]+f[0-9]+"
$currentVersionNumber = $currentVersion | Select-String -Pattern $regex -AllMatches  | Select-Object -First 1 | %{$_.Matches} | %{$_.Value}

Remove-Item -Path $archiveContentFile

if(!($currentVersion))
{
    Write-Error -Category InvalidResult -Message "Cannot obtain the most current version of Unity3D."
}
elseif(!(Test-Path -Path "$dependenciesDir\$currentVersion"))
{
    # If installing a new version, remove the directory link first
    if((Test-Path -Path "$dependenciesDir\latest"))
    {
        cmd /c rmdir /q "$dependenciesDir\latest"
    }

    # Uninstall Unity3D
    Get-ChildItem -Path $dependenciesDir | ForEach-Object {
        Start-Process -Wait -FilePath "$dependenciesDir\$_\Unity\Editor\Uninstall.exe" -ArgumentList "/S _?=$dependenciesDir\$_\Unity\Editor\"
        Remove-Item -Recurse -Path "$dependenciesDir\$_"
    }
    
    # Download Unity3D editor and Windows build support
    New-Item -ItemType directory -Path "$dependenciesDir\$currentVersion"
    wget -OutFile "$dependenciesDir\$currentVersion\$currentVersion.exe" $currentDownloadLink 
    wget -OutFile "$dependenciesDir\$currentVersion\UnitySetup-Windows-Support-for-Editor-$currentVersionNumber.exe" "http://netstorage.unity3d.com/unity/$currentRevision/TargetSupportInstaller/UnitySetup-Windows-Support-for-Editor-$currentVersionNumber.exe"

    # Install Unity3D editor and Windows build support
    Start-Process -Wait -FilePath "$dependenciesDir\$currentVersion\$currentVersion.exe" -ArgumentList "/S /D=$dependenciesDir\$currentVersion\Unity"
    Start-Process -Wait -FilePath "$dependenciesDir\$currentVersion\UnitySetup-Windows-Support-for-Editor-$currentVersionNumber.exe" -ArgumentList "/S /D=$dependenciesDir\$currentVersion\Unity"

    # Create a directory link to the latest version for easy referencing later on
    cmd /c mklink /D "$dependenciesDir\latest" "$dependenciesDir\$currentVersion"

    Write-Host "Installed: $currentVersion"
}
else
{
    Write-Host "Current version already installed: $currentVersion"
}
