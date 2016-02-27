<#
    Script to update the assembly version of a project in a really crude way.  Will replace whatever is in AssemblyVersion and AssemblyFileVersion with 
    the following version format:

        Major.Minor.BuildId

    The major and minor release numbers will be already defined in the AssemblyInfo.cs file. It will also add an AssemblyInformationalVersion to the file
    with the following format:

        Major.Minor.BuildId.SourceVersion
    
    This script will only run in a TFS build process because it relies on environment variables defined by TFS.

    Requires the following custom environment variables to be set in TFS:

        BuildScriptDir            - Absolute path to where all powershell scripts for this agent are stored
        AssemblyInfoRelativePaths - Relative paths to the AssemblyInfo.cs files in the git repository.  The paths should be comma delimited and the 
                                    assembilies need to have the identical major and minor versions set.

#>

. "$env:BUILDSCRIPTDIR\sharedFunctions.ps1"

$assemblyInfoRelativePaths = $env:ASSEMBLYINFORELATIVEPATHS.Split(",")

foreach($assemblyInfoRelativePath in $assemblyInfoRelativePaths)
{
    $assemblyInfoFile = Join-Path  $env:BUILD_SOURCESDIRECTORY $assemblyInfoRelativePath.Trim()
    $assemblyInfoFile = Join-Path  $assemblyInfoFile "AssemblyInfo.cs"
    
    $assemblyVersion = getAssemblyVersion $assemblyInfoFile

    # Replace the version with the generated version
    $assemblyInfo = [system.io.file]::ReadAllText($assemblyInfoFile)

    $assemblyInfo = [regex]::Replace($assemblyInfo, "\[assembly: AssemblyVersion\(`"[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+`"\)\]", [string]::Format("[assembly: AssemblyVersion(`"{0}.0`")]", $assemblyVersion.AssemblyVersion))
    $assemblyInfo = [regex]::Replace($assemblyInfo, "\[assembly: AssemblyFileVersion\(`"[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+`"\)\]", [string]::Format("[assembly: AssemblyFileVersion(`"{0}.0`")]", $assemblyVersion.AssemblyVersion))

    $assemblyInfo | Out-File $assemblyInfoFile

    # Append the informational version to the end of the file
    Add-Content $assemblyInfoFile ([string]::Format("[assembly: AssemblyInformationalVersion(`"{0}`")]", $assemblyVersion.AssemblyInformationalVersion))
    $assemblyVersion.AssemblyInformationalVersion | Out-File "$env:BUILD_STAGINGDIRECTORY\VERSION"
}

Write-Host ([string]::Format("Building version: {0}", $assemblyVersion.AssemblyInformationalVersion))

