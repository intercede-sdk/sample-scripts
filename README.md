A collection of sample PowerShell scripts.

- getBearer.ps1: Get the OAuth bearer token for authentication when a predefined client secret
- Import_MyID_Core.ps1: Add a user with details defined in a CSV and then request a device for that user
- Import_LDAPUser_MyID_Core.ps1: Import a user from LDAP and request a device for them

Example usage:

```
.\getBearer.ps1 -clientId my.secret -clientSecret 7f7bd651-15a4-5c33-8c3a-a76a21eddbde

.\Import_MyID_Core.ps1 -clientId my.secret -clientSecret 7f7bd651-15a4-5c33-8c3a-a76a21eddbde
.\Import_MyID_Core.ps1 -clientId my.secret -clientSecret 7f7bd651-15a4-5c33-8c3a-a76a21eddbde -canUseExistingUser

.\Import_LDAPUser_MyID_Core.ps1 -clientId my.secret -clientSecret 7f7bd651-15a4-5c33-8c3a-a76a21eddbde -logonName "Alena Castle"
.\Import_LDAPUser_MyID_Core.ps1 -clientId my.secret -clientSecret 7f7bd651-15a4-5c33-8c3a-a76a21eddbde -uniqueId "619F4E062A51264A9452EF5F18A89506"
```
