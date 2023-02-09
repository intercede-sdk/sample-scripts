﻿#TODO: Create import from LDAP script
#TODO: Add switch to decide whether to use existing user for requests (i.e. don't error if user already exists)
#TODO ? Move try/catch to functions

Param
(
    [string]$authUrl = "https://react.domain31.local/web.oauth2/connect/token",
    [string]$apiUrl = "https://react.domain31.local/rest.core/api",
    [string]$clientId = "client id",
    [string]$clientSecret = "client secret",
    [string]$groupName = "Technology",
    [string]$roleName = "MyID_PROD_Cardholders",
    [string]$roleScope = "self",
    [string]$domain = "domain31",
    [string]$credProfileName = "TMO_1"
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
        return ""
    }

}

Function Invoke-CoreAPI-Post {
    Param
    (
        [Parameter(Mandatory)]
        [string] $Location,
        [string] $FailureMessage = "",

        [Parameter(Mandatory)]
        [object] $Body
    )

    try {
        $apiResponse = Invoke-WebRequest -Uri "$apiUrl/$Location" -Headers $apiHeaders -Method Post -Body ($Body | ConvertTo-Json)
        return ConvertFrom-Json $apiResponse.Content
    }
    catch {
        Write-Host "ERROR - $FailureMessage. $_"
        return ""
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

################ Get Group
$groupId = (Invoke-CoreAPI-Get -Location "groups?q=$groupName" -FailureMessage "Unable to get group").results.id
if (!$groupId) {
    return "Unable to find Group '$groupName'"
    # We could add group through API, but it seems more sensible that Config should be done ahead
    # Similar to the roles we expect the system to have
}

################ Get Role
# Make sure role we are trying to set exists
# Unfortunately this API endpoint doesn't filter on name
$roleId = (Invoke-CoreAPI-Get -Location "roles" -FailureMessage "Unable to get role").results | Where-Object id -eq $roleName
if (!$roleId) {
    return "Unable to find Role '$roleName'"
}

# note objectGUID/uniqueID from LDAP can't be used
# show a separate LDAP import
#                            <UniqueID>'+$UniqueID+'</UniqueID>

################ Add User
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
                id    = $roleName
                name  = $roleName
                scope = $roleScope
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


$newUser = (Invoke-CoreAPI-Post -Location "people" -FailureMessage "Unable to add user" -Body $body).id
if (!$newUser) {
    ## I don't want to accidentally add request for a different user in the system
    # We could have searched for Logon Name prior to add to avoid 'logonName already exists' errors
    return;
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

$response = Invoke-CoreAPI-Post -Location "people/$newUser/requests" -FailureMessage "Unable to create request for user" -Body $body
if ($response) {
    "Request created for user."
    $response
}
