[cmdletbinding()]
param(
    [parameter(Mandatory=$true)]
    [string]$CoverageFilePath
    
    [parameter(Mandatory=$true)]
    [string]$CoverageXmlFilePath
)

Import-Module TaskHelpers
$vsPath = Get-VSRootPath 

Add-Type -Path "$vsPath\Common7\IDE\PrivateAssemblies\Microsoft.VisualStudio.Coverage.Analysis.dll"

$coverageInfo = [Microsoft.VisualStudio.Coverage.Analysis.CoverageInfo]::CreateFromFile($CoverageFilePath)
$data = $coverageInfo.BuildDataSet($null)
$data.ExportXml($CoverageXmlFilePath)
