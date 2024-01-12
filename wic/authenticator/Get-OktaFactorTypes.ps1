function Get-OktaFactorTypes {
    [CmdletBinding()]
    param (
        [Alias("Api")]
        [Parameter(Mandatory = $false, HelpMessage = "The API token used to authenticate with the Okta API.")]
        [String]$ApiToken = $env:OKTA_API_TOKEN,

        [Alias("Org")]
        [Parameter(Mandatory = $false, HelpMessage = "The Okta organization name used to construct the API URL.")]
        [String]$OrgName = $env:OKTA_ORG_NAME
    )

    # Check if the required parameters are provided
    if (-not $ApiToken -or -not $OrgName) {
        Write-Host "Error: API token and organization name are required parameters. Please provide them."
        return
    }

    # Construct the API URL
    $OrgUrl = "https://$OrgName.okta.com"

    # Define the API endpoints for List Factors and User Information
    $FactorsApiEndpoint = "$OrgUrl/api/v1/factors"
    $UsersApiEndpoint = "$OrgUrl/api/v1/users"

    # Create a header with the API key
    $headers = @{
        'Authorization' = "SSWS $ApiToken"
    }

    # Send a GET request to the List Factors API
    try {
        $factorsResponse = Invoke-RestMethod -Uri $FactorsApiEndpoint -Headers $headers -Method Get

        # Check if the request was successful
        if ($factorsResponse) {
            # Initialize an array to store factor types with user info
            $factorTypes = @()

            # Loop through the response and extract factor types
            foreach ($factor in $factorsResponse) {
                # Send a GET request to the User Information API
                $userResponse = Invoke-RestMethod -Uri "$UsersApiEndpoint/$($factor.userId)" -Headers $headers -Method Get

                if ($userResponse.StatusCode -eq 200) {
                    $firstName = $userResponse.profile.firstName
                    $lastName = $userResponse.profile.lastName
                    $userName = $userResponse.profile.login

                    $factorTypes += [PSCustomObject]@{
                        UserId     = $factor.userId
                        FirstName  = $firstName
                        LastName   = $lastName
                        UserName   = $userName
                        FactorType = $factor.factorType
                    }
                }
            }

            # Output the structured array
            $factorTypes
        } else {
            Write-Host "Error: Failed to retrieve factor types."
        }
    } catch {
        Write-Host "Error: $_"
    }
}

# Uncomment and use the following line to call the function with parameters or use environment variables.
# Get-OktaFactorTypes -ApiToken "YOUR_API_TOKEN" -OrgName "YOUR_ORG_NAME"
