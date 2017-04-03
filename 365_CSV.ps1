<#
.SYNOPSIS
Exports user list from Office 365 tentant in a format that can be used to bulk-add users in BitTitan
.PARAMETER SourceTenant
The name of the source tentant.
.PARAMETER TargetTenant
The name of the target tentant.
.PARAMETER VanityDomain
An array of "vanity domains" in use by the organisation.
.PARAMETER Flags
Flags that affect the migration process in BitTitan. See the BitTitan KB for more info.
.PARAMETER Credential
The credentials to log onto the source tenant.
.EXAMPLE
./Script-Name.ps1 -Credential (Get-Credential) -SourceTenant sourcecompany.onmicrosoft.com -TargetTenant targettenant.onmicrosoft.com 
#>
[cmdletbinding(SupportsShouldProcess=$True)]
Param (
    [Parameter(Mandatory=$true)]
    [String]$SourceTenant,
    [Parameter(Mandatory=$true)]
    [String]$TargetTenant,
    [Parameter(Mandatory=$true)]
    [String[]]$VanityDomain,
    [Int]$Flags = 0,
    [PsCredential]$Credential
)
BEGIN {
    $Session = New-PsSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -AllowRedirect -Authentication Basic -Credential $Credential
    Import-PsSession -AllowClobber $Session | Out-Null
}
PROCESS {
    foreach ($d in $VanityDomain) {
        try {
            foreach ($u in (Get-Mailbox -ResultSize Unlimited | ? { $_.UserPrincipalName -like "*@$($d)" }) ) {
                $out = [ordered]@{}
                $out.'Source Email' = $u.UserPrincipalName.Replace("@$($d)", "@$($SourceTenant)")
                $out.'Source Login Name' = $null
                $out.'Source Password' = $null
                $out.'Destination Email' = $u.UserPrincipalName.Replace("@$($d)", "@$($TargetTenant)")
                $out.'Destination Login Name' = $null
                $out.'Destination Password' = $null
                $out.'Flags' = $Flags
                [PsCustomObject]$out
            }
        } catch {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            Write-Error "Problem with: $($FailedItem); Error: $($ErrorMessage)"
        }
    }
}
END {
    # Remove PsSession if required
    if ($Session) {
        Remove-PsSession $Session
    }
}
