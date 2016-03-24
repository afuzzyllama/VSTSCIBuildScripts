[cmdletbinding()]
param(
    [parameter(Mandatory=$true)]
    [string]$AssemblyFile
)

Import-Module TaskHelpers

$vsPath = Get-VSRootPath

Start-Process -FilePath "$vsPath\Team Tools\Performance Tools\vsinstr.exe" -ArgumentList "-coverage $assemblyToInstrument" -NoNewWindow -Wait

if((Test-Path "$assemblyToInstrument.orig") -eq $false)
{
    Write-Error "$assemblyToInstrument was not instrumented"
}
