# Install-OktaVerify.ps1

## Description

The `Install-OktaVerify.ps1` script installs the Okta Verify executable on Windows with customizable parameters, including:
- SKU
- OrgName
- ClientID
- ClientSecret.

You can use this script multiple ways.

1. You can just run the script:

```powershell
.\Install-OktaVerify.ps1
```

This will prompt you for the file location of the Okta Verify executable (a file explorer window will open), and prompt you for the `OrgName`, `ClientID`, and `ClientSecret` values inline in the terminal.

1. You can alternatively rename the `config.json.example` to `config.json`, and populate the values of the parameters:

```json
{
    "SKU": "ALL",
    "OrgName": "ExampleOrg",
    "ClientID": "YourClientID",
    "ClientSecret": "YourClientSecret"
}
```

Now, when you run `.\Install-OktaVerify.ps1`, it will use the values from the `config.json` file, and only prompt for the location of the Okta Verify executable.

1. You can also run the script and pass all the parameters as arguments:

```powershell
.\Install-OktaVerify.ps1 -SKU "ALL" -OrgName "ExampleOrg" -ClientID "YourClientID" -ClientSecret "YourClientSecret"
```

However, this optoin doesn't really save you any time compared to the original executable commands. I include it here for completeness.

In ALL the above options, the `Set-OktaDeviceAccessRegistry` function sets the relevant registry key values for the Okta Device Access (Desktop MFA) feature.