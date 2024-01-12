# Use PowerShell Module that provide Core API access
Import-Module $PSScriptRoot\Invoke-CoreAPI.psm1 -Force

# Get authentication token
# This was set using details from: https://forums.intercede.com/wp-content/uploads/Flare/MyID-v1209-PIV/index.htm#MyID%20Core%20API/Authentication/Authentication.htm?TocPath=APIs%257CMyID%2520Core%2520API%257C3%2520Server-to-server%2520authentication%257C_____0
Set-CoreAPIConnection -Server "https://react.domain31.local" -ClientId "get.user" -ClientSecret "07025f77-e54e-46eb-a2eb-079f89586573"

#tests if input is a valid GUID
function testguid($test) {
    $ObjectGuid = [System.Guid]::empty
    # Returns True if successfully parsed, otherwise returns False.
    [System.Guid]::TryParse($test, [System.Management.Automation.PSReference]$ObjectGuid)
}

function updatePerson($nameOrId, $file) {

    if (testguid $nameOrId) {
        $href = "people/" + $nameOrId
    }
    else {
        $entity = Invoke-CoreAPIGet -Location "people?q=$($nameOrId)"
        #$entity.results
        $href = $entity.results.href

        if ($href.count -gt 1) {
            return "Multiple records found:`n$href"
        }
    }

    $file = "$PSScriptRoot\$file"

    $body = get-content $file | ConvertFrom-Json

    Invoke-CoreAPIPatch -Location $href -Body $body -FailureMessage "Error updating $nameOrId"
}

# Directly in DB (as hidden config)
# UPDATE dbo.Configuration SET [Value]='YES' WHERE [Name]='EDIT DN'
# Operation Settings > LDAP
# Edit Directory Information = YES
# Background Update = NO
# BOL Shutdown / IIS restart

# example: use JSON to update a user by name - only works for a single match
# . .\UpdateUser;updatePerson grace nameChange.json
# example: update a user by their MyID GUID
# . .\UpdateUser;updatePerson 2E054F53-2918-44FB-A5C1-32B6061222F5 nameChange.json
