# PowerShell script to find a a device owned by a user and cancel it
# An alternative to FindUserCancelDevice.ps1

# Use PowerShell Module that provide Core API access
Import-Module $PSScriptRoot\Invoke-CoreAPI.psm1 -Force

# Get authentication token
Set-CoreAPIConnection -Server "https://react.domain31.local" -ClientId "get.user" -ClientSecret "07025f77-e54e-46eb-a2eb-079f89586573"

# Find devices owned by specific user
$devices = Invoke-CoreAPIGet -Location "devices?owner=123456"
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