function Remove-OktaUser {
    <#
    .SYNOPSIS
        Removes an Okta user.

    .DESCRIPTION
        This function removes an Okta user based on the provided user ID.

    .PARAMETER UserId
        The ID of the user to remove.

    .EXAMPLE
        Remove-OktaUser -UserId "user123"

    .NOTES
        Ensure that you have the required API token, Okta organization name, and user ID defined in the Invoke-OktaApi function to successfully remove the user in Okta.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The ID of the user to remove.")]
        [String]$UserId
    )

    # Construct the user URL
    $userUrl = "https://$OrgName.okta.com/api/v1/users/$UserId"

    # Invoke the Okta API to remove the user
    $response = Invoke-OktaApi -Method "Delete" -Uri $userUrl

    # Output the response
    return $response
}
