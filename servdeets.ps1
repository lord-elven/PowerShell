$servers = get-qadcomputer -searchroot FQDN/SITE/SRV
#foreach ($Server in $Servers)
#{
#    $Addresses = $null
#    try {
#        $Addresses = [System.Net.Dns]::GetHostAddresses("$Server").IPAddressToString
#    }
#    catch { 
#        $Addresses = "Server IP cannot resolve."
#    }
#    foreach($Address in $addresses) {
#        write-host $Server, $Address 
#    }
#}

#$servers = get-content List_of_Servers.txt
$serversAndIps = "List_of_servers_with_ips.csv"

$results =@()
  foreach ($server in $servers )
   {
	$result=@() 
	$result = "" | Select ServerName , IPaddress
	$result.ipaddress = (gwmi Win32_NetworkAdapterConfiguration -computername $server | Where { $_.IPAddress }  | select -expand ipaddress  )[0]
	$result.servername = $server
	$results += $result
   }
   
$results | export-csv -NoTypeInformation $serversandips