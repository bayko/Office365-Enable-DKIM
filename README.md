# Office365-Enable-DKIM
This script will automate the process of enabling DKIM for all domains inside an Office 365 Tenant. Normally this process requires logging into EAC after you have created the DNS records required and manually throwing the switch on each one.

DKIM will only be turned on for a domain if a DNS lookup for both CNAME records is successful, otherwise it is skipped:

selector1._domainkey.contoso.com 
selector2._domainkey.contoso.com

```````````````````````````````````````````````````````````````````
Provide your Global Admin credentials as a parameter when executing:

C:\Users\User> .\Office365-Enable-DKIM.ps1 admin@contoso.com Password123
