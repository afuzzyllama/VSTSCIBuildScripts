$assemblyInfoFile = Join-Path  $env:BUILD_SOURCESDIRECTORY $env:ASSEMBLYINFORELATIVEPATH 
$assemblyInfoFile = Join-Path  $assemblyInfoFile "AssemblyInfo.cs"

$assemblyInfo = [system.io.file]::ReadAllText($assemblyInfoFile)

$assemblyInfoVersionString = [regex]::Matches($assemblyInfo, "\[assembly: AssemblyVersion\(`"[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+`"\)\]")
$assemblyInfoVersion = [regex]::Matches($assemblyInfoVersionString, "[0-9]+\.[0-9]+") 
$assemblyInfoVersion = [string]$assemblyInfoVersion[0]

$assemblyVersion = [string]::Format("{0}.{1}", $assemblyInfoVersion, $env:BUILD_BUILDID)
$AssemblyInformationalVersion = [string]::Format("{0}.{1}.{2}", $assemblyInfoVersion, $env:BUILD_BUILDID, $env:BUILD_SOURCEVERSION.SubString(0,7))

$assemblyInfo = [regex]::Replace($assemblyInfo, "\[assembly: AssemblyVersion\(`"[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+`"\)\]", "[assembly: AssemblyVersion(`"$assemblyVersion`")]")
$assemblyInfo = [regex]::Replace($assemblyInfo, "\[assembly: AssemblyFileVersion\(`"[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+`"\)\]", "[assembly: AssemblyFileVersion(`"$assemblyVersion`")]")

$assemblyInfo | Out-File $assemblyInfoFile
Add-Content $assemblyInfoFile "`n[assembly: AssemblyInformationalVersion(`"$AssemblyInformationalVersion`")]"
