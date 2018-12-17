Write-Host 'Connecting to 365' -foregroundcolor DarkGreen
$Username = $args[0]
$Password = $args[1]
if ((!$Username) -or (!$Password)){
    Write-Host 'You must supply global admin credentials as parameters when executing this script ( ie: C:\> .\STS-Office365-Provisioning.ps1 office365admin@company.com Password99 )' -foregroundcolor Red
    Exit
}
$SecureStringPwd = $Password | ConvertTo-SecureString -AsPlainText -Force 
$Creds = New-Object System.Management.Automation.PSCredential -ArgumentList $Username, $SecureStringPwd
Connect-MsolService -Credential $Creds
$Session = New-PSSession -ConfigurationName Microsoft.Exchange `
    -ConnectionUri https://outlook.office365.com/powershell-liveid/ `
    -Credential $Creds -Authentication Basic -AllowRedirection
Import-PSSession $Session

Write-Host 'Enabling DKIM on all tenant Domains where CNAME records have been configured' -foregroundcolor DarkGreen
# Run DKIM status check against all client created domain names inside tenant account
$DkimDomains = Get-MsolDomain | Where-Object Name -notmatch "microsoft"
foreach ($DkimDomain in $DkimDomains) {
    $DkimReady = Get-DkimSigningConfig $DkimDomain.Name

    # If the domain already has DKIM enabled, skip it
    if ($DkimReady.Enabled -eq 'True') {
        Write-Host ('DKIM Already Enabled for ' + $DkimDomain.Name) -foregroundcolor Blue
    } else {

        # Perform DNS lookup to check if both CNAME records exist (selector1._domainkey.contoso.com & selector2._domainkey.contoso.com)
        $RecordCheck1 = "selector1._domainkey." + $DkimDomain.Name
        $RecordCheck2 = "selector2._domainkey." + $DkimDomain.Name
        try {
            $ErrorActionPreference = 'silentlycontinue'
            $RecordLookup1 = Resolve-DnsName -Name $RecordCheck1 -Type CNAME
            $RecordLookup2 = Resolve-DnsName -Name $RecordCheck2 -Type CNAME

            # If both of the records exist, enable DKIM for the domain name in EAC
            if (($RecordLookup1) -and ($RecordLookup2)) {
                Set-DkimSigningConfig -Identity $DkimDomain.Name -Enabled $True
                Write-Host ('Enabled DKIM for ' + $Dkimdomain.Name) -foregroundcolor DarkGreen

            # Skip enabling where lookup for both DNS records failed
            } else {
                Write-Host ('Skipped Enabling DKIM for ' + $Dkimdomain.Name + ' as no CNAME records were found!') -foregroundcolor Red
                }
        } catch {
            Write-Host ('Skipped Enabling DKIM for ' + $Dkimdomain.Name + ' as no CNAME records were found!') -foregroundcolor Red
        }
    }
}
