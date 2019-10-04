#clear-host
$serverlist = Get-Content "c:\scripts\servers.txt" -ErrorAction SilentlyContinue


function Get-PageFileInfo()
{
    $data = foreach ($server in $serverlist) { 
        $physicalmem  = Get-WmiObject -computer $server Win32_ComputerSystem | 
                        where {$_.TotalPhysicalMemory} 

        $Pagefilesize = Get-WmiObject -computer $server Win32_pagefileusage | 
                        where {$_.AllocatedBaseSize}
    
        New-Object psobject -Property @{
            Server   = $server
            RAM      = "$([math]::round(($physicalmem.TotalPhysicalMemory)/1GB,0)) GB"
            PageFile = "$([math]::round(($Pagefilesize.AllocatedBaseSize)/1024) ) GB"
        } 
    }
}  

#$data | Out-File -FilePath "c:\scripts\pagefileinfo.txt"
Get-PageFileInfo