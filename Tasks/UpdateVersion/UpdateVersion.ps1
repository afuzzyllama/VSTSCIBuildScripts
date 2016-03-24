<#
    Script to update the assembly version of a project in a really crude way.  Will replace whatever is in 
    AssemblyVersion, AssemblyFileVersion, AssemblyInformationalVersion with the following version format:

        Major.Minor.PathId.BuildId
            
    This script will only run in a TFS build process because it relies on environment variables defined by TFS.

#>

[cmdletbinding()]
param(
    [parameter(Mandatory=$true)]
    [string]$AssemblyInfoFile
)

Import-Module TaskHelpers
 
$assemblyVersion = Get-AssemblyVersion

# Replace the version with the generated version
$assemblyInfo = [system.io.file]::ReadAllText($AssemblyInfoFile)

$assemblyInfo = [regex]::Replace($assemblyInfo, "\[assembly: AssemblyVersion\(`"[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+`"\)\]", [string]::Format("[assembly: AssemblyVersion(`"{0}`")]", $assemblyVersion))
$assemblyInfo = [regex]::Replace($assemblyInfo, "\[assembly: AssemblyFileVersion\(`"[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+`"\)\]", [string]::Format("[assembly: AssemblyFileVersion(`"{0}`")]", $assemblyVersion))

$assemblyInfo | Out-File $assemblyInfoFile

# Append the informational version to the end of the file
Add-Content $assemblyInfoFile ([string]::Format("[assembly: AssemblyInformationalVersion(`"{0}`")]", $assemblyVersion))

Write-Host ([string]::Format("Building version: {0}", $assemblyVersion))

