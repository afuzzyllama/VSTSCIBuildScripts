[cmdletbinding()]
param(
    [parameter(Mandatory=$true)]
    [string]$CoverageXmlFilePath
    
    [parameter(Mandatory=$true)]
    [string]$CoverallsRepoToken
)

$coveralls = "$env:DEPENDENCIES_DIR\Coveralls.NET\latest\Coveralls.NET\tools\csmacnz.Coveralls.exe"
& $coveralls --exportcodecoverage -i $coverageXml -o $coverageXml.json --useRelativePaths --repoToken $CoverallsRepoToken 