[cmdletbinding()]
param(
    [parameter(Mandatory=$true)]
    [string]$OutputFile
)

Import-Module TaskHelpers

Start-Job -ArgumentList $OutputFile -scriptblock { 

    $outFile = $args[0]
    $vsPath = Get-VSRootPath
    Start-Process -Verb runAs -FilePath "$vsPath\Team Tools\Performance Tools\vsperfcmd.exe" -ArgumentList "/Start:coverage /Output:$outFile /CrossSession /User:Everyone" 

} 

#wait for VSPerfCmd to start up
Write-Host "Waiting 5s for vsperfmon to start up..."
Start-Sleep -s 5


$vsPath = Get-VSRootPath
$counter = 0
while($counter -lt 6)
{
    $e = Start-Process -Verb runAs -FilePath "$vsPath\Team Tools\Performance Tools\vsperfcmd.exe" -ArgumentList "/status" -PassThru -Wait

    if ($e.ExitCode -eq 0){
        break       
    }

    if ($e.ExitCode -eq 1 -and $counter -lt 5){
        Write-Host "Still waiting. Give it 5s more ($counter)..."
        Start-Sleep -s 5
        $counter++
        continue
    }

    Write-Error "Cannot start vsperfmon" 
}

