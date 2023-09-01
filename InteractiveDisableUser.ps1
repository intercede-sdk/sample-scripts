# PowerShell script to find a user and then disable them interactively

# In order to disable a person in the Core API, the role used by the
# user account used in the client credential grant needs to have "Edit User" access


# Use PowerShell Module that provide Core API access
Import-Module $PSScriptRoot\Invoke-CoreAPI.psm1 -Force

# Get authentication token
Set-CoreAPIConnection -Server "https://react.domain31.local" -ClientId "get.user" -ClientSecret "07025f77-e54e-46eb-a2eb-079f89586573"

#Enter surname of user we wish to find
$lastName = Read-Host "Enter first few characters of last name"

#Perform search
$users = Invoke-CoreAPIGet -Location "people?name.last=$($lastName)*"
# see details with:
$users.results

#Enter surname of user we wish to find
$id = Read-Host "Enter 'id' of user to disable"

# Exit early if user is not found or already disabled
$selectedUser = $users.results | Where-Object { $_.id -eq $id }
if(!$selectedUser){
    return "Please check id provided and try again"
}

if ( $selectedUser.Enabled -eq "No") {
    Write-Host "Selected user is already disabled"
    return $selectedUser
}

#Show reasons for disabling user
#Disable person is operation 100113 (can we simplify this?)
$possibleReasons = Invoke-CoreAPIGet -Location "people/$($id)/statusMappings?op=100113"
$possibleReasons.results

#Choose reason to disable
$reason = Read-Host "Enter 'id' of reason"
$notes = Read-Host "(Optional) Provide notes to be included when disabling user"

#set up body for cancellation
$cancelReason = @{
    reason = @{
        statusMappingId = $reason
        description = $notes
    }
}

# Perform disable operations
$response = Invoke-CoreAPIPost -Location "people/$($id)/disable" -Body $cancelReason -FailureMessage "Unable to disable user"
# Remove Links from reponse (these are the operations that can be performed on the user)
$response.PSObject.Properties.Remove('links')
ConvertTo-Json $response -Depth 6