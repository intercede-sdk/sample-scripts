Param
(
    [Parameter(Mandatory)]
    [string]$ClientId,
    [Parameter(Mandatory)]
    [string]$ClientSecret,

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