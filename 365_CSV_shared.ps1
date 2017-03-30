#./Script-Name.ps1 -VanityDomain <Customers Email Domain> |export-csv PATH

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
            foreach ($u in (Get-Mailbox | where {$_.recipientTypeDetails -eq 'sharedmailbox' } )) {
                $out = [ordered]@{}
                $out.'Source Email' = $u.UserPrincipalName.Replace($d, $SourceTenant)
                $out.'Source Login Name' = $null
                $out.'Source Password' = $null
                $out.'Destination Email' = $u.UserPrincipalName.Replace($d, $TargetTenant)
                $out.'Destination Login Name' = $null
                $out.'Destination Password' = $null
                $out.'Flags' = $Flags
                [PsCustomObject]$out
            }
        } catch {
            Write-Error "Problem with process..."
        }
    }
}  
END {
    Remove-PsSession $Session
}