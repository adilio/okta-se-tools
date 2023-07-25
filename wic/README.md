# PowerShell Scripts and Functions for Okta Management

This repository contains PowerShell scripts and functions that interact with the Okta API to manage users and perform various operations in an Okta organization. The scripts are designed to be used in a PowerShell environment with the necessary API token and Okta organization name.

## Contents

1. [Get-OktaUsers.ps1](#get-oktausersps1)
2. [Invoke-OktaApi.ps1](#invoke-oktaapips1)
3. [New-OktaUser.ps1](#new-oktauserps1)
4. [Remove-OktaUser.ps1](#remove-oktauserps1)
5. [config.json.example](#configjsonexample)

---

## Get-OktaUsers.ps1

### Description

This script retrieves Okta users based on specified filters. It communicates with the Okta API to retrieve users and creates an array of users with their attribute information.

### Parameters

- **ApiToken**: The API token used to authenticate with the Okta API.
- **OrgName**: The Okta organization name used to construct the API URL.
- **FirstName**: Filters users by first name.
- **LastName**: Filters users by last name.
- **Email**: Filters users by email address.
- **Department**: Filters users by department.
- **Status**: Filters users by status. Possible values: "STAGED", "PROVISIONED", "ACTIVE", "RECOVERY", "PASSWORD EXPIRED", "LOCKED OUT", "SUSPENDED", "DEPROVISIONED".
- **Minimal**: When specified, includes only a minimal set of attributes in the output: First name, Last name, Email, Status, ID, Title, and Department.

### Example

```powershell
Get-OktaUsers -ApiToken "YOUR_API_TOKEN" -OrgName "your-okta-org" -Status "ACTIVE" -Minimal
```

## Invoke-OktaApi.ps1

### Description

This PowerShell script (`Invoke-OktaApi.ps1`) is a function that makes a REST API request to an Okta endpoint using the provided parameters. It allows you to interact with the Okta API for various operations.

### Parameters

- **ApiToken**: The API token used to authenticate with the Okta API. This parameter is optional if the API token is provided in the environment variable `$env:OKTA_API_TOKEN`.
- **OrgName**: The Okta organization name used to construct the API URL. This parameter is optional if the organization name is provided in the environment variable `$env:OKTA_ORG_NAME`.
- **Method**: The HTTP method to use for the API request. Valid values are "Get", "Post", "Put", or "Delete". This parameter is mandatory.

### Examples

1. Make a GET request to Okta API:

```powershell
Invoke-OktaApi -ApiToken "YOUR_API_TOKEN" -OrgName "your-okta-org" -Method Get
```

1. Make a POST request to Okta API:

```powershell
Invoke-OktaApi -ApiToken "YOUR_API_TOKEN" -OrgName "your-okta-org" -Method Post
```

### Notes

- Ensure that you have the required API token and Okta organization name defined in the function or provided as parameters to successfully invoke the Okta API.
- The function checks for the `ApiToken` and `OrgName` as parameters first. If not provided, it looks for them in the environment variables `$env:OKTA_API_TOKEN` and `$env:OKTA_ORG_NAME`, respectively. If still not found, it looks for a configuration file (`config.json`) in the current directory. Ensure the configuration file is formatted correctly with the `OrgName` and `ApiToken` fields.

## New-OktaUser.ps1

### Description
This script creates a new user in Okta using the provided user attributes.

### Parameters
- **UserAttributes**: A hashtable containing the user attributes. Required attributes:
    - "firstName"
    - "lastName"
    - "email"
    - "login"

### Example

```powershell
$userAttributes = @{
    "firstName" = "John"
    "lastName" = "Doe"
    "email" = "john.doe@example.com"
    "login" = "johndoe"
}
New-OktaUser -UserAttributes $userAttributes
```