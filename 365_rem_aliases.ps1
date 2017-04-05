<#
.SYNOPSIS
Removes matching aliases from Office 365 tentant to allow the domain to be removed from Office 365
.PARAMETER VanityDomain
An array of "vanity domains" in use by the organisation.
.PARAMETER Credential
The credentials to log onto the source tenant.
.EXAMPLE
./Script-Name.ps1 -Credential (Get-Credential) -VanityDomain example.com
#>
[cmdletbinding(SupportsShouldProcess=$True)]
Param (
    [Parameter(Mandatory=$true)]
    [String[]]$VanityDomain,
    [PsCredential]$Credential
)
BEGIN {
    $Session = New-PsSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -AllowRedirect -Authentication Basic -Credential $Credential -EA Stop
    Import-PsSession -AllowClobber $Session -EA Stop | Out-Null
}
PROCESS {
    foreach ($d in $VanityDomain) {
        Write-Verbose "Processing ""$($d)""..."
        #try {
            # Process mailboxes
        	foreach ($Mailbox in (Get-Mailbox -ResultSize Unlimited | ? { ($_.EmailAddresses -like "*@$($d)") })) {
                Write-Verbose "Processing ""$($Mailbox.UserPrincipalName)""..."
                $Addresses = $Mailbox.EmailAddresses
                foreach ($Email in $Mailbox.EmailAddresses) {
                    Write-Verbose "Checking ""$Email""..."
                    if ($Email -like "smtp:*@$($d)") {
                        $Action = "Removed"
                        Write-Verbose "Match found..."
                        $Addresses.Remove($Email)
                    } else {
                        $Action = "Skipped"
                    }
                    # Show some output
                    [PsCustomObject]@{
                        Name = $Mailbox.UserPrincipalName;
                        Type = $Mailbox.RecipientTypeDetails;
                        EmailAddress = $Email;
                        Action = $Action
                    }
                }
                if ($pscmdlet.ShouldProcess($Mailbox.UserPrincipalName, "Set-Mailbox")) {
                    try {
                        Write-Verbose "Setting EmailAddresses..."
                        Set-Mailbox -Identity $Mailbox.UserPrincipalName -Emailaddresses $Addresses -EA Stop
                    } catch {
                        $ErrorMessage = $_.Exception.Message
                        Write-Error "Problem with Set; Error: $($ErrorMessage)"
                    }
                }
            }
            # Process distribution lists
            foreach ($List in (Get-DistributionGroup -ResultSize Unlimited | ? { ($_.EmailAddresses -like "*@$($d)") })) {
                Write-Verbose "Processing ""$($List.Name)""..."
                $Addresses = $List.EmailAddresses
                foreach ($Email in $List.EmailAddresses) {
                    Write-Verbose "Checking ""$Email""..."
                    if ($Email -like "smtp:*@$($d)") {
                        $Action = "Removed"
                        Write-Verbose "Match found..."
                        $Addresses.Remove($Email)
                    } else {
                        $Action = "Skipped"
                    }
                    # Show some output
                    [PsCustomObject]@{
                        Name = $List.Name;
                        Type = "DistributionList";
                        EmailAddress = $Email;
                        Action = $Action
                    }
                }
                if ($pscmdlet.ShouldProcess($List.UserPrincipalName, "Set-DistributionList")) {
                    try {
                        Write-Verbose "Setting EmailAddresses..."
                        Set-DistributionGroup -Identity $List.Name -Emailaddresses $Addresses
                    } catch {
                        $ErrorMessage = $_.Exception.Message
                        Write-Error "Problem with Set; Error: $($ErrorMessage)"
                    }
                }
            }
        #}catch {
        #    $ErrorMessage = $_.Exception.Message
        #    $FailedItem = $_.Exception.ItemName
        #    Write-Error "Problem with: $($FailedItem); Error: $($ErrorMessage)"
        #}
    }
}  
END {
    # Remove PsSession if required
    if ($Session) {
        #Remove-PsSession $Session
    }
}


