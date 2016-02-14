$env:path += ";" + (Get-Item "Env:ProgramFiles").Value + "\Git\usr\bin\"
$env:path += ";" + (Get-Item "Env:ProgramFiles").Value + "\Git\cmd\"
$env:GIT_SSH_COMMAND = "ssh -o StrictHostKeyChecking=no"

. 'C:\agent\posh-git-0.4\profile.ps1'
