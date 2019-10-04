Clear-Host

#$computers = Get-ADComputer -Filter {enabled -eq $true} -Properties Name | select @{Name="ComputerName";Expression={$_.Name}}
$servers = Get-ADComputer -Filter {enabled -eq $true} -SearchBase "OU=<OU>, DC=<DC>, DC=<DC>, DC=<DC>" -Properties Name | select @{Name="ComputerName";Expression={$_.Name}}

foreach($server in $servers){
  if((Test-Connection -ComputerName $server -Quiet) -eq $true){
    
    #$RedCloak = Get-service -ComputerName $computer | Where DisplayName -like RedCloak* -ErrorAction SilentlyContinue
    Write-Host "Checking Server: $server" -ForegroundColor Cyan

    $RedCloak = Get-Service -ComputerName $server -ServiceName *redcloak* -ErrorAction SilentlyContinue
    
    if ($RedCloak -like $RedCloak) {
        Write-Host "RedCloak installed and is Running" -ForegroundColor Yellow
        $servicestate = "Installed"
        }
        Else {
            Write-Host "RedCloak is Not Running or installed" -ForegroundColor Red
            $servicestate = "Not Installed"
        }
    }

    $obj = New-Object PSCustomObject -Property @{    "Service Status" = $servicestate    "Server Name" = $server    }    $obj | Export-Csv C:\tmp\redcloakstate.csv -Append -NoTypeInformation
}



PAUSE