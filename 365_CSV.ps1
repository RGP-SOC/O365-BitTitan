#./Script-Name.ps1 -SourceTenant <Source> -TargetTenant <Target> -VanityDomain <Email Domain> |export-csv PATH


[cmdletbinding()]
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
    Connect-MsolService -Credential $Credential
}
PROCESS {
    foreach ($d in $VanityDomain) {
        try {
            foreach ($u in (Get-MsolUser -All | ? { $_.IsLicensed } | ? { $_.UserPrincipalName -like "*@$($d)" }) ) {
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
END { }
