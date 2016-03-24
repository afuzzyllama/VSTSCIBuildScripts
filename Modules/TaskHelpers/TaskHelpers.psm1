function Get-VSLatestVersion
{
    $regPath = "HKLM:\SOFTWARE\Microsoft\VisualStudio"
	if (-not (Test-Path $regPath))
	{
		return $null
	}
	
	$keys = Get-Item $regPath | %{$_.GetSubKeyNames()} -ErrorAction SilentlyContinue
	$version = Get-LatestVersion $keys

	if ([string]::IsNullOrWhiteSpace($version))
	{
		return $null
	}
	return $version
}

function Get-LatestVersion($keys)
{
    [decimal]$decimalKey = $null
	[decimal]$latestVersion = 0.0
	[string]$latestVersionString = "00"
	foreach ($key in $keys)
	{
		if([decimal]::TryParse($key, [ref]$decimalKey) -eq $true)
		{
			if($latestVersion -lt $decimalKey)
			{
				$latestVersion = $decimalKey
				$latestVersionString = $key.Replace(".", "")
			}
		}
	}

	return $latestVersionString
}

function Get-VSRootPath
{
    $version = Get-VSLatestVersion
    
    if($version -eq $null)
    {
        return $null
    }
    
    $vsComnDir = [Environment]::GetEnvironmentVariable("VS$($version)COMNTools")
    
    if($vsComnDir -eq $null)
    {
        return $null
    }
    
    return [System.IO.Path]::GetFullPath(Join-Path $vsComnDir "..\..\")
}

Function Get-VSTSConfiguration([string]$jsonFile)
{
    $json = Get-Content $jsonFile
    
    $configuration = ConvertFrom-Json $json
    
    return $configuration
}

<#
    Determines the assembly version of the project.  This function works during the build process

    Returns:
        
        String representation of assembly version 


#>
Function Get-AssemblyVersion()
{
    $configuration = Get-VSTSConfiguration($env:VSTSCONFIGFILE)
    Return [string]::Format("{0}.{1}.{2}.{3}", $configuration.Version.Major, $configuration.Version.Minor, $configuration.Version.Patch, $env:BUILD_BUILDID);
}

<#

    Gets the authorization butes from a github username and access token

    Parameters:

        username - github username
        accessToken - github access token

    Returns

        Base 64 string that represents the authorization bytes

#>    
Function Get-AuthorizationBytes([string]$username, [string] $accessToken)
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
function Get-WebRequest([string]$uri, [string]$method, [hashtable]$headers, [hashtable]$parameters)
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
function UploadFile([string]$uri, [string]$filepath, [hashtable]$headers)
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

Export-ModuleMember -function Get-VSLatestVersion
Export-ModuleMember -function Get-VSRootPath
Export-ModuleMember -function Get-VSTSConfiguration
Export-ModuleMember -function Get-AssemblyVersion
Export-ModuleMember -function Get-AuthorizationBytes
Export-ModuleMember -function Get-WebRequest
Export-ModuleMember -function UploadFile
