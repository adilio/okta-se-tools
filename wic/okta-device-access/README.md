# Install-OktaVerify.ps1

## Description

The `Install-OktaVerify.ps1` script installs the Okta Verify executable on Windows with customizable parameters, including:
- SKU
- OrgName
- ClientID
- ClientSecret
- OktaVerifyPath

## Downloading

You can download the Okta Verify executable from your Okta Admin dashboard Under `Settings` > `Downloads` (from the left sidebar). You can then download this script locally using this one-liner in a PowerShell Admin console:

```powershell
Invoke-RestMethod https://tinyurl.com/ov-install -OutFile Install-OktaVerify.ps1
```

## Running

You can use this script multiple ways.

1. You can just run the script:

```powershell
.\Install-OktaVerify.ps1
```

This will prompt you for the file location of the Okta Verify executable (a file explorer window will open), and prompt you for the `OrgName`, `ClientID`, and `ClientSecret` values inline in the terminal.

2. You can alternatively rename the `config.json.example` to `config.json`, and populate the values of the parameters:

```json
{
    "SKU": "ALL",
    "OrgName": "ExampleOrg",
    "ClientID": "YourClientID",
    "ClientSecret": "YourClientSecret",
    "OktaVerifyPath": "C:\\Path\\To\\OktaVerify.exe"
}
```

Now, when you run `.\Install-OktaVerify.ps1`, it will use the values from the `config.json` file.

In ALL the above options, the `Set-OktaDeviceAccessRegistry` function sets the relevant registry key values for the Okta Device Access (Desktop MFA) feature.