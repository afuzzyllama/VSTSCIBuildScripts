[cmdletbinding()]
param(
    [parameter(Mandatory=$true)]
    [string]$OutputFile
)

Import-Module TaskHelpers

$vsPath = Get-VSRootPath
Start-Process -Verb runAs -FilePath "$vsPath\Team Tools\Performance Tools\vsperfcmd.exe" -ArgumentList "/shutdown" 

Get-job | Remove-Job

Write-Host "Waiting 10s for vsperfmon to shutdown..."
Start-Sleep -s 10