# PowerShell script to find a user and cancel a device issued to them

# Use PowerShell Module that provide Core API access
Import-Module $PSScriptRoot\Invoke-CoreAPI.psm1 -Force

# Get authentication token
Set-CoreAPIConnection -Server "https://react.domain31.local" -ClientId "get.user" -ClientSecret "07025f77-e54e-46eb-a2eb-079f89586573"

# Find user with specific employeeId
$users = Invoke-CoreAPIGet -Location "people?employeeId=123456"
# see details with:
#$users.results

# Find devices issued to user
$devices = Invoke-CoreAPIGet -Location "people/$($users.results.id)/devices"
# see details with: 
#$devices.results

# Remote cancel device
$cancelReason = @{
    reason = @{
        statusMappingId = 1 
    }
 }
$result = Invoke-CoreAPIPost -Location "devices/$($devices.results.id)/cancel" -FailureMessage "Unable to cancel device" -Body $cancelReason
$result