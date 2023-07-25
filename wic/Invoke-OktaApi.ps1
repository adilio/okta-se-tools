function Invoke-OktaApi {
    <#
    .SYNOPSIS
        Invokes an Okta API endpoint.

    .DESCRIPTION
        This function makes a REST API request to an Okta endpoint using the provided parameters.

    .PARAMETER ApiToken
        The API token used to authenticate with the Okta API.

    .PARAMETER OrgName
        The Okta organization name used to construct the API URL.

    .PARAMETER Method
        The HTTP method to use for the API request.

    .EXAMPLE
        Invoke-OktaApi -ApiToken "YOUR_API_TOKEN" -OrgName "your-okta-org" -Method Get

    .NOTES
        Ensure that you have the required API token and Okta organization name to successfully invoke the Okta API.
    #>
    [CmdletBinding()]
    param (
        [Alias("Api")]
        [Parameter(Mandatory = $false, HelpMessage = "The API token used to authenticate with the Okta API.")]
        [String]$ApiToken = $env:OKTA_API_TOKEN,

        [Alias("Org")]
        [Parameter(Mandatory = $false, HelpMessage = "The Okta organization name used to construct the API URL.")]
        [String]$OrgName = $env:OKTA_ORG_NAME,

        [Parameter(Mandatory = $true, HelpMessage = "The HTTP method to use for the API request.")]
        [ValidateSet("Get", "Post", "Put", "Delete")]
        [String]$Method
    )

    # Check if the API token and OrgName are not specified as parameters
    if (-not $ApiToken -or -not $OrgName) {
        # Check if the API token and OrgName are defined in environment variables
        if ($env:OKTA_API_TOKEN -and $env:OKTA_ORG_NAME) {
            $ApiToken = $env:OKTA_API_TOKEN
            $OrgName = $env:OKTA_ORG_NAME
        }
        else {
            # Check if the API token and OrgName are defined in a configuration file
            $configFile = ".\config.json"  # Update with the actual path to the configuration file
            if (Test-Path $configFile) {
                $config = Get-Content $configFile -Raw | ConvertFrom-Json
                $OrgName = $config.OrgName
                $ApiToken = $config.ApiToken
            }
            else {
                Write-Error "API token and OrgName must be provided as parameters, defined in environment variables, or specified in a configuration file."
                return
            }
        }
    }

    # Check if the OrgName is in the "orgname" or "orgname.okta.com" format
    $baseUrl = $OrgName
    if ($OrgName -notlike "*.okta.com") {
        $baseUrl = "$OrgName.okta.com"
    }

    # Set the Okta API endpoint
    $apiUrl = "https://$baseUrl/api/v1/users"

    # Set the authorization header
    $headers = @{
        'Accept' = 'application/json'
        'Content-Type' = 'application/json'
        'Authorization' = "SSWS $ApiToken"
    }

    # Make the API request
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method $Method
    }
    catch {
        Write-Error "Failed to invoke Okta API. Error: $_"
        return
    }

    # Output the response
    return $response
}
