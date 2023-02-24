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
    [string]$Domain = "domain31",
    [string]$CredProfileName = "TMO_1",
    
    [switch]$CanUseExistingUser,
    [switch]$ShowLinks
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

Function Invoke-CoreAPI-Post {
    Param
    (
        [Parameter(Mandatory)]
        [string] $Location,
        [string] $FailureMessage = "",

        [Parameter(Mandatory)]
        [PSCustomObject] $Body
    )

    try {
        $apiResponse = Invoke-WebRequest -Uri "$ApiUrl/$Location" -Headers $apiHeaders -Method Post -Body ($Body | ConvertTo-Json)
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
    $tokenResponse = Invoke-WebRequest -Uri $AuthUrl -Method Post -Headers $headers  -Body "grant_type=client_credentials"
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

################ Get Group
# Make sure group we are trying to set exists
# We could add group through API, but it seems more sensible that Config should be done ahead
$groupId = (Invoke-CoreAPI-Get -Location "groups?q=$GroupName" -FailureMessage "Unable to get group").results.id
if (!$groupId) {
    return "Unable to find Group '$GroupName'"
}

################ Get Role
# Make sure role we are trying to set exists
# Unfortunately this API endpoint doesn't filter on name
$roleId = (Invoke-CoreAPI-Get -Location "roles" -FailureMessage "Unable to get role").results | Where-Object id -eq $RoleName
if (!$roleId) {
    return "Unable to find Role '$RoleName'"
}

################ Add/Get User
Import-CSV -Path .\ACastle2.csv -Delimiter ';' |
ForEach-Object {
    $logonName = $_.SAMAccountName
    $body = @{
        name      = @{
            first = $_.GivenName
            last  = $_.sn
        }
        enabled   = 1
        logonName = $logonName
        group     = @{
            id   = $groupId
            name = $GroupName
        }
        roles     = @(
            @{
                id    = $RoleName
                name  = $RoleName
                scope = $RoleScope
            }
        )
        account   = @{
            samAccountName = $logonName
            upn            = $_.userPrincipalName
            dn             = $_.distinguishedName
            cn             = $_.CN
            domain         = $Domain

        }
    }
}

if ($CanUseExistingUser) {
    $userId = (Invoke-CoreAPI-Get -Location "people?logonName=$logonName").results.id
}

if (!$userId) {
    $userId = (Invoke-CoreAPI-Post -Location "people" -FailureMessage "Unable to add user" -Body $body).id
    if (!$userId) {
        return
    }
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

$response = Invoke-CoreAPI-Post -Location "people/$userId/requests" -FailureMessage "Unable to create request for user" -Body $body
if ($response) {
    "Request created for user."

    if (!$ShowLinks) {
        $response.PSObject.Properties.Remove('links')
    }
    ConvertTo-Json $response -Depth 6
}
