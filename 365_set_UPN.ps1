#./Script-Name.ps1 -Tenant <Tenant Name> -VanityDomain <Customers Email Domain>

[cmdletbinding()]
Param (
    [Parameter(Mandatory=$true)]
    [String]$Tenant,
    [Parameter(Mandatory=$true)]
    [String[]]$VanityDomain,
    [String]$Exclude = "admin@$($Tenant)",
    [PsCredential]$Credential
)
BEGIN {
    Connect-MsolService -Credential $Credential
}
PROCESS {
    foreach ($d in $VanityDomain) {
        try {
        	foreach ($user in (Get-MsolUser -All | ? { ($_.UserPrincipalName -like "*@$($d)") -and ($_.UserPrincipalName -ne $Exclude) })) {
                Set-MsolUserPrincipalName -UserPrincipalName $user.UserPrincipalName -NewUserPrincipalName ($user.UserPrincipalName.Split("@")[0] + "@$($Tenant)")
                $user.UserPrincipalName
            }
        } catch {
            Write-Error "Problem with process..."
        }
    }
}  
END { }

Run the above:


