<#
    This script will take all the files located in a directory named "ReleaseContents" in the build staging directory and place them in a zip file in the
    staging directory with a name  in the following format:

        RepoName.Major.Minor.PatchId.BuildId.zip

    This script will only run in a TFS build process because it relies on environment variables defined by TFS.

#>

[cmdletbinding()]
param(
    [parameter(Mandatory=$true)]
    [string]$ReleaseFolder
)

Import-Module TaskHelpers

Add-Type -Assembly System.IO.Compression.FileSystem
$compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal

$assemblyVersion = Get-AssemblyVersion $assemblyInfoFile

[System.IO.Compression.ZipFile]::CreateFromDirectory($ReleaseFolder, ([string]::Format("{0}\{1}.{2}.zip", $env:BUILD_STAGINGDIRECTORY, $env:GITREPO, $assemblyVersion)), $compressionLevel, $false <# include base directory? #>)
