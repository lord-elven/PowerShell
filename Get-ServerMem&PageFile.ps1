﻿# Get memory and page file location.
#$serverlist="server1","server2"
$serverlist=get-content "C:\scripts\servers.txt" -ErrorAction SilentlyContinue

    $Pagefilesize = Get-WmiObject -computer $server Win32_pagefileusage | 
$data | Export-Csv "c:\result.csv" -NoTypeInformation