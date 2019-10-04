Clear-Host

#$computers = Get-ADComputer -Filter {enabled -eq $true} -Properties Name | select @{Name="ComputerName";Expression={$_.Name}}
#$servers = Get-ADComputer -Filter {enabled -eq $true} -SearchBase "OU=<OU>, DC=<DC>, DC=<DC>, DC=<DC>" -Properties Name | select @{Name="ComputerName";Expression={$_.Name}}

$serverlist = get-content "c:\scripts\servers.txt" -ErrorAction SilentlyContinue

foreach($server in $serverlist){
  if((Test-Connection -ComputerName $server -Quiet) -eq $true){
    
    Write-Host "Checking Server: $server" -ForegroundColor Cyan

    get-eventlog system | where-object {$_.eventid -eq 6006} | select -first 10
    }
}