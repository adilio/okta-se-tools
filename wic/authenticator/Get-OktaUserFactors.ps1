function Get-OktaUserFactors {
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

  # Define the API endpoints for Users and Factors
  $UsersApiEndpoint = "$OrgUrl/api/v1/users"
  $FactorsApiEndpoint = "$OrgUrl/api/v1/users/{userId}/factors"

  # Create a header with the API key
  $headers = @{
      'Authorization' = "SSWS $ApiToken"
  }

  # Send a GET request to the Users API to get all users
  try {
      $usersResponse = Invoke-RestMethod -Uri $UsersApiEndpoint -Headers $headers -Method Get

      # Check if the request was successful
      if ($usersResponse) {
          # Initialize an array to store user factors
          $userFactors = @()

          # Loop through the users and retrieve their factors
          foreach ($user in $usersResponse) {
              $userId = $user.id
              $userName = $user.profile.login
              $firstName = $user.profile.firstName
              $lastName = $user.profile.lastName

              # Send a GET request to retrieve user's enrolled factors
              $factorsResponse = Invoke-RestMethod -Uri ($FactorsApiEndpoint -replace "{userId}", $userId) -Headers $headers -Method Get

              if ($factorsResponse) {
                  # Replace 'signed_nonce' with 'Okta Verify (FastPass)' and 'push' with 'OV Mobile (Push Notification)' in enrolled factors
                  $enrolledFactors = $factorsResponse | ForEach-Object {
                      if ($_.factorType -eq 'signed_nonce') {
                          $_.factorType = 'Okta Verify (FastPass)'
                      } elseif ($_.factorType -eq 'push') {
                          $_.factorType = 'OV Mobile (Push Notification)'
                      }
                      $_.factorType
                  }

                  # Create a custom object for the user with their enrolled factors
                  $userFactors += [PSCustomObject]@{
                      UserId = $userId
                      UserName = $userName
                      FirstName = $firstName
                      LastName = $lastName
                      EnrolledFactors = $enrolledFactors -join ', '
                  }
              }
          }

          # Output the array of custom objects
          $userFactors
      } else {
          Write-Host "Error: Failed to retrieve user data."
      }
  } catch {
      Write-Host "Error: $_"
  }
}

# Uncomment and use the following line to call the function with parameters or use environment variables.
# Get-OktaUserFactors -ApiToken "YOUR_API_TOKEN" -OrgName "YOUR_ORG_NAME"
