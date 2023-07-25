function New-OktaUser {
    <#
    .SYNOPSIS
        Creates a new user in Okta.

    .DESCRIPTION
        This function creates a new user in Okta using the provided user attributes.

    .PARAMETER UserAttributes
        A hashtable containing the user attributes. Required attributes: "firstName", "lastName", "email", "login".

    .EXAMPLE
        $userAttributes = @{
            "firstName" = "John"
            "lastName" = "Doe"
            "email" = "john.doe@example.com"
            "login" = "johndoe"
        }
        New-OktaUser -I apologize for the incomplete code. Here's the complete code snippet for the `New-OktaUser` function:

```powershell
function New-OktaUser {
    <#
    .SYNOPSIS
        Creates a new user in Okta.

    .DESCRIPTION
        This function creates a new user in Okta using the provided user attributes.

    .PARAMETER UserAttributes
        A hashtable containing the user attributes. Required attributes: "firstName", "lastName", "email", "login".

    .EXAMPLE
        $userAttributes = @{
            "firstName" = "John"
            "lastName" = "Doe"
            "email" = "john.doe@example.com"
            "login" = "johndoe"
        }
        New-OktaUser -UserAttributes $userAttributes

    .NOTES
        Ensure that you have the required API token and Okta organization name defined in the Invoke-OktaApi function to successfully create the user in Okta.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "A hashtable containing the user attributes. Required attributes: `firstName`, `lastName`, `email`, `login`.")]
        [Hashtable]$UserAttributes
    )

    # Construct the user object
    $userObject = @{
        "profile" = @{
            "firstName" = $UserAttributes["firstName"]
            "lastName" = $UserAttributes["lastName"]
            "email" = $UserAttributes["email"]
            "login" = $UserAttributes["login"]
        }
        "credentials" = @{
            "password" = @{
                "value" = $UserAttributes["password"]
            }
        }
    }

    # Convert the user object to JSON
    $userJson = $userObject | ConvertTo-Json

    # Invoke the Okta API to create the user
    $response = Invoke-OktaApi -Method "Post" -Body $userJson

    # Output the response
    return $response
}
