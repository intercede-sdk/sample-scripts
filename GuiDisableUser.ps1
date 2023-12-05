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
#Form Start

Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration

[xml]$XAML = @'

<Window x:Class="InteractiveDisableUser.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:InteractiveDisableUser"
        mc:Ignorable="d"
        Title="Disable User" Height="450" Width="800">
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="57*"/>
            <ColumnDefinition Width="743*"/>
        </Grid.ColumnDefinitions>
        <Label Content="First few characters of last name of user to disabled" HorizontalAlignment="Left" Margin="0,18,0,0" VerticalAlignment="Top" Width="286" Height="26" Grid.Column="1"/>
        <Label Content="Reason to disable" HorizontalAlignment="Right" Margin="0,187,457,0" VerticalAlignment="Top" Width="286" Grid.Column="1" Height="26"/>
        <Label Content="Notes" Margin="0,214,457,0" VerticalAlignment="Top" Grid.Column="1" Height="26"/>
        <Label Content="Results" HorizontalAlignment="Right" Margin="0,245,457,0" VerticalAlignment="Top" Width="286" Grid.Column="1" Height="26"/>
        <TextBox x:Name="lastName" HorizontalAlignment="Left" Margin="302,22,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="369" Grid.Column="1" Height="18"/>
        <ComboBox x:Name="reasonList" HorizontalAlignment="Right" Margin="0,191,150,0" VerticalAlignment="Top" Width="466" Grid.Column="1" Height="22"/>
        <TextBox x:Name="notes" Margin="127,218,150,0" TextWrapping="Wrap" VerticalAlignment="Top" Grid.Column="1" Height="18"/>
        <TextBox x:Name="results" HorizontalAlignment="Right" Margin="0,276,72,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="671" Height="140" Grid.Column="1" IsEnabled="False"/>
        <Button Grid.Column="1" Content="Update" HorizontalAlignment="Right" Margin="0,214,72,0" VerticalAlignment="Top" IsEnabled="{Binding SelectedValuePath, ElementName=reasonList}" Width="65"/>
        <DataGrid x:Name="users" Grid.Column="1" Margin="0,55,72,252" IsReadOnly="True"/>
    </Grid>
</Window>

'@ -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window' -replace 'x:Class="\S+"', ''


#Read XAML
$reader = (New-Object System.Xml.XmlNodeReader $XAML)
$form = [Windows.Markup.XamlReader]::Load($reader)
$XAML.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name ($_.Name) -Value $form.FindName($_.Name) }

#endregion

#region XAML Controlls

$lastName.Add_TextChanged({
        $search = $lastName.Text
        if (!$search) {
            return $users.ItemsSource = $null
        }

        $results = Invoke-CoreAPIGet -Location "people?name.last=$($search)*"
        $users.ItemsSource = $results.results
    })

   
#endregion

$form.ShowDialog()
<#

#Enter surname of user we wish to find
$id = Read-Host "Enter 'id' of user to disable"

# Exit early if user is not found or already disabled
$selectedUser = $users.results | Where-Object { $_.id -eq $id }
if (!$selectedUser) {
    return "Please check id provided and try again"
}

if ( $selectedUser.Enabled -eq "No") {
    Write-Host "Selected user is already disabled"
    return $selectedUser
}

#Show reasons for disabling user
#Disable person is operation 100113 (can we simplify this?)
$possibleReasons = Invoke-CoreAPIGet -Location "people/$($id)/statusMappings?op=100113"
$possibleReasons.results

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