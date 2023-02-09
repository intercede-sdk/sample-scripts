#TODO: Create import from LDAP script
#TODO: Add switch to decide whether to use existing user for requests (i.e. don't error if user already exists)
#TODO ? Move try/catch to functions

Param
(
    [string]$auth_url = "https://react.domain31.local/web.oauth2/connect/token",
    [string]$api_url = "https://react.domain31.local/rest.core/api",
    [string]$clientId = "client id",
    [string]$clientSecret = "client secret",
    [string]$csv_location = "C:\temp\ACastle2.csv"

)

Function Invoke-CoreAPI-Get {
    Param
    (
        [Parameter(Mandatory)]
        [string] $Location
    )

    $apiResponse = Invoke-WebRequest -Uri "$api_url/$Location" -Headers $apiHeaders
    return ConvertFrom-Json $apiResponse.Content
}

Function Invoke-CoreAPI-Post {
    Param
    (
        [Parameter(Mandatory)]
        [string] $Location,

        [Parameter(Mandatory)]
        [object] $Body
    )

    $apiResponse = Invoke-WebRequest -Uri "$api_url/$Location" -Headers $apiHeaders -Method Post -Body ($Body | ConvertTo-Json)
    return ConvertFrom-Json $apiResponse.Content
}

################ Auth

$headers = @{
    'Authorization' = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${clientId}:${clientSecret}"))
}

try {
    $tokenResponse = Invoke-WebRequest -Uri $auth_url -Method Post -Headers $headers  -Body "grant_type=client_credentials"
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
$groupName = "Technology"

try {
    $groupId = (Invoke-CoreAPI-Get -Location "groups?q=$groupName").results.id
}
catch {
    return "ERROR - Unable to get group. $_"
}

if (!$groupId) {
    return "Group '$groupName' doesn't exist"
    # We could add group through API, but it seems more sensible that Config should be done ahead
    # Similar to the roles we expect the system to have
}

################ Get Role
# Make sure role we are trying to set exists
# Unfortunately this API endpoint doesn't filter on name
$role = "MyID_PROD_Cardholders"
$scope = "self"

try {
    $roleId = (Invoke-CoreAPI-Get -Location "roles").results | Where-Object id -eq $role
}
catch {
    return "ERROR - Unable to get role. $_"
}

if (!$roleId) {
    return "Role '$role' doesn't exist"
}

# note objectGUID/uniqueID from LDAP can't be used
# show a separate LDAP import
#                            <UniqueID>'+$UniqueID+'</UniqueID>

################ Add User

$domain = "domain31"

Import-CSV -Path .\ACastle2.csv -Delimiter ';' |

ForEach-Object {
    $body = @{
        name      = @{
            first = $_.GivenName
            last  = $_.sn
        }
        enabled   = 1
        logonName = $_.SAMAccountName
        group     = @{
            id   = $groupId
            name = $groupName
        }
        roles     = @(
            @{
                id    = $role
                name  = $role
                scope = $scope
            }
        )
        account   = @{
            samAccountName = $_.SAMAccountName
            upn            = $_.userPrincipalName
            dn             = $_.distinguishedName
            cn             = $_.CN
            domain         = $domain

        }
    }
}
       
# Are these settings available?
#            <SourceID>CertServ</SourceID>
#            <IssueDate>2022-07-22</IssueDate>
#            <GenerateUserDN>0</GenerateUserDN>
#            <ActionOnDuplicate>MergeEmpty</ActionOnDuplicate>
#            <RolesActionOnDuplicate>Skip</RolesActionOnDuplicate>
#            <DeleteMissingUsers>0</DeleteMissingUsers>
#            <PushToLDAP>0</PushToLDAP>
#            <CreateUnknownGroups>1</CreateUnknownGroups>
#            <AuditAll>1</AuditAll>
#            <DataType>CMSRequestCard</DataType>


try {
    $newUser = (Invoke-CoreAPI-Post -Location "people" -Body $body).id
}
catch {
    return "ERROR - Unable to add user. $_"
    ## I don't want to accidentally add request for a different user in the system
    # We could have searched for Logon Name prior to add to avoid 'logonName already exists' errors
}

################ Create request
$credProfileName = "TMO_1"

try {
    $credProfileId = (Invoke-CoreAPI-Get -Location "credprofiles?q=$credProfileName").results.id
}
catch {
    return "ERROR - Unable to get credentialprofile. $_"
}

if (!$credProfileId) {
    return "Credential profile '$credProfileName' doesn't exist"
}

$body = @{
    credProfile = @{
        id = $credProfileId
    }
}

try {
    $response = Invoke-CoreAPI-Post -Location "people/$newUser/requests" -Body $body
}
catch {
    return "ERROR - Unable to create request for user. $_"
}

"Request created for user."
$response