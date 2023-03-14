Import-Module Microsoft.PowerShell.Utility

# read the contents of a Json file into an object
function Read-JSON
{
    param (
        [Parameter(Mandatory)]
        [string] $FilePath
    )

    $contents = Get-Content $FilePath -Raw

    # our configuration JSON files contain comments,
    # remove the comments
    # regex taken from https://stackoverflow.com/questions/51066978/convert-to-json-with-comments-from-powershell

    $contents = $contents -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/'

    return ($contents | ConvertFrom-Json)
}

# write a json object to a file
function Write-JSON
{
    param(
        [Parameter(Mandatory)]
        [Object] $Contents,
        [Parameter(Mandatory)]
        [string] $FilePath
    )

    $Contents | ConvertTo-Json -Depth 32 | Set-Content $FilePath -Force
}

# backup a file to a file with "_backup" added to the extension
function Backup-File
{
    param(
        [Parameter(Mandatory)]
        [string] $FilePath
    )

    (Get-Content $FilePath -Raw ) | Set-Content ($FilePath + "_backup")
}

function Update-Setting
{
    param(
        [Parameter(Mandatory)]
        [object] $parentObject,
        [Parameter(Mandatory)]
        [string] $settingName,
        [Parameter(Mandatory)]
        [object] $settingValue
    )

    # attempt to get the setting we want so we can test to see if it exists
    $setting = $parentObject | Get-Member -Name $settingName

    if ($null -eq $setting)
    {
        $parentObject | Add-Member -Name $settingName -Value $settingValue -MemberType NoteProperty
    }
    else 
    {
        # Ideally would like to do the following but it doesn't work - I think Get-Member returns a copy rather than reference
        # $setting = $settingValue
        # the documentation says you should be able to use Add-Member with -Force to overwrite the value but this doesn't work either
        # so delete the old setting and re-add it
        $parentObject.psobject.properties.remove($settingName)
        $parentObject | Add-Member -Name $settingName -Value $settingValue -MemberType NoteProperty
    }
}

