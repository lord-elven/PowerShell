$servers = Get-Content C:\Scripts\servers.txt 

foreach($server in $servers) {
    Write-Host "Checking Server $server..." -ForegroundColor Cyan
    $redcloak = Get-Service -ComputerName $server -ServiceName *redcloak* -ErrorAction SilentlyContinue
    
        if($redcloak -like $redcloak) {
            Write-Host "RedCloak is running on $server" -ForegroundColor Yellow
            }
            Else {
            Write-Host "RedCloak is Not Running" -ForegroundColor Red
            }
        
}