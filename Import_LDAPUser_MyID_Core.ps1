<#
.DESCRIPTION
This script shows how a user can be imported from LDAP, using either their LogonName or UniqueID.
A request is then made for the imported user. If the user has already been imported, an additional request is made for them.
Optionally perform a directory sync.
Update the PARAM section to reflect your environment
#>
Param
(
    [string]$ClientId = "myid.mysystem",
    [string]$ClientSecret = "efdc4478-4fda-468b-9d9a-78792c20c683",
    [string]$Server = "https://react.domain31.local",
    [string]$GroupName = "Technology",
    [string]$RoleName = "MyID_PROD_Cardholders",
    [string]$RoleScope = "self",
    [string]$CardProfileName = "PIV_1",
    # Only one of the following Strings need to be completed; UniqueId is from LDAP
    [string]$UniqueId = "619F4E062A51264A9452EF5F18A89506",
    [string]$LogonName = "Alena Castle",

    [switch]$ShowLinks,
    [switch]$DoDirSync
)

Import-Module $PSScriptRoot\Invoke-CoreAPI.psm1 -Force

Set-CoreAPIConnection -Server $Server -ClientId $ClientId -ClientSecret $ClientSecret

################ Get directory
# Assuming only one directory
$dirId = (Invoke-CoreAPIGet -Location "dirs" -FailureMessage "Failure getting directory information").results.id
if (!$dirId) {
    return;
}

################ Get Group
# If groups are not auto-created, we need to set a target group
$groupId = (Invoke-CoreAPIGet -Location "groups?q=$GroupName" -FailureMessage "Unable to get group").results.id
if (!$groupId) {
    return "Unable to find Group '$GroupName'"
}

################ Import User
if (!$UniqueId) {
    if (!$LogonName) {
        return "Provide either a UniqueId or a LogonName"
    }

    $UniqueId = (Invoke-CoreAPIGet -Location "dirs/$dirId/people?ldap.LogonName=$LogonName" -FailureMessage "Unable to find user in LDAP").results.id
    if (!$UniqueId) {
        return "Unable to find user '$LogonName' in LDAP"
    }
}

$body = @{
    group = @{
        id   = $groupId
        name = $GroupName
    }
    roles = @(
        @{
            id    = $RoleName
            name  = $RoleName
            scope = $RoleScope
        }
    )
}

$userId = (Invoke-CoreAPIPatch -Location "dirs/$dirId/people/$UniqueId" -FailureMessage "Unable to import user" -Body $body).id
if (!$userId) {
    return
}

################ Create request
$credProfileId = (Invoke-CoreAPIGet -Location "credprofiles?q=$CardProfileName" -FailureMessage "Unable to get credential profile").results.id
if (!$credProfileId) {
    return "Unable to find Credential profile '$CardProfileName'"
}

$body = @{
    credProfile = @{
        id = $credProfileId
    }
}

$response = Invoke-CoreAPIPost -Location "people/$userId/requests" -FailureMessage "Unable to create request for user" -Body $body
if ($response) {
    "Request created for user."

    if (!$ShowLinks) {
        $response.PSObject.Properties.Remove('links')
    }
    ConvertTo-Json $response -Depth 6
}

################ Directory Sync (optional)
if ($DoDirSync) {
    $dirSync = Invoke-CoreAPIPost -Location "people/$userId/DirSync" -FailureMessage "Unable to import user" -Body $body
    @{
        "account" = $dirSync.account
        "group"   = $dirSync.group
        "roles"   = $dirSync.roles
    }
}
