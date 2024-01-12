<#
.SYNOPSIS
    Adds permissions to the Okta AD Agent service account on Windows with customizable parameters.

.DESCRIPTION
    This function runs powershell commands to add permissions to the Okta AD Agent service account
    that you specify. It will add permissions in up to 2 categories depending on parameter values.
	
	Flags for permissions: 
		-p - Manage Passwords and Unlock status ONLY
		-a - All - Provision users, groups AND manage password/unlock permissions

		If groups and users are allowed to be created, then it is necessary to add permissions to attributes.
		The list of user attributes may be different depending on your deployment of Okta and AD.
		The attributes can either be discovered from Okta, or provided in a local config.json file.
			- If discovery is required, you need to provide the Okta URL and an API token with sufficient Okta admin 
			  permissions to be able to read apps and app schemas.
			- If providing a file, enter the attributes in a config.json file. A sample is provided.
		
    ServiceAccount: 
        Provide the domain logon of the service account. e.g. DOMAIN\service.acct  
    
	OU: 
		-OU <OU>
			Provide the OU where the permissions apply
			The format is LDAP. For example: OU=targetOU,DC=domain
		-i
			Include all sub-OUs iteratively (for user and group creation)

		If you would like to add permissions to multiple OUs (not under the same OU) then run the command
		multiple times.




.NOTES
    Author: @skeleher
    Date: January 12, 2024
    Version: 0.1
#>

# Check for various flags
$permissionsPresent = $false
$groupsUsers = $false
$passwords = $false

foreach ($arg in $args) {
	if ($arg -eq '-p') {
		$permissionsPresent = $true
		$passwords = $true
        break
    }
	if ($arg -eq '-a') {
		$permissionsPresent = $true
		$groupsUsers = $true
		$passwords = $true
        break
    }
}

if (-not $permissionsPresent) {
	$permission = Read-Host "What permissions would you like to grant? (p) Password/unlock ONLY, (a) all provisioning and password/unlock [Default is ALL]"
	if (($permission -eq "a") -or (-not $permission)) {
		$groupsUsers = $true
		$passwords = $true
	}
	else {
		$passwords = $true
	}
}

Write-Host "Permissions are: G: $groupsUsers P: $passwords"

# Prompt the user for input

$serviceAcct = Read-Host "Enter the service account name (sAMAccount format)"
$adOU = Read-Host "Enter the Active Directory OU, in LDAP format"
$subOUsInput = Read-Host "Inherit permission to sub-OUs? (y)es/(n)o, default is yes)"

$compInfo = Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem
$curDomain = $compInfo.domain
			
# Always add the service account user to the Pre-Windows 2000 Compatible Access group
$pw2K = "Pre-Windows 2000 Compatible Access"
Add-ADGroupMember -Identity $pw2K -Members $serviceAcct
Write-Host "$serviceAcct added to the group $pw2K"

function AddUserCreateAndAttributesPrivileges {
	param (
		[string]$domainOU,
		[string]$serviceAccount,
		[string[]]$attributes,
		[bool]$inheritOUs
	)
	
	$inherit = ""
	if ($inheritOUs) {
		$inherit = "/I:T"
	}
	
	# Add permission to Create (not delete) users within the specified OU
    dsacls "$domainOU" $inherit /G "${serviceAccount}:CC;user"
	# Catch error and stop script
	
	foreach ($attr in $attributes) {
		# Add permissions to write to user properties within the specified OU
		# Note that for user attributes, /I:S is the only inheritence type accepted
		dsacls "$domainOU" /I:S /G "${serviceAccount}:WP;${attr};user"
		# Catch error and stop script
	}
}

function AddPasswordManagementPrivileges {
	param (
		[string]$domainOU,
		[string]$serviceAccount
	)
	
	## Note that for user properties and reset password, /I:S is the only allowable option for inheritance
	
	Write-Debug "Calling dsacls $domainOU $inherit /G ${serviceAccount}:CA;Reset Password;User"
	# Add permission to control access to reset the password of a user within the specified OU
	dsacls "$domainOU" /I:S /G "${serviceAccount}:CA;Reset Password;user"

	# Add permission to write to the pwdLastSet property within the specified OU
	dsacls "$domainOU" /I:S /G "${serviceAccount}:WP;pwdLastSet;user"

	# Add permission to write to the lockoutTime property within the specified OU
	dsacls "$domainOU" /I:S /G "${serviceAccount}:WP;lockoutTime;user"

	# Todo: Catch errors and stop script

}

function AddGroupPrivileges {
	param (
		[string]$domainOU,
		[string]$serviceAccount,
		[bool]$inheritOUs
	)
	
	$inherit = ""
	if ($inheritOUs) {
		$inherit = "/I:T"
	}
	
	# Add permissions to Create and Delete groups within the specified OU
	dsacls "$domainOU" $inherit /G "${serviceAccount}:CCDC;group"
	# Catch error and stop script
	
	$groupAttrs = @('sAMAccountName', 'description', 'groupType', 'member', 'cn', 'name')
	
	foreach ($attr in $groupAttrs) {
		# Add permissions to write to group properties within the specified OU
		dsacls "$domainOU" /I:S /G "${serviceAccount}:WP;${attr};group"
		# Catch error and stop script
	}
}

# Function to make an HTTP GET request with authorization header
function Invoke-WebRequestWithAuthorization {
	param (
		[string]$url,
		[string]$secretKey
	)

	$headers = @{
		Authorization = "SSWS $secretKey"
		'Content-Type'  = 'application/json'
	}
	
	
	# Write-Output "DEBUG: Invoke method - URL is: $url"
	# Retrieve the app ID for the Directory
	$response = Invoke-WebRequest -Uri $url -Headers $headers -Method Get
	
	return $response
}

# Set default value for sub-OUs if not provided
[bool] $subOUs = $false;

if (-not $subOUsInput) {
    $subOUs = $true
}
elseif (($subOUsInput -eq "y") -or ($subOUsInput -eq "Y")) {
	$subOUs = $true;
}

if ($passwords) {
	Write-Debug "Calling AddPasswordManagementPrivileges -domainOU $adOU -serviceAccount $serviceAcct"
	AddPasswordManagementPrivileges -domainOU $adOU -serviceAccount $serviceAcct
}

if ($groupsUsers) {

	$webUrl = Read-Host "Enter the Okta URL (e.g. mydomain.okta.com)"
	$secretKey = Read-Host "Enter the authorization secret key"

	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

	$fullUrl = "https://$webUrl/api/v1/apps?filter=name+eq+%22active_directory%22"
	Write-Host "DEBUG: Full URL is: $fullUrl"
		
	# Make HTTP GET request to get the list of applications
	$response1 = Invoke-WebRequestWithAuthorization -url $fullUrl -secretKey $secretKey

	# Parse and output each value in the array
	$jsonObj = $response1.Content | ConvertFrom-Json

	if ($jsonObj -is [array]) {
		$len = $jsonObj.length
		if ($len -ge 1) {

			#$curDomain = "Adilio"
			Write-Host "Domain name is $curDomain"
			$appId = ""
			
			if ($len -gt 1) {
				$foundDomain = $false;
				$counter = 0
				foreach ($item in $jsonObj) {
					$id = $item.id
					$name = $item.name
					$label = $item.label

					Write-Debug "Item: ID=$id, Name=$name, Label=$label"
					if ($label -eq $curDomain) {
						$foundDomain = $true
						break;
					}
					$counter++
				}
				if ($foundDomain) {
					Write-Host "Using $curDomain, found at item $counter"
				}
				else {
					# Prompt the user to select a domain from the list.
					$selectCtr = 0;
					foreach ($item in $jsonObj) {
						$selectCtr++
						$label = $item.label
						Write-Host "$selectCtr. $label"
					}
					$selectedItem = Read-Host "Domain not found. Please select from integrated AD domains in Okta, or Enter to cancel."
					if (($selectedItem -le $jsonObj.length) -and ($selectedItem -gt 0)) {
						$counter = $selectedItem - 1
						$item = $jsonObj[$counter].label
						Write-Host "You selected item $selectedItem. $item"
					}
					else {
						Write-Host "Cancelled operation."
						exit
					}
				}
				# If we are running at this point, then the domain is the item at # counter.
				# Read the Schema for this app.
				$appId = $jsonObj[$counter].id
				
			}
			else {
				# Only one AD domain. Confirm that the domain matches this domain.
				$oktaADDomain = $jsonObj[0].label
				if ($oktaADDomain -ne $curDomain) {
					$resp = Read-Host "Current domain $curDomain does not match Okta integrated AD domain $oktaADDomain. Continue? [y/n]"
					if ($resp -ne 'y') {
						Write-Host "Cancelled operation."
						exit
					}
				}
			}
			
			$fullUrl = "https://$webUrl/api/v1/meta/schemas/apps/$appId/default"

			# Make HTTP Get request to get the list of attributes in the schema of the directory
			$response = Invoke-WebRequestWithAuthorization -url $fullUrl -secretKey $secretKey

			$jsonObj2 = $response.Content | ConvertFrom-Json
			
			Write-Debug "Found schema object."
			Write-Debug $jsonObj2
			
			$allADAttrNames = @()
			
			# Get all the base attributes - first the Okta labels, then find the AD Names
			$baseAttributeNames = @()
			if ($prop = $jsonObj2.definitions.PSObject.Properties.Item('base')) {
				$baseAttributeNames = $jsonObj2.definitions.base.properties.psobject.Properties.Name
				# Got the Okta labels, now get the AD names from the title property			
				foreach ($nameKey in $baseAttributeNames) {
					# Ignore any SYSTEM scoped properties - these are managed by the Okta integration 
					if ($jsonObj2.definitions.base.properties.($nameKey).scope -ne "SYSTEM") {
						$allADAttrNames+= $jsonObj2.definitions.base.properties.($nameKey).title
					}
					else {
						$title = $jsonObj2.definitions.base.properties.($nameKey).title
						Write-Debug "Not including SYSTEM scoped property $title"
					}
				}
			}
			else {
				Write-Host "No base property"
			}
			
			$customAttributeNames = @()	
			# Get all the custom attributes - first the Okta labels, then find the AD Names
			if ($prop = $jsonObj2.definitions.PSObject.Properties.Item('custom')) {
				$customAttributeNames = $jsonObj2.definitions.custom.properties.psobject.Properties.Name
				# Got the Okta labels, now get the AD names from the title property
				foreach ($nameKey in $customAttributeNames) {
					$allADAttrNames+= $jsonObj2.definitions.custom.properties.($nameKey).title
				}
			}
			$outarr = $baseAttributeNames -join ','
			Write-Debug "Base Attributes: $outarr"

			$outarr = $customAttributeNames -join ','
			Write-Debug "Custom Attributes: $outarr"
			
			$outarr = $allADAttrNames -join ','
			Write-Debug "All AD Names: $outarr"

			# Only continue if we found attributes.
			if ($allADAttrNames.length -gt 0) {
				# Add User permissions
				AddUserCreateAndAttributesPrivileges -domainOU $adOU -serviceAccount $serviceAcct -attributes $allADAttrNames -inheritOUs $subOUs
				# Next: Do the same for Groups
				AddGroupPrivileges -domainOU $adOU -serviceAccount $serviceAcct -inheritOUs $subOUs
			}			
		}
		else {
			Write-Host "Error: There are no AD Domains integrated with Okta org $webUrl."
		}
		
	} else {
		Write-Host "Unexpected response format. Expected an array of strings in JSON."
		Write-Host $jsonObj
	}
}