# PowerShell script to find a user and then disable them through a GUI front-end
# In order to disable a person in the Core API, the role used by the
# user account used in the client credential grant needs to have "Edit User" access

#region set up

# Use PowerShell Module that provide Core API access
Import-Module $PSScriptRoot\Invoke-CoreAPI.psm1 -Force

# Get authentication token
Set-CoreAPIConnection -Server "https://react.domain31.local" -ClientId "get.user" -ClientSecret "07025f77-e54e-46eb-a2eb-079f89586573"
#endregion

#region XAML

Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration

[xml]$XAML = (Get-Content -Path "$PSScriptRoot\\GUI\\InteractiveDisableUser\\MainWindow.xaml" -Raw) -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window' -replace 'x:Class="\S+"', ''

#Read XAML
$reader = (New-Object System.Xml.XmlNodeReader $XAML)
$form = [Windows.Markup.XamlReader]::Load($reader)
$XAML.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name ($_.Name) -Value $form.FindName($_.Name) }

#endregion

#region XAML Controls

# Populate users datagrid with users that match last name
$lastName.Add_TextChanged({
        $search = $lastName.Text
        if (!$search) {
            return $users.ItemsSource = $null
        }

        $results = Invoke-CoreAPIGet -Location "people?name.last=$($search)*"
        $users.ItemsSource = $results.results
    })

# Populate reasons datagrid with reasons to disable - note this can vary as selected user varies
$users.Add_SelectionChanged({
    Write-Host $users.selectedItems
    if($users.selectedItems.Enabled -eq "No"){
        Write-Host "already disabled"
        return $reasonList.ItemsSource = $null
    }
    $possibleReasons = Invoke-CoreAPIGet -Location "people/$($users.selectedItems.id)/statusMappings?op=100113"
    $reasonList.ItemsSource = $possibleReasons.results
})

# 'Update button' should be disabled until user and reason is selected
# Show messages in "Results" - select user, select reason, user already disabled, enter note (optional) and click update, result of update
   
#endregion

$form.ShowDialog()
<#


#Choose reason to disable
$reason = Read-Host "Enter 'id' of reason"
$notes = Read-Host "(Optional) Provide notes to be included when disabling user"

#set up body for cancellation
$cancelReason = @{
    reason = @{
        statusMappingId = $reason
        description     = $notes
    }
}

# Perform disable operations
$response = Invoke-CoreAPIPost -Location "people/$($id)/disable" -Body $cancelReason -FailureMessage "Unable to disable user"
# Remove Links from reponse (these are the operations that can be performed on the user)
$response.PSObject.Properties.Remove('links')
ConvertTo-Json $response -Depth 6
#>