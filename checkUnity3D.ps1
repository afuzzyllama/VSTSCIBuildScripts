. C:\agent\buildScripts\profile.ps1 

$ARCHIVECONTENT = "C:\agent\content"
$DEPENDENCIESDIR = "C:\agent\dependencies\Unity"

Write-Host "Checking for latest version of Unity3D"

if(!(Test-Path -Path $DEPENDENCIESDIR))
{
    New-Item -ItemType directory -Path $DEPENDENCIESDIR | Out-Null
}

wget -OutFile $ARCHIVECONTENT https://unity3d.com/get-unity/download/archive

$Regex = "(http|https)://(netstorage|download).unity3d.com/(download_unity|unity)/[a-z0-9]+/Windows32EditorInstaller/UnitySetup32-[0-9]+\.[0-9]+\.[0-9]+f[0-9]+\.exe"
$CurrentDownloadLink = Select-String -Path $ARCHIVECONTENT -Pattern $Regex -AllMatches | Select-Object -First 1 | %{$_.Matches} | %{$_.Value}


$Regex = "UnitySetup32-[0-9]+\.[0-9]+\.[0-9]+f[0-9]+"
$CurrentVersion = $CurrentDownloadLink | Select-String -Pattern $Regex -AllMatches  | Select-Object -First 1 | %{$_.Matches} | %{$_.Value}


if(!(Test-Path -Path "$DEPENDENCIESDIR\$CurrentVersion"))
{
    Get-ChildItem -Path $DEPENDENCIESDIR | ForEach-Object {
        Start-Process -Wait -FilePath "$DEPENDENCIESDIR\$_\Unity\Editor\Uninstall.exe" -ArgumentList "/S _?=$DEPENDENCIESDIR\$_\Unity\Editor\"
        Remove-Item -Recurse -Path "$DEPENDENCIESDIR\$_"
    }

    New-Item -ItemType directory -Path "$DEPENDENCIESDIR\$CurrentVersion"
    wget -OutFile "$DEPENDENCIESDIR\$CurrentVersion\$CurrentVersion.exe" $CurrentDownloadLink 
    Start-Process -Wait -FilePath "$DEPENDENCIESDIR\$CurrentVersion\$CurrentVersion.exe" -ArgumentList "/S /D=$DEPENDENCIESDIR\$CurrentVersion\Unity"

    Write-Host "Installed: $CurrentVersion"
}
else
{
    Write-Host "Current version already installed: $CurrentVersion"
}

Remove-Item -Path $ARCHIVECONTENT
