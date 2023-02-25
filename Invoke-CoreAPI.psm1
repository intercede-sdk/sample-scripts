Function Set-CoreAPIConnection {
    Param
    (
        [Parameter(Mandatory)]
        [string]$Server,
        [Parameter(Mandatory)]
        [string]$ClientId,
        [Parameter(Mandatory)]
        [string]$ClientSecret
    )

    $headers = @{
        'Authorization' = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${ClientId}:${ClientSecret}"))
    }
    
    # TODO - is there a function for joining URIs?
    try {
        $tokenResponse = Invoke-WebRequest -Uri "$Server/web.oauth2/connect/token" -Method Post -Headers $headers  -Body "grant_type=client_credentials"
        $tokenResponseJSON = ConvertFrom-Json $tokenResponse.Content
    
        $token = $tokenResponseJSON.access_token 

        New-Variable -Name ApiHeader -Value @{
            'Authorization' = "Bearer $Token"
            'Content-type'  = 'application/json'
        } -Scope Script -Force

        New-Variable -Name ApiUrl -Value "$Server/rest.core/api" -Scope Script -Force
    }
    catch {
        return "ERROR - Unable to get an access token. $_"
    }
}

Function Invoke-CoreAPIGet {
    Param
    (
        [Parameter(Mandatory)]
        [string] $Location,
        [string] $FailureMessage = ""
    )

    try {
        $apiResponse = Invoke-WebRequest -Uri "$ApiUrl/$Location" -Headers $ApiHeader
        return ConvertFrom-Json $apiResponse.Content
    }
    catch {
        Write-Host "ERROR - $FailureMessage. $_"
    }
}

Function Invoke-CoreAPIMethod {
    Param
    (
        [Parameter(Mandatory)]
        [string] $Location,
        [string] $FailureMessage = "",

        [Parameter(Mandatory)]
        [PSCustomObject] $Body,
        [Parameter(Mandatory)]
        [string] $Method
    )

    try {
        $apiResponse = Invoke-WebRequest -Uri "$ApiUrl/$Location" -Headers $ApiHeader -Method $Method -Body ($Body | ConvertTo-Json)
        return ConvertFrom-Json $apiResponse.Content
    }
    catch {
        Write-Host "ERROR - $FailureMessage. $_"
    }
}

Function Invoke-CoreAPIPost {
    Param
    (
        [Parameter(Mandatory)]
        [string] $Location,
        [string] $FailureMessage = "",

        [Parameter(Mandatory)]
        [PSCustomObject] $Body
    )

    Invoke-CoreAPIMethod -Location $Location -FailureMessage $FailureMessage -Method Post -Body $Body
}

Function Invoke-CoreAPIPatch {
    Param
    (
        [Parameter(Mandatory)]
        [string] $Location,
        [string] $FailureMessage = "",

        [Parameter(Mandatory)]
        [PSCustomObject] $Body
    )

    Invoke-CoreAPIMethod -Location $Location -FailureMessage $FailureMessage -Method Patch -Body $Body
}

Export-ModuleMember -Function Set-CoreAPIConnection
Export-ModuleMember -Function Invoke-CoreAPIGet
Export-ModuleMember -Function Invoke-CoreAPIPost
Export-ModuleMember -Function Invoke-CoreAPIPatch
