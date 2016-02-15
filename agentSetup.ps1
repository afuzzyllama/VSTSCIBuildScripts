. C:\agent\buildScripts\profile.ps1

$EMAIL = Read-Host "Enter email address for service account: "

$SSHDIR = "~\.ssh"
$SSHFILE = "$SSHDIR\id_rsa"
if(!(Test-Path -Path $SSHDIR))
{
    New-Item -ItemType directory -Path $SSHDIR
}

ssh-keygen.exe -q -f $SSHFILE -b 4096 -t rsa -N "''" -C $EMAIL 
ssh-add.exe $SSHFILE 2>&1 | %{ Write-Host $_ }
