A collection of sample PowerShell scripts.

- getBearer.ps1: Get the OAuth bearer token from the MyID web.oauth2 web service.
- Import_MyID_Core.ps1: Authenticates to MyID, then Add a user with details defined in a CSV and then request a device for that user.
- Import_LDAPUser_MyID_Core.ps1: Authenticates to MyID, then Import a user from LDAP and request a device for them (optionally perform a directory sync at end)

Example usage:

```
.\getBearer.ps1 -ClientId myid.mysystem -ClientSecret efdc4478-4fda-468b-9d9a-78792c20c683

.\Import_MyID_Core.ps1 -ClientId myid.mysystem -ClientSecret efdc4478-4fda-468b-9d9a-78792c20c683
.\Import_MyID_Core.ps1 -ClientId myid.mysystem -ClientSecret efdc4478-4fda-468b-9d9a-78792c20c683 -CanUseExistingUser

.\Import_LDAPUser_MyID_Core.ps1 -ClientId myid.mysystem -ClientSecret efdc4478-4fda-468b-9d9a-78792c20c683 -LogonName "Alena Castle"
.\Import_LDAPUser_MyID_Core.ps1 -ClientId myid.mysystem -ClientSecret efdc4478-4fda-468b-9d9a-78792c20c683 -UniqueId "619F4E062A51264A9452EF5F18A89506"
.\Import_LDAPUser_MyID_Core.ps1 -ClientId myid.mysystem -ClientSecret efdc4478-4fda-468b-9d9a-78792c20c683 -UniqueId "619F4E062A51264A9452EF5F18A89506" -DoDirSync
```
