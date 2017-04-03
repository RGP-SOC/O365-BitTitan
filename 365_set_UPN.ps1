<#
.SYNOPSIS
Changes UserPrincipalName (Login Name) from SourceDomain to TargetDomain in the Office 365 Tenant
.PARAMETER SourceDomain
The name of the source domain.
.PARAMETER TargetDomain
The name of the target domain.
.PARAMETER Credential
The credentials to log onto the tenant.
.PARAMETER Exdlue
List of accounts to exlcude from the change.
.EXAMPLE
./Script-Name.ps1 -Credential (Get-Credential) -SourceDomain example.com -TargetDomain example.onmicrosoft.com 
#>
[cmdletbinding()]
Param (
    [Parameter(Mandatory=$true)]
    [String[]]$SourceDomain,
    [Parameter(Mandatory=$true)]
    [String]$TargetDomain,
    [String]$Exclude = "admin@$($SourceDomain)",
    [PsCredential]$Credential
)
BEGIN {
    Connect-MsolService -Credential $Credential -EA Stop
}
PROCESS {
    foreach ($d in $SourceDomain) {
        try {
        	foreach ($user in (Get-MsolUser -All | ? { ($_.UserPrincipalName -like "*@$($d)") -and ($_.UserPrincipalName -ne $Exclude) })) {
                $NewUserPrincipalName = $user.UserPrincipalName.Split("@")[0] + "@$($TargetDomain)"
                Set-MsolUserPrincipalName -UserPrincipalName $user.UserPrincipalName -NewUserPrincipalName $NewUserPrincipalName
                    SourceUserPrincipalName = $user.UserPrincipalName;
                    TargetUserPrincipalName = $NewUserPrincipalName
                }
            }
        } catch {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            Write-Error "Problem with: $($FailedItem); Error: $($ErrorMessage)"
        }
    }
}  
END { }
