# PowerShell script to add a user and request a credential for that user

# Hard-coded details further down in script is obtained by querying database
# Group id:
#   select objectID, Name, * from groups
# Credential profile id:
#   select objectID, Name, * from CardProfiles where CurrentVersion=1

# Use PowerShell Module that provide Core API access
Import-Module $PSScriptRoot\Invoke-CoreAPI.psm1 -Force

# Get authentication token
Set-CoreAPIConnection -Server "https://react.domain31.local" -ClientId "get.user" -ClientSecret "07025f77-e54e-46eb-a2eb-079f89586573"

# Create user
## First create user object as a PowerShell object
$userDetails = @{
    employeeId = "123456"
    enabled =  "1"
    contact = @{
      emailAddress = "test.user@intercede.com"
    }
    name = @{
      first = "Sam"
      last = "Jones"
    }
    group = @{
      id = "BBF6B7A9-460C-48FD-AB9E-7DB163A1D65D"
    }
    logonName = "123456"
    roles = @(
      @{
        id = "Applicant"
        name = "Applicant"
        scope = "self"
      }
    )
  }

$user = Invoke-CoreAPIPost -Location "people" -FailureMessage "Unable to create user" -Body $userDetails
# see details with: $user

# Create request for user we just created
$requestDetails = @{
    credProfile = @{
         id = "0A5915F9-B308-4403-9C9F-F2A568E57C9B" 
    }
  }

$request = Invoke-CoreAPIPost -Location "people/$($user.id)/requests" -FailureMessage "Unable to create request" -Body $requestDetails
$request


