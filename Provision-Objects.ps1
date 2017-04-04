<#
.SYNOPSIS
Provisions objects from one Office 365 tentant in another
.PARAMETER SourceTenant
The name of the source tentant.
.PARAMETER TargetTenant
The name of the target tentant.
.PARAMETER VanityDomain
An array of "vanity domains" in use by the organisation.
.PARAMETER SourceCredential
The credentials to log onto the source tenant.
.PARAMETER TargetCredential
The credentials to log onto the source tenant.
.PARAMETER RecipientTypeDetails
List of mailbox types to create.
.PARAMETER DistributionLists
Sets the script to replicate distribution lists instead.
.EXAMPLE
./Provision-Objects.ps1 -Credential (Get-Credential) -SourceTenant sourcecompany.onmicrosoft.com -TargetTenant targettenant.onmicrosoft.com 
#>
[cmdletbinding(SupportsShouldProcess=$True)]
Param (
    [Parameter(Mandatory=$true)]
    [String]$SourceTenant,
    [Parameter(Mandatory=$true)]
    [String]$TargetTenant,
    [String[]]$VanityDomain = $SourceTenant,
    [PsCredential]$SourceCredential,
    [PsCredential]$TargetCredential,
    [Parameter(ParameterSetName='Mailboxes')]
    [ValidateSet("SharedMailbox", "EquipmentMailbox", "RoomMailbox", "Contact")]
    [String[]]$RecipientTypeDetails = @("SharedMailbox", "EquipmentMailbox", "RoomMailbox", "Contact"),
    [Parameter(ParameterSetName='Groups')]
    [Switch]$DistributionLists
)
BEGIN {
    $SourceSession = New-PsSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -AllowRedirect -Authentication Basic -Credential $SourceCredential -EA Stop
    Import-PsSession -AllowClobber $SourceSession -Prefix Source -EA Stop | Out-Null
    $TargetSession = New-PsSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -AllowRedirect -Authentication Basic -Credential $TargetCredential -EA Stop
    Import-PsSession -AllowClobber $TargetSession -Prefix Target -EA Stop | Out-Null
}
PROCESS {
    foreach ($d in $VanityDomain) {
        try {
            if ($DistributionLists) {
                # Handle distribution lists
                foreach ($SourceList in (Get-SourceDistributionGroup -ResultSize Unlimited | ? { $_.PrimarySmtpAddress -like "*@$($d)" } )) {
                    $TargetList = (Get-TargetDistributionGroup -Identity $SourceList.Name -EA SilentlyContinue)
                    if ($TargetList) {
                        $TargetExists = $true
                    } else {
                        $TargetExists = $false
                        if ($pscmdlet.ShouldProcess("$TargetAlias", "New-DistributionGroup")) {
                            $NewTargetList = @{
                                Name = $SourceList.Name;
                                DisplayName = $SourceList.DisplayName
                            }
                            $TargetList = New-TargetDistributionGroup @NewTargetList -EA Continue
                            if ($TargetList) {
                                $TargetCreated = $true
                            } else {
                                $TargetCreated = $false
                            }
                        }
                    }
                    $out = @{
                        Alias = $SourceList.Alias;
                        SourcePrimarySmtpAddress = $SourceMailbox.UserPrincipalName.Replace("@$($d)", "@$($SourceTenant)");
                        TargetUserPrincipalName = $TargetMailbox.UserPrincipalName;
                        RecipientTypeDetails = $SourceMailbox.RecipientTypeDetails;
                        TargetExists = $TargetExists;
                        TargetCreated = $TargetCreated
                    }
                }
            } else {
                # Handle mailboxes
                foreach ($SourceMailbox in (Get-SourceMailbox -ResultSize Unlimited | ? { ($RecipientTypeDetails -contains $_.RecipientTypeDetails) -and ($_.UserPrincipalName -like "*@$($d)") } )) {
                    $TargetMailbox = (Get-TargetMailbox -RecipientTypeDetails $SourceMailbox.RecipientTypeDetails -Identity $SourceMailbox.UserPrincipalName.Replace("@$($d)", "@$($TargetTenant)") -EA SilentlyContinue)
                    if ($TargetMailbox) {
                        $TargetExists = $true
                    } else {
                        $TargetExists = $false
                        $TargetUserPrincipalName = $SourceMailbox.UserPrincipalName.Replace("@$($d)", "@$($TargetTenant)")
                        if ($pscmdlet.ShouldProcess("$TargetUserPrincipalName", "New-Mailbox")) {
                            $NewTargetMailbox = @{
                                Name = $SourceMailbox.Name;
                                FirstName = $SourceMailbox.FirstName;
                                LastName = $SourceMailbox.LastName;
                                Initials = $SourceMailbox.Initials;
                                DisplayName = $SourceMailbox.DisplayName
                            }
                            switch ($SourceMailbox.RecipientTypeDetails) {
                                "RoomMailbox" {
                                    $NewTargetMailbox.Room = $true
                                }
                                "SharedMailbox" {
                                    $NewTargetMailbox.Shared = $true
                                }
                                "EquipmentMailbox" {
                                    $NewTargetMailbox.Equipment = $true
                                }
                            }
                            $TargetMailbox = New-TargetMailbox @NewTargetMailbox -EA Continue
                            if ($TargetMailbox) {
                                $TargetCreated = $true
                            } else {
                                $TargetCreated = $false
                                $TargetMailbox = @{
                                    UserPrincipalName = "N/A"
                                }
                            }
                        }
                    }
                    $out = @{
                        Alias = $SourceMailbox.Alias;
                        SourceUserPrincipalName = $SourceMailbox.UserPrincipalName.Replace("@$($d)", "@$($SourceTenant)");
                        TargetUserPrincipalName = $TargetMailbox.UserPrincipalName;
                        RecipientTypeDetails = $SourceMailbox.RecipientTypeDetails;
                        TargetExists = $TargetExists;
                        TargetCreated = $TargetCreated
                    }
                }
            }
            # Return output to pipeline
            [PsCustomObject]$out
        } catch {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            Write-Error "Problem with: $($FailedItem); Error: $($ErrorMessage)"
        }
    }
}  
END {
    # Remove PsSession if required
    if ($SourceSession) {
        Remove-PsSession $SourceSession
    }
    if ($TargetSession) {
        Remove-PsSession $TargetSession
    }
}
