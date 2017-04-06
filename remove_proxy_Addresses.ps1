
foreach ($UserObj in Get-MsolUser -all | ?{$_.proxyaddresses -match "isa.com.au"}) {
	$user = Get-MSOLUser $UserObj -Properties mail,department,ProxyAddresses
	$user.ProxyAddresses = $UserObj.UserPrincipalName
	Set-MSOLUser -instance $user 
}