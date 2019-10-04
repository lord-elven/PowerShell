# Get memory and page file location.
#$serverlist="server1","server2"
$serverlist=get-content "C:\scripts\servers.txt" -ErrorAction SilentlyContinue
$data = foreach ($server in $serverlist) {    write-host "Checking Server: $server" -ForegroundColor yellow         $physicalmem  = Get-WmiObject -computer $server Win32_ComputerSystem |                     where {$_.TotalPhysicalMemory} 
    $Pagefilesize = Get-WmiObject -computer $server Win32_pagefileusage |                     where {$_.AllocatedBaseSize}        New-Object psobject -Property @{        Server   = $server        RAM      = "$([math]::round(($physicalmem.TotalPhysicalMemory)/1GB,0)) GB"        PageFile = "$([math]::round(($Pagefilesize.AllocatedBaseSize)/1024) ) GB"    } }  
$data | Export-Csv "c:\result.csv" -NoTypeInformation