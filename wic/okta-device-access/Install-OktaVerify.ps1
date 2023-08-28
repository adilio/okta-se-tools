<#
.SYNOPSIS
    Installs the Okta Verify executable on Windows with customizable parameters.

.DESCRIPTION
    This function installs the Okta Verify executable on Windows by specifying the SKU, OrgName, ClientID, and ClientSecret.
    It expects these values to be set in a config.json file in the present script directory.

.PARAMETER SKU
    The SKU of the Okta Verify executable. Default value is "ALL".

.NOTES
    Author: @adilio
    Date: July 20, 2023
    Version: 0.3
#>

function Install-OktaVerify {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$SKU = "ALL",
        [Parameter(Mandatory = $false)]
        [string]$CustomDomain
    )

    # Function to read parameter values from the config.json file
    function Get-ConfigParams {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Path
        )

        if (Test-Path $Path) {
            $configContent = Get-Content $Path -Raw | ConvertFrom-Json

            return @{
                SKU          = $configContent.SKU
                OrgName      = $configContent.OrgName
                ClientID     = $configContent.ClientID
                ClientSecret = $configContent.ClientSecret
            }
        }
        else {
            return $null
        }
    }

    # Check if config.json is present and read parameter values from it
    $configFilePath = Join-Path $PSScriptRoot "config.json"
    $configParams = Get-ConfigParams -Path $configFilePath

    if ($configParams) {
        # Use config.json parameters if available
        $SKU = $configParams.SKU
        $OrgName = $configParams.OrgName
        $ClientID = $configParams.ClientID
        $ClientSecret = $configParams.ClientSecret
    }
    else {
        Write-Host "Config file not found or invalid. Make sure the config.json file exists and is properly formatted." -ForegroundColor Yellow

        # Prompt the user for OrgName, ClientID, and ClientSecret if not defined in config.json
        $OrgName = Read-Host "Enter your Okta OrgName (e.g., 'orgname' or 'orgname.okta.com')"
        $ClientID = Read-Host "Enter your Client ID"
        $ClientSecret = Read-Host "Enter your Client Secret"

        # Create a new config object and save it to config.json
        $newConfig = @{
            SKU          = $SKU
            OrgName      = $OrgName
            ClientID     = $ClientID
            ClientSecret = $ClientSecret
        } | ConvertTo-Json -Depth 4

        $newConfig | Out-File -FilePath $configFilePath -Encoding UTF8

        Write-Host "Config.json created with provided parameters." -ForegroundColor Green
    }

    # Check if any of the parameters are empty and prompt the user to enter them
    if (-not $OrgName) {
        $OrgName = Read-Host "Enter your Okta OrgName (e.g., 'orgname' or 'orgname.okta.com')"
    }

    if (-not $ClientID) {
        $ClientID = Read-Host "Enter your Client ID"
    }

    if (-not $ClientSecret) {
        $ClientSecret = Read-Host "Enter your Client Secret"
    }

    # Check if the OrgName is in the "orgname", "orgname.oktapreview.com", or "orgname.okta.com" format
    $baseUrl = $OrgName
    if (-not $CustomDomain -and ($OrgName -notlike "*.okta.com" -and $OrgName -notlike "*.oktapreview.com")) {
        Write-Host "Invalid OrgName format. The format should be 'orgname' or 'orgname.okta.com' or 'orgname.oktapreview.com'." -ForegroundColor Yellow
        return
    }
    if ($CustomDomain) {
        $baseUrl = $OrgName
    }
    else {
        $baseUrl = "$OrgName.okta.com"
    }

    # Prompt for the location of the Okta Verify executable using OpenFileDialog
    $oktaVerifyPath = Get-OktaVerifyPath

    if (-not (Test-Path $oktaVerifyPath)) {
        Write-Host "Invalid OktaVerifyPath specified. The specified path does not exist." -ForegroundColor Yellow
        return
    }

    # Installation logic here, using the provided parameters and the $oktaVerifyPath variable
    Invoke-Expression -Command "$oktaVerifyPath /q SKU=$SKU ORGURL=$baseUrl CLIENTID=$ClientID CLIENTSECRET=$ClientSecret"
    Write-Host "Okta Verify silent install initiated." -ForegroundColor Green

    # Set registry keys for Okta Device Access (Desktop MFA)
    Set-OktaDeviceAccessRegistry
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
        }
        else {
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
    }
    else {
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

    Write-Host "Okta Verify Desktop MFA registry keys set." -ForegroundColor Green
}

# Install Okta Verify silently
Install-OktaVerify

# Comment the above line, and uncomment below, if you are using a custom domain
#Install-OktaVerify -CustomDomain