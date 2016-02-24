<#
    Collection of functions that are used across multiple scripts.

    Requires the following custom environment variables to be set in TFS:
    
        AssemblyInfoRelativePath - Relative path to AssemblyInfo.cs file

#>

<#
    Determines the assembly version of the project.  This function works during the build process

    Parameters:

        assemblyInfoFile - Path to AssemblyInfo.cs    
    
    Returns:
        
        Object that contains the assembly version and the assembly informational version


#>
Function getAssemblyVersion([string]$assemblyInfoFile)
{
    $assemblyInfo = [system.io.file]::ReadAllText($assemblyInfoFile)
    
    $assemblyInfoVersionString = [regex]::Matches($assemblyInfo, "\[assembly: AssemblyVersion\(`"[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+`"\)\]")
    $assemblyInfoVersion = [regex]::Matches($assemblyInfoVersionString, "[0-9]+\.[0-9]+") 
    $assemblyInfoVersion = [string]$assemblyInfoVersion[0]
        
    $returnObject = New-Object -TypeName PSObject -Property @{
            AssemblyVersion              = [string]::Format("{0}.{1}", $assemblyInfoVersion, $env:BUILD_BUILDID);
            AssemblyInformationalVersion = [string]::Format("{0}.{1}.{2}", $assemblyInfoVersion, $env:BUILD_BUILDID, $env:BUILD_SOURCEVERSION.SubString(0,7))
        }

    Return $returnObject
}

<#

    Pulls the assembly informational version from a file that contains the version number

    Parameters:

        path - Path to file that contains the version number

    Returns:

        String that contains the assembly informational version

#>
Function getAssemblyInformationalVersionFromFile([string]$path)
{
    $assemblyInformationalVersion = [system.io.file]::ReadAllText($path)
    $assemblyInformationalVersion = $assemblyInformationalVersion -replace "`r|`n", ""
    Return $assemblyInformationalVersion
}

<#

    Gets the authorization butes from a github username and access token

    Parameters:

        username - github username
        accessToken - github access token

    Returns

        Base 64 string that represents the authorization bytes

#>    
function getAuthorizationBytes([string]$username, [string] $accessToken)
{
    $authorizationString = "{0}:{1}" -f $username, $accessToken
    $authorizationBytes = [System.Text.Encoding]::Ascii.GetBytes($authorizationString)
    $authorizationBytes = [Convert]::ToBase64String($authorizationBytes)

    Return $authorizationBytes
}

<#

    Processes a web request with the passed in parameters

    Paramters:
        
           uri - uri to request
           method - web method to process.  Only tested with GET and POST.  If GET, ignores the parameters variable
           headers - headers to use for the request
           parameters - hashtable to be converted to json and then passes as data in the body of the request

    Returns

        Web response object

#>
function getWebRequest([string]$uri, [string]$method, [hashtable]$headers, [hashtable]$parameters)
{
    $uriObject = New-Object -TypeName System.Uri -ArgumentList($uri)
    $parametersJSON = $parameters | ConvertTo-Json
        
    try
    {
        if($method.ToUpper() -eq "GET")
        {
            $response = Invoke-WebRequest -Uri $uri -Method $method -Headers $headers -TimeoutSec 10 -UseBasicParsing 
        }
        else
        {
            $response = Invoke-WebRequest -Uri $uri -Method $method -Headers $headers -Body $parametersJSON -TimeoutSec 10 -UseBasicParsing 
        }
    }
    catch
    {
        throw ([string]::Format("{0} : {1}", $_.Exception.Response.StatusCode, $_))
    }
    #>
    
    return $response
}

<#

    Uploads a file with the passed in parameters

    Parameters:
        
        uri - uri to upload to
        filepath - local file path to upload
        headers - headers to use for upload request

    Returns

        Web response object

#>
function uploadFile([string]$uri, [string]$filepath, [hashtable]$headers)
{
    $uriObject = New-Object -TypeName System.Uri -ArgumentList($uri)
    
    try
    {
        $response = Invoke-RestMethod -Uri $uri -Method "POST" -Headers $headers -InFile $filepath -TimeoutSec 120 -UseBasicParsing -ContentType "application/zip"
    }
    catch
    {
        throw ([string]::Format("{0} : {1}", $_.Exception.Response.StatusCode, $_))       
    }
        
    return $response
}

