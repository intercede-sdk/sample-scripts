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

# Default message
$results.Text = "Enter part of user's last name"

# Populate users datagrid with users that match last name
$lastName.Add_TextChanged({
        $search = $lastName.Text
        if (!$search) {
            $results.Text = "Enter part of user's last name"
            return $users.ItemsSource = $null
        }
        $userList = (Invoke-CoreAPIGet -Location "people?name.last=$($search)*").results
        $users.ItemsSource = $userList
        $results.Text = $userList ? "Select a user" : "No user found"        
    })

# Populate reasons datagrid with reasons to disable - note this can vary as selected user varies
$users.Add_SelectionChanged({
    if(!$users.selectedItems){
        return $reasonList.ItemsSource = $null
    }
    if($users.selectedItems.Enabled -eq "No"){
        $results.Text = "Selected user already disabled"
        return $reasonList.ItemsSource = $null
    }
    $possibleReasons = Invoke-CoreAPIGet -Location "people/$($users.selectedItems.id)/statusMappings?op=100113"
    $reasonList.ItemsSource = $possibleReasons.results
    $results.Text = "Select reason to disable and, optionally, add notes"
})

# 'Update button' disabled until user and reason is selected
$reasonList.Add_SelectionChanged({
    $update.IsEnabled = $reasonList.selectedItems;
    if($reasonList.selectedItems){
        $results.Text = "Click update to disable user"
    }
})

$update.Add_Click({
    # avoid double call
    $update.IsEnabled = $false;
    # set up body for cancellation
    $cancelReason = @{
        reason = @{
            statusMappingId = $reasonList.selectedItems.id
            description     = $notes.Text
        }
    }

    Write-Host @cancelReason
    
    # Perform disable operations
    $response = Invoke-CoreAPIPost -Location "people/$($users.selectedItems.id)/disable" -Body $cancelReason -FailureMessage "Unable to disable user"
    # Remove Links from reponse (these are the operations that can be performed on the user)
    $response.PSObject.Properties.Remove('links')
    $results.Text = ConvertTo-Json $response -Depth 6
})
   
#endregion

$form.ShowDialog()