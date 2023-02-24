Param
(
    [Parameter(Mandatory)]
    [string]$ClientId,
    [Parameter(Mandatory)]
    [string]$ClientSecret,

    [string]$AuthUrl = "https://react.domain31.local/web.oauth2/connect/token",
    [string]$ApiUrl = "https://react.domain31.local/rest.core/api",
    [string]$GroupName = "Technology",
    [string]$RoleName = "MyID_PROD_Cardholders",
    [string]$RoleScope = "self",
    [string]$CredProfileName = "TMO_1",
    [string]$UniqueId,
    [string]$LogonName,

    [switch]$ShowLinks,
    [switch]$DoDirSync
)

Function Invoke-CoreAPI-Get {
    Param
    (
        [Parameter(Mandatory)]
        [string] $Location,
        [string] $FailureMessage = ""
    )

    try {
        $apiResponse = Invoke-WebRequest -Uri "$ApiUrl/$Location" -Headers $apiHeaders
        return ConvertFrom-Json $apiResponse.Content
    }
    catch {
        Write-Host "ERROR - $FailureMessage. $_"
    }
}

Function Invoke-CoreAPI-Method {
    Param
    (
        [Parameter(Mandatory)]
        [string] $Location,
        [string] $FailureMessage = "",

        [Parameter(Mandatory)]
        [object] $Body,
        [string] $Method = "Post"
    )

    try {
        $apiResponse = Invoke-WebRequest -Uri "$ApiUrl/$Location" -Headers $apiHeaders -Method $Method -Body ($Body | ConvertTo-Json)
        return ConvertFrom-Json $apiResponse.Content
    }
    catch {
        Write-Host "ERROR - $FailureMessage. $_"
    }
}

################ Auth
$headers = @{
    'Authorization' = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${ClientId}:${ClientSecret}"))
}

try {
    $tokenResponseJSON = Invoke-WebRequest -Uri $AuthUrl -Method Post -Headers $headers  -Body "grant_type=client_credentials"
    $tokenResponse = ConvertFrom-Json $tokenResponseJSON.Content

    $token = $tokenResponse.access_token 
}
catch {
    return "ERROR - Unable to get an access token. $_"
}

# common header for API calls
$apiHeaders = @{
    'Authorization' = "Bearer $token"
    'Content-type'  = 'application/json'
}

################ Get directory
# Assuming only one directory
$dirId = (Invoke-CoreAPI-Get -Location "dirs" -FailureMessage "Failure getting directory information").results.id
if (!$dirId) {
    return;
}

################ Get Group
# If groups are not auto-created, we need to set a target group
$groupId = (Invoke-CoreAPI-Get -Location "groups?q=$GroupName" -FailureMessage "Unable to get group").results.id
if (!$groupId) {
    return "Unable to find Group '$GroupName'"
}

################ Import User
if (!$UniqueId) {
    if (!$LogonName) {
        return "Provide either a UniqueId or a LogonName"
    }

    $UniqueId = (Invoke-CoreAPI-Get -Location "dirs/$dirId/people?ldap.LogonName=$LogonName" -FailureMessage "Unable to find user in LDAP").results.id
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

$userId = (Invoke-CoreAPI-Method -Location "dirs/$dirId/people/$UniqueId" -FailureMessage "Unable to import user" -Body $body -Method "Patch").id
if (!$userId) {
    return
}

################ Create request
$credProfileId = (Invoke-CoreAPI-Get -Location "credprofiles?q=$CredProfileName" -FailureMessage "Unable to get credential profile").results.id
if (!$credProfileId) {
    return "Unable to find Credential profile '$CredProfileName'"
}

$body = @{
    credProfile = @{
        id = $credProfileId
    }
}

$response = Invoke-CoreAPI-Method -Location "people/$userId/requests" -FailureMessage "Unable to create request for user" -Body $body
if ($response) {
    "Request created for user."

    if (!$ShowLinks) {
        $response.PSObject.Properties.Remove('links')
    }
    ConvertTo-Json $response -Depth 6
}

################ Directory Sync (optional)
if ($DoDirSync) {
    $dirSync = Invoke-CoreAPI-Method -Location "people/$userId/DirSync" -FailureMessage "Unable to import user" -Body $body
    @{
        "account" = $dirSync.account
        "group"   = $dirSync.group
        "roles"   = $dirSync.roles
    }
}
