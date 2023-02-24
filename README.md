A collection of sample PowerShell scripts.

- getBearer.ps1: Get the OAuth bearer token for authentication when a predefined client secret
- Import_MyID_Core.ps1: Add a user with details defined in a CSV and then request a device for that user
- Import_LDAPUser_MyID_Core.ps1: Import a user from LDAP and request a device for them (optionally perform a directory sync at end)

Example usage:

```
.\getBearer.ps1 -ClientId my.secret -ClientSecret 7f7bd651-15a4-5c33-8c3a-a76a21eddbde

.\Import_MyID_Core.ps1 -ClientId my.secret -ClientSecret 7f7bd651-15a4-5c33-8c3a-a76a21eddbde
.\Import_MyID_Core.ps1 -ClientId my.secret -ClientSecret 7f7bd651-15a4-5c33-8c3a-a76a21eddbde -CanUseExistingUser

.\Import_LDAPUser_MyID_Core.ps1 -ClientId my.secret -ClientSecret 7f7bd651-15a4-5c33-8c3a-a76a21eddbde -LogonName "Alena Castle"
.\Import_LDAPUser_MyID_Core.ps1 -ClientId my.secret -ClientSecret 7f7bd651-15a4-5c33-8c3a-a76a21eddbde -UniqueId "619F4E062A51264A9452EF5F18A89506"
.\Import_LDAPUser_MyID_Core.ps1 -ClientId my.secret -ClientSecret 7f7bd651-15a4-5c33-8c3a-a76a21eddbde -UniqueId "619F4E062A51264A9452EF5F18A89506" -DoDirSync
```
