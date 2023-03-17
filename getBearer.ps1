<#
.SYNOPSIS
Generates an authentication token

.DESCRIPTION
Generates an authentication token from the MyID web.oauth2 web service.
Takes a client identifier and secret and sends it to the MyID web.oauth2 web service in a manner that it expects.

.PARAMETER ClientId
The client identifier, e.g. myid.mysystem

.PARAMETER ClientSecret
The client secret, e.g. efdc4478-4fda-468b-9d9a-78792c20c683

.PARAMETER Authurl
The MyID web.oauth2 web service

.EXAMPLE
.\getBearer.ps1 -ClientId myid.mysystem -ClientSecret efdc4478-4fda-468b-9d9a-78792c20c683
  Authorized. Token is:
eyJhbGciOiJSUzI1NiIsImtpZCI6IlU1VUpPTm5WR1pBPSIsInR5cCI6ImF0K2p3dCJ9.eyJuYmYiOjE2Nzg3Mjc1MjEsImV4cCI6MTY3ODczMTEyMSwiaXNzIjoiaHR0cHM6Ly9yZWFjdC5kb21haW4zMS5sb2NhbC93ZWIub2F1dGgyIiwiYXVkIjoibXlpZC5yZXN0IiwiY2xpZW50X2lkIjoibXlpZC5zcGVjZmxvdy5hZG1pbiIsIm15aWRTZXNzaW9uSWQiOiItMzI4NjM2NTczLDdBODA3RjE1LTgyODQtNDM3NS1CMzUwLTAxQzk4QTExNzUzMyIsImp0aSI6IjcyQTBDODVEQTk2QzEyNTk3NTRBREI4MEQzRTYxNTVFIiwiaWF0IjoxNjc4NzI3NTIxLCJzY29wZSI6WyJteWlkLnJlc3QuYmFzaWMiXX0.olPJc84TLldJ5QibLt1D1aiLIAu8EFmzxDJ8ZQAvjVXU5whfUsjo-9aqEKaV6zpWZlf7wkWO9PfY5HDcwFt7kKmo8AZ4vHR03BpG2PJwYxug4lL0Z6CmjIpYsbELmby8Pt_qs6eVT87uhFVOpkU-raDhx6ts5JkK2_YPFXzTBoYHFcNGMBAP7DOCUwCPszJAkdHZ6f-liTEyW-EaIUKbarc7xaLPVG9S6WrA5RVv1WK3vRZ-0ew5eoaN1dq2irbAAoQ5jLX6vsXJc0ErRPsNkmMhFVTN1WsCBcVlzDN5Td0Z-Pk35pNhfo9D4_dcQ-7BRUn1tmqurCTQiGlTTBn1PA
#>

[CmdletBinding(PositionalBinding = $false)]
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