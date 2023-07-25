function Get-OktaUsers {
    <#
    .SYNOPSIS
        Retrieves Okta users based on specified filters.

    .DESCRIPTION
        This function communicates with the Okta API to retrieve Okta users based on the provided filters. It creates an array of users with their attribute information.

    .PARAMETER ApiToken
        The API token used to authenticate with the Okta API.

    .PARAMETER OrgName
        The Okta organization name used to construct the API URL.

    .PARAMETER FirstName
        Filters users by first name.

    .PARAMETER LastName
        Filters users by last name.

    .PARAMETER Email
        Filters users by email address.

    .PARAMETER Department
        Filters users by department.

    .PARAMETER Status
        Filters users by status. Possible values:
        - STAGED: New users created through the API and not activated yet.
        - PROVISIONED: Users manually activated by an admin, but haven't completed the activation process.
        - ACTIVE: Users in an active state.
        - RECOVERY: Existing users in password reset mode.
        - PASSWORD EXPIRED: Users with an expired password.
        - LOCKED OUT: Users who exceeded the number of login attempts defined in the login policy.
        - SUSPENDED: Users cannot access applications, including the dashboard/admin.
        - DEPROVISIONED: Deactivated users in Okta.

    .PARAMETER Minimal
        When specified, includes only the following minimal set of attributes in the output:
        - First name
        - Last name
        - Email
        - Status
        - ID
        - Title
        - Department

    .EXAMPLE
        Get-OktaUsers -ApiToken "YOUR_API_TOKEN" -OrgName "your-okta-org" -Status "ACTIVE" -Minimal

    .NOTES
        Ensure that you have the required API token and Okta organization name to successfully retrieve user information.
    #>
    [CmdletBinding()]
    param (
        [Alias("Api")]
        [Parameter(Mandatory = $false, HelpMessage = "The API token used to authenticate with the Okta API.")]
        [String]$ApiToken = $env:OKTA_API_TOKEN,

        [Alias("Org")]
        [Parameter(Mandatory = $false, HelpMessage = "The Okta organization name used to construct the API URL.")]
        [String]$OrgName = $env:OKTA_ORG_NAME,

        [Parameter(Mandatory = $false, HelpMessage = "Filters users by first name.")]
        [String]$FirstName,

        [Parameter(Mandatory = $false, HelpMessage = "Filters users by last name.")]
        [String]$LastName,

        [Parameter(Mandatory = $false, HelpMessage = "Filters users by email address.")]
        [String]$Email,

        [Parameter(Mandatory = $false, HelpMessage = "Filters users by department.")]
        [String]$Department,

        [Parameter(Mandatory = $false, HelpMessage = @"
Filters users by status. Possible values:
- STAGED: New users created through the API and not activated yet.
- PROVISIONED: Users manually activated by an admin, but haven't completed the activation process.
- ACTIVE: Users in an active state.
- RECOVERY: Existing users in password reset mode.
- PASSWORD EXPIRED: Users with an expired password.
- LOCKED OUT: Users who exceeded the number of login attempts defined in the login policy.
- SUSPENDED: Users cannot access applications, including the dashboard/admin.
- DEPROVISIONED: Deactivated users in Okta.
"@)]
        [ValidateSet("STAGED", "PROVISIONED", "ACTIVE", "RECOVERY", "PASSWORD EXPIRED", "LOCKED OUT", "SUSPENDED", "DEPROVISIONED")]
        [String]$Status,

        [Parameter(Mandatory = $false, HelpMessage = "Includes only the first name, last name, email, status, ID, title, and department in the output.")]
        [Switch]$Minimal
    )

    # Create an array to store filtered users
    $filteredUsers = @()

    # Invoke the Okta API to retrieve users
    $response = Invoke-OktaApi -ApiToken $ApiToken -OrgName $OrgName -Method "Get"

    # Iterate through each user and apply filters
    foreach ($user in $response) {
        $match = $true

        if ($FirstName -and $user.profile.firstName -ne $FirstName) {
            $match = $false
        }
        if ($LastName -and $user.profile.lastName -ne $LastName) {
            $match = $false
        }
        if ($Email -and $user.profile.email -ne $Email) {
            $match = $false
        }
        if ($Department -and $user.profile.department -ne $Department) {
            $match = $false
        }
        if ($Status) {
            switch ($Status) {
                "STAGED" {
                    if ($user.status -ne "STAGED") {
                        $match = $false
                    }
                }
                "PROVISIONED" {
                    if ($user.status -ne "PROVISIONED") {
                        $match = $false
                    }
                }
                "ACTIVE" {
                    if ($user.status -ne "ACTIVE") {
                        $match = $false
                    }
                }
                "RECOVERY" {
                    if ($user.status -ne "RECOVERY") {
                        $match = $false
                    }
                }
                "PASSWORD EXPIRED" {
                    if ($user.status -ne "PASSWORD_EXPIRED") {
                        $match = $false
                    }
                }
                "LOCKED OUT" {
                    if ($user.status -ne "LOCKED_OUT") {
                        $match = $false
                    }
                }
                "SUSPENDED" {
                    if ($user.status -ne "SUSPENDED") {
                        $match = $false
                    }
                }
                "DEPROVISIONED" {
                    if ($user.status -ne "DEPROVISIONED") {
                        $match = $false
                    }
                }
                default {
                    $match = $false
                }
            }
        }

        if ($match) {
            if ($Minimal) {
                $filteredUser = [PSCustomObject]@{
                    "First Name" = $user.profile.firstName
                    "Last Name" = $user.profile.lastName
                    "Email" = $user.profile.email
                    "Status" = $user.status
                    "ID" = $user.id
                    "Title" = $user.profile.title
                    "Department" = $user.profile.department
                }
            } else {
                $filteredUser = $user
            }

            $filteredUsers += $filteredUser
        }
    }

    # Output the filtered array of user objects
    return $filteredUsers
}
