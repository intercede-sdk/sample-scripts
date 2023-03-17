A collection of sample PowerShell scripts.

- Configure_OAuth.ps1: Update the MyID web.oauth2 web service config to include another client
- getBearer.ps1: Get the OAuth bearer token from the MyID web.oauth2 web service.
- Import_MyID_Core.ps1: Authenticates to MyID, then Add a user with details defined in a CSV and then request a device for that user.
- Import_LDAPUser_MyID_Core.ps1: Authenticates to MyID, then Import a user from LDAP and request a device for them (optionally perform a directory sync at end)
- `psm1` files are support modules used by above scripts

Use the `get-help` feature of powershell to get further details, for example:

```
PS > get-help .\Import_LDAPUser_MyID_Core.ps1 -Full
```
