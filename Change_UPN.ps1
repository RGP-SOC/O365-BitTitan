#Replace with the old suffix
$oldSuffix = 'ISA.local'

#Replace with the new suffix
$newSuffix = 'isa.com.au'

#Replace with the OU you want to change suffixes for
$ou = "DC=ISA,DC=local"

#Replace with the name of your AD server
$server = "ISA-FS1"

Get-ADUser -SearchBase $ou -filter * | ForEach-Object {
$newUpn = $_.UserPrincipalName.Replace($oldSuffix,$newSuffix)
$_ | Set-ADUser -server $server -UserPrincipalName $newUpn
}