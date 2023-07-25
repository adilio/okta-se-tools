<#
.SYNOPSIS
    Installs the Okta Verify executable on Windows with customizable parameters.

.DESCRIPTION
    This function installs the Okta Verify executable on Windows by specifying the SKU, OrgName, ClientID, and ClientSecret.
    Additionally, it prompts the user to browse and select the location of the Okta Verify executable.

.PARAMETER SKU
    The SKU of the Okta Verify executable. Default value is "ALL".

.PARAMETER OrgName
    The organization name associated with Okta in the format "orgname" or "orgname.okta.com".

.PARAMETER ClientID
    The client ID for accessing Okta APIs.

.PARAMETER ClientSecret
    The client secret for accessing Okta APIs as a secure string.

.EXAMPLE
    Install-OktaVerify -SKU "ALL" -OrgName "ExampleOrg" -ClientID "YourClientID" -ClientSecret (ConvertTo-SecureString -String "YourClientSecret" -AsPlainText -Force)

.EXAMPLE
    Install-OktaVerify -OrgName "ExampleOrg.okta.com" -ClientID "YourClientID" -ClientSecret (Read-Host "Enter your Client Secret" -AsSecureString)

.NOTES
    Author: @adilio
    Date: July 20, 2023
    Version: 1.0
#>
function Install-OktaVerify {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$SKU = "ALL",

        [Parameter(Mandatory = $false)]
        [string]$OrgName,

        [Parameter(Mandatory = $false)]
        [string]$ClientID,

        [Parameter(Mandatory = $false)]
        [securestring]$ClientSecret
    )

    # Function to read parameter values from the config.json file
    function Get-ConfigParams {
        param (
            [Parameter]
            [string]$Path
        )

        if (Test-Path $Path) {
            $configContent = Get-Content $Path -Raw | ConvertFrom-Json

            return @{
                SKU = $configContent.SKU
                OrgName = $configContent.OrgName
                ClientID = $configContent.ClientID
                ClientSecret = $configContent.ClientSecret | ConvertTo-SecureString
            }
        } else {
            return $null
        }
    }

    # Check if config.json is present and read parameter values from it
    $configParams = Get-ConfigParams -Path (Join-Path $PSScriptRoot "config.json")

    if ($configParams) {
        # Use config.json parameters if available
        $SKU = $configParams.SKU
        $OrgName = $configParams.OrgName
        $ClientID = $configParams.ClientID
        $ClientSecret = $configParams.ClientSecret
    }

    # Prompt for OrgName, ClientID, and ClientSecret if not provided as parameters
    if (-not $OrgName) {
        $OrgName = Read-Host "Enter your Okta OrgName (e.g., 'orgname' or 'orgname.okta.com')"
    }

    if (-not $ClientID) {
        $ClientID = Read-Host "Enter your Client ID"
    }

    if (-not $ClientSecret) {
        $ClientSecret = Read-Host "Enter your Client Secret" -AsSecureString
    }
    
    $plainTextClientSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ClientSecret))

    # Check if the OrgName is in the "orgname" or "orgname.okta.com" format
    $baseUrl = $OrgName
    if ($OrgName -notlike "*.okta.com") {
        $baseUrl = "$OrgName.okta.com"
    }

    if ($oktaVerifyPath) {
        # Installation logic here, using the provided parameters and the $oktaVerifyPath variable
        Invoke-Expression -Command "$oktaVerifyPath /q SKU=$SKU ORGURL=$baseUrl CLIENTID=$ClientID CLIENTSECRET=$plainTextClientSecret"
        Write-Host "Okta Verify silent install initiated successfully." -ForegroundColor Green
    }
}

# Displays an OpenFileDialog to prompt the user to browse and select the Okta Verify executable.
function Get-OktaVerifyPath {
    [CmdletBinding()]
    param ()

    # Define the config.json file path
    $configFilePath = Join-Path $PSScriptRoot "config.json"

    if (Test-Path $configFilePath) {
        # Read config.json and check if OktaVerifyPath is defined
        $configContent = Get-Content $configFilePath -Raw | ConvertFrom-Json
        $oktaVerifyPathOverride = $configContent.OktaVerifyPath

        if ($oktaVerifyPathOverride -and (Test-Path $oktaVerifyPathOverride -PathType Leaf)) {
            # If OktaVerifyPath is defined and exists, use it directly
            return $oktaVerifyPathOverride
        } else {
            Write-Host "Invalid OktaVerifyPath specified in the config.json file. Falling back to manual selection." -ForegroundColor Yellow
        }
    }

    # Add type for the System.Windows.Forms assembly
    Add-Type -AssemblyName System.Windows.Forms

    # Create OpenFileDialog object
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog

    # Set properties of the OpenFileDialog
    $openFileDialog.Filter = "Executable files (*.exe)|*.exe"
    $openFileDialog.Title = "Select the Okta Verify executable"

    # Show the OpenFileDialog and wait for the user's selection
    if ($openFileDialog.ShowDialog() -eq 'OK') {
        # Return the full file path of the selected executable
        return $openFileDialog.FileName
    } else {
        # If the user cancels the OpenFileDialog, display a message and return $null
        Write-Host "Okta Verify installation cancelled." -ForegroundColor Yellow
        return $null
    }
}

# Sets relevant registry key values for Okta Device Access 
function Set-OktaDeviceAccessRegistry {
    # Define the registry path
    $registryPath = "HKLM:\SOFTWARE\Policies\Okta\Okta Device Access"

    # Check if the registry path exists, if not, create it
    if (-Not (Test-Path $registryPath)) {
        New-Item -Path $registryPath -Force | Out-Null
    }

    Set-ItemProperty -Path $registryPath -Name "MfaRequiredList" -Value "*" -Type MultiString
    Set-ItemProperty -Path $registryPath -Name "MaxLoginsWithoutEnrolledFactors" -Value 50
    Set-ItemProperty -Path $registryPath -Name "MaxLoginsWithOfflineFactor" -Value 50
    Set-ItemProperty -Path $registryPath -Name "MFAGracePeriodInMinutes" -Value 60

    Write-Host "Okta Verify Desktop MFA registry keys successfully." -ForegroundColor Green
    # Output the updated registry values
    Get-ItemProperty -Path $registryPath
}

# Prompt for the location of the Okta Verify executable using OpenFileDialog
$oktaVerifyPath = Get-OktaVerifyPath

# Install Okta Verify silently
Install-OktaVerify

# Set registry keys for Okta Device Access (Desktop MFA)
Set-OktaDeviceAccessRegistry