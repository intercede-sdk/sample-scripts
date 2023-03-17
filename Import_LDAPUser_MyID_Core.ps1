<#
.SYNOPSIS
Import user from LDAP and request a credential for them.

.DESCRIPTION
Import a user from LDAP, using either their LogonName or UniqueID.
A credential request is then made for the imported user. If the user has already been imported, an additional request is made for them.
Optionally perform a directory sync.

.PARAMETER ClientId
The client identifier, e.g. myid.mysystem

.PARAMETER ClientSecret
The client secret, e.g. efdc4478-4fda-468b-9d9a-78792c20c683

.PARAMETER Server
The MyID web server hosting the MyID Core API and MyID web.oauth2 web service

.PARAMETER GroupName
The group that the imported user will be added to

.PARAMETER RoleName
The MyID role that the imported user will be given

.PARAMETER RoleScope
The scope of the MyID role given to the user. One of: self, department, division, all

.PARAMETER CardProfileName
The credential profile used when requesting a credential for the imported user

.PARAMETER UniqueId
The LDAP UniqueID of the user being imported. Set this or LogonName

.PARAMETER LogonName
The LDAP LogonName of the user being imported. Set this or UniqueID

.PARAMETER ShowLinks
Set this to show HATEOAS links related to the request generated for the imported user

.PARAMETER DoDirSync
Set this to perform a Directory Synchronisation after importing the user.

.EXAMPLE 
.\Import_LDAPUser_MyID_Core.ps1 -ClientId myid.mysystem -ClientSecret efdc4478-4fda-468b-9d9a-78792c20c683 -LogonName "Alena Castle"

.EXAMPLE
.\Import_LDAPUser_MyID_Core.ps1 -ClientId myid.mysystem -ClientSecret efdc4478-4fda-468b-9d9a-78792c20c683 -UniqueId "619F4E062A51264A9452EF5F18A89506"

.EXAMPLE
.\Import_LDAPUser_MyID_Core.ps1 -ClientId myid.mysystem -ClientSecret efdc4478-4fda-468b-9d9a-78792c20c683 -UniqueId "619F4E062A51264A9452EF5F18A89506" -DoDirSync

#>
Param
(
    [Parameter(Mandatory)]
    [string]$ClientId,
    [Parameter(Mandatory)]
    [string]$ClientSecret,

    [string]$Server = "https://react.domain31.local",
    [string]$GroupName = "Tech",
    [string]$RoleName = "Cardholder",

    [ValidateSet('self', 'department', 'division', 'all')]
    [string]$RoleScope = "self",

    [string]$CardProfileName = "PIV_1",
    # Only one of the following Strings need to be completed; UniqueId is from LDAP
    [string]$UniqueId = "619F4E062A51264A9452EF5F18A89506",
    [string]$LogonName = "Alena Castle",

    [switch]$ShowLinks,
    [switch]$DoDirSync
)

if ($UniqueId && $LogonName) {
    return "Please provide either a UniqueID or a LogonName but not both"
}

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
