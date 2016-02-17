. C:\agent\buildScripts\profile.ps1 

$archiveContent = "C:\agent\content"
$dependenciesDir = "C:\agent\dependencies\Unity"

Write-Host "Checking for latest version of Unity3D"

if(!(Test-Path -Path $dependenciesDir))
{
    New-Item -ItemType directory -Path $dependenciesDir | Out-Null
}

wget -OutFile $archiveContent https://unity3d.com/get-unity/download/archive

$regex = "http://netstorage.unity3d.com/unity/[a-z0-9]+/Windows32EditorInstaller/UnitySetup32-[0-9]+\.[0-9]+\.[0-9]+f[0-9]+\.exe"
$currentDownloadLink = Select-String -Path $archiveContent -Pattern $regex -AllMatches | Select-Object -First 1 | %{$_.Matches} | %{$_.Value}

$regex = "http://netstorage.unity3d.com/unity/[a-z0-9]+"
$currentRevision = $currentDownloadLink | Select-String -Pattern $regex -AllMatches | Select-Object -First 1 | %{$_.Matches} | %{$_.Value}

$lastSlashPos = $currentRevision.LastIndexOf("/");
$currentRevision = $currentRevision.Substring($lastSlashPos + 1)

$regex = "UnitySetup32-[0-9]+\.[0-9]+\.[0-9]+f[0-9]+"
$currentVersion = $currentDownloadLink | Select-String -Pattern $regex -AllMatches  | Select-Object -First 1 | %{$_.Matches} | %{$_.Value}

$regex = "[0-9]+\.[0-9]+\.[0-9]+f[0-9]+"
$currentVersionNumber = $currentVersion | Select-String -Pattern $regex -AllMatches  | Select-Object -First 1 | %{$_.Matches} | %{$_.Value}


if(!($currentVersion))
{
    Write-Error -Category InvalidResult -Message "Cannot obtain the most current version of Unity3D."
}
elseif(!(Test-Path -Path "$dependenciesDir\$currentVersion"))
{
    Get-ChildItem -Path $dependenciesDir | ForEach-Object {
        Start-Process -Wait -FilePath "$dependenciesDir\$_\Unity\Editor\Uninstall.exe" -ArgumentList "/S _?=$dependenciesDir\$_\Unity\Editor\"
        Remove-Item -Recurse -Path "$dependenciesDir\$_"
    }

    New-Item -ItemType directory -Path "$dependenciesDir\$currentVersion"
    wget -OutFile "$dependenciesDir\$currentVersion\$currentVersion.exe" $currentDownloadLink 
    wget -OutFile "$dependenciesDir\$currentVersion\UnitySetup-Windows-Support-for-Editor-$currentVersionNumber.exe" "http://netstorage.unity3d.com/unity/$currentRevision/TargetSupportInstaller/UnitySetup-Windows-Support-for-Editor-$currentVersionNumber.exe"

    Start-Process -Wait -FilePath "$dependenciesDir\$currentVersion\$currentVersion.exe" -ArgumentList "/S /D=$dependenciesDir\$currentVersion\Unity"
    Start-Process -Wait -FilePath "$dependenciesDir\$currentVersion\UnitySetup-Windows-Support-for-Editor-$currentVersionNumber.exe" -ArgumentList "/S /D=$dependenciesDir\$currentVersion\Unity"

    if((Test-Path -Path "$dependenciesDir\latest"))
    {
        cmd /c rmdir /q "$dependenciesDir\latest"
    }
    cmd /c mklink /D "$dependenciesDir\latest" "$dependenciesDir\$currentVersion"

    Write-Host "Installed: $currentVersion"
}
else
{
    Write-Host "Current version already installed: $currentVersion"
    
}

Remove-Item -Path $archiveContent
