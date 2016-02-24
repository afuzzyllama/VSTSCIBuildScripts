<#

    Script that will create a github release with appropriate tag.  This script is intended to be used with the release system in TFS.

    Creates a tag, a reference for that tag, and uploads a zip file to the release in the release's artifact directory.

    Requires the following custom environment variables to be set in TFS:

        BuildScriptDir            - Absolute path to where all powershell scripts for this agent are stored
        AssemblyInfoRelativePath  - Relative path to the AssemblyInfo.cs file in the git repository
        GitUsername               - Username of git user to create the release
        GitRepoOwner              - The username/organization that owns the repository
        GitRepo                   - The repository to release in
        GitProfileName            - The display name for the GitUsername
        GitUserEmail              - The email of the git user to create the release

    A special case to use this script:

        The git access token must be passed in as argument 0 to this script.  TFS does not create environment variables for secrets.
        Therefore something like $(gitAccessToken) must be passed into this script to get the secret in.  Be careful when editing this
        script not to reveal the secret!

#>

. "$env:BUILDSCRIPTDIR\sharedFunctions.ps1"

# The access token is not pushed into the $env scope so, it is passed to this script manually
$GitAccessToken = $args[0]

$assemblyInformationalVersion = getAssemblyInformationalVersionFromFile "$env:AGENT_RELEASEDIRECTORY\$env:BUILD_DEFINITIONNAME\ReleaseContents\VERSION"
$authorizationBytes = getAuthorizationBytes $env:GITUSERNAME $GitAccessToken

$headers = @{
            "Authorization"=([string]::Format("Basic {0}", $authorizationBytes));
            "Content-Type"="application/json; charset=utf-8"
            }

# Create tag

Write-Host ([string]::Format("Creating tag for v{0}", $assemblyInformationalVersion));
$uri = "https://api.github.com/repos/$env:GITREPOOWNER/$env:GITREPO/git/tags"
$method = "POST"

$currentDate = Get-Date
$currentDate = $currentDate.ToUniversalTime()

$parameters = @{
    tag=([string]::Format("v{0}", $assemblyInformationalVersion));
    message="CI Build";
    object=$env:BUILD_SOURCEVERSION;
    type="commit";
    tagger= @{
        name=$env:GITPROFILENAME;
        email=$env:GITUSEREMAIL;
        date=$currentDate.ToString("yyyy-MM-ddThh:mm:ssZ")
    }
}

try
{           
    $webResponse = getWebRequest $uri $method $headers $parameters
}
catch
{
    Write-Error ([string]::Format("Could not create tag for v{0} - {1}", $assemblyInformationalVersion, $_.Exception.Message));
    Write-Error ([string]::Format("URI: {0}", $uri));
    exit 1
}
Write-Host ([string]::Format("Successfully created tag for v{0}", $assemblyInformationalVersion));


# Create tag reference
Write-Host ([string]::Format("Creating reference for v{0}", $assemblyInformationalVersion));
$uri = "https://api.github.com/repos/$env:GITREPOOWNER/$env:GITREPO/git/refs"
$method = "POST"

$parameters = @{
    ref=([string]::Format("refs/tags/v{0}", $assemblyInformationalVersion))
    sha=$env:BUILD_SOURCEVERSION;
}

try
{           
    $webResponse = getWebRequest $uri $method $headers $parameters
}
catch
{
    Write-Error ([string]::Format("Could not create reference for v{0} - {1}", $assemblyInformationalVersion, $_.Exception.Message));
    Write-Error ([string]::Format("URI: {0}", $uri));
    exit 1
}

Write-Host ([string]::Format("Successfully created reference for v{0}", $assemblyInformationalVersion));

# Create release

Write-Host ([string]::Format("Publishing release for v{0}", $assemblyInformationalVersion));

$uri = "https://api.github.com/repos/$env:GITREPOOWNER/$env:GITREPO/releases"
$method = "POST"

$parameters = @{
    tag_name=([string]::Format("v{0}", $assemblyInformationalVersion));
    target_commitish="master";
    name=([string]::Format("v{0}", $assemblyInformationalVersion));
    body="Successful CI build of library.  Please consult the [ReadMe](https://github.com/$env:GITREPOOWNER/$env:GITREPO/blob/master/README.md) for implementing this release into your project.";
    draft=$false;
    prerelease=$false
}

try
{  
    $webResponse = getWebRequest $uri $method $headers $parameters
}
catch
{
    Write-Error ([string]::Format("Could not publish release for v{0} - {1}", $assemblyInformationalVersion, $_.Exception.Message));
    Write-Error ([string]::Format("URI: {0}", $uri));
    exit 1
}

Write-Host ([string]::Format("Successfully published release for v{0}", $assemblyInformationalVersion));

# Get latest release id

$uri = ([string]::Format("https://api.github.com/repos/$env:GITREPOOWNER/$env:GITREPO/releases/tags/v{0}", $assemblyInformationalVersion))
$method = "GET"

Write-Host $uri

$webResponse = getWebRequest $uri $method $headers @{}

$content = $webResponse | ConvertFrom-Json
$releaseId = $content.id


# Upload release file 
Write-Host ([string]::Format("Uploading release zip for v{0}", $assemblyInformationalVersion));

$zipName = ([string]::Format("{0}.{1}.zip", $env:GITREPO, $assemblyInformationalVersion))

$uri = "https://uploads.github.com/repos/$env:GITREPOOWNER/$env:GITREPO/releases/$releaseId/assets?name=$zipName"


$headers = @{"Authorization"=([string]::Format("Basic {0}", $authorizationBytes))}

try
{
    uploadFile $uri ([string]::Format("{0}\{1}.{2}.zip","$env:AGENT_RELEASEDIRECTORY\$env:BUILD_DEFINITIONNAME\ReleaseContents\", $env:GITREPO, $assemblyInformationalVersion)) $headers 
}
catch
{
    Write-Error ([string]::Format("Could not upload release zip for v{0} - {1}", $assemblyInformationalVersion, $_.Exception.Message));
    Write-Error ([string]::Format("URI: {0}", $uri));
    exit 1
}

Write-Host ([string]::Format("Successfully uploaded release zip for v{0}", $assemblyInformationalVersion));
