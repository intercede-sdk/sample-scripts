Param
(
    [string]$authUrl = "https://react.domain31.local/web.oauth2/connect/token",
    [string]$apiUrl = "https://react.domain31.local/rest.core/api",
    [string]$clientId = "client id",
    [string]$clientSecret = "client secret",
    [string]$groupName = "Technology",
    [string]$roleName = "MyID_PROD_Cardholders",
    [string]$roleScope = "self",
    [string]$credProfileName = "TMO_1",
    [string]$uniqueId,
    [string]$logonName
)

Function Invoke-CoreAPI-Get {
    Param
    (
        [Parameter(Mandatory)]
        [string] $Location,
        [string] $FailureMessage = ""
    )

    try {
        $apiResponse = Invoke-WebRequest -Uri "$apiUrl/$Location" -Headers $apiHeaders
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
        $apiResponse = Invoke-WebRequest -Uri "$apiUrl/$Location" -Headers $apiHeaders -Method $Method -Body ($Body | ConvertTo-Json)
        return ConvertFrom-Json $apiResponse.Content
    }
    catch {
        Write-Host "ERROR - $FailureMessage. $_"
    }
}

################ Auth
$headers = @{
    'Authorization' = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${clientId}:${clientSecret}"))
}

try {
    $tokenResponse = Invoke-WebRequest -Uri $authUrl -Method Post -Headers $headers  -Body "grant_type=client_credentials"
    $tokenResponseJSON = ConvertFrom-Json $tokenResponse.Content

    $token = $tokenResponseJSON.access_token 
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
$dirId = (Invoke-CoreAPI-Get -Location "dirs" -FailureMessage "").results.id

################ Get Group
# If groups are not auto-created, we need to set a target group
$groupId = (Invoke-CoreAPI-Get -Location "groups?q=$groupName" -FailureMessage "Unable to get group").results.id
if (!$groupId) {
    return "Unable to find Group '$groupName'"
}

################ Import User
if (!$uniqueId) {
    if (!$logonName) {
        return "Provide either a uniqueId or a logonName"
    }

    $uniqueId = (Invoke-CoreAPI-Get -Location "dirs/$dirId/people?ldap.logonName=$logonName" -FailureMessage "Unable to find user in LDAP").results.id
    if (!$uniqueId) {
        return "Unable to find user in LDAP"
    }
}

$body = @{
    group = @{
        id   = $groupId
        name = $groupName
    }
    roles = @(
        @{
            id    = $roleName
            name  = $roleName
            scope = $roleScope
        }
    )
}

$userId = (Invoke-CoreAPI-Method -Location "dirs/$dirId/people/$uniqueId" -FailureMessage "Unable to import user" -Body $body -Method "Patch").id
if (!$userId) {
    return
}

################ Create request
$credProfileId = (Invoke-CoreAPI-Get -Location "credprofiles?q=$credProfileName" -FailureMessage "Unable to get credential profile").results.id
if (!$credProfileId) {
    return "Unable to find Credential profile '$credProfileName'"
}

$body = @{
    credProfile = @{
        id = $credProfileId
    }
}

$response = Invoke-CoreAPI-Method -Location "people/$userId/requests" -FailureMessage "Unable to create request for user" -Body $body
if ($response) {
    "Request created for user."
    $response
}
