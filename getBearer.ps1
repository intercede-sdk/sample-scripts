Param
(
    [string]$authurl = "https://react.domain31.local/web.oauth2/connect/token",
    [string]$clientId = "client id",
    [string]$clientSecret = "client secret"
)

$headers = @{
    'Authorization' = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${clientId}:${clientSecret}"))
}

try {
    $tokenResponse = Invoke-WebRequest -Uri $authurl -Method Post -Headers $headers  -Body "grant_type=client_credentials"
    $tokenResponseJSON = ConvertFrom-Json $tokenResponse.Content

    $token = $tokenResponseJSON.access_token 

    "  Authorized. Token is:"
    "$token"
}
catch {
    
    "  ERROR - Unable to get an access token."
    "$Error"
}