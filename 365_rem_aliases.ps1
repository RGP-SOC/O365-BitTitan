#./Script-Name.ps1 -VanityDomain <Customers Email Domain>

[cmdletbinding(SupportsShouldProcess=$True)]
Param (
    [Parameter(Mandatory=$true)]
    [String[]]$VanityDomain,
    [PsCredential]$Credential
)
BEGIN {
    $Session = New-PsSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -AllowRedirect -Authentication Basic -Credential $Credential
    Import-PsSession -AllowClobber $Session | Out-Null
}
PROCESS {
    foreach ($d in $VanityDomain) {
        try {
        	foreach ($user in (Get-Mailbox -ResultSize Unlimited | ? { ($_.EmailAddresses -like "*@$($d)") })) {
                Write-Verbose "Processing $(user.UserPrincipalName)..."
                $Addresses = $user.EmailAddresses
                foreach ($email in $user.EmailAddresses) {
                    Write-Verbose "Checking $email..."
                    if ($email -like "smtp:*@$($d)") {
                        Write-Verbose "smtp:*@$($d) matched..."
                        $Addresses.Remove($email)
                    }
                }
                $user.EmailAddresses = $Addresses
                if ($pscmdlet.ShouldProcess("$i", "Set-Mailbox")) {
                    Set-Mailbox -Identity $user.UserPrincipalName -Emailaddresses $user.EmailAddresses
                }
            }
        } catch {
            Write-Error "Problem with process..."
        }
    }
}  
END {
    Remove-PsSession $Session
}


