<#
.DESCRIPTION
This script shows how you can get an Authentication Token from the MyID web.oauth2 web service.
Update the PARAM section to reflect your environment.
#>

Param
(
    [string]$ClientId = "myid.mysystem",
    [string]$ClientSecret = "efdc4478-4fda-468b-9d9a-78792c20c683",
    [string]$Authurl = "https://react.domain31.local/web.oauth2/connect/token"
)

$headers = @{
    'Authorization' = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${ClientId}:${ClientSecret}"))
}

try {
    $tokenResponseJSON = Invoke-WebRequest -Uri $Authurl -Method Post -Headers $headers  -Body "grant_type=client_credentials"
    $tokenResponse = ConvertFrom-Json $tokenResponseJSON.Content

    $token = $tokenResponse.access_token 

    "  Authorized. Token is:"
    "$token"
}
catch {
    
    "  ERROR - Unable to get an access token."
    "$Error"
}