Clear-Host
$largeFiles = (GCI -Path I:\ -Recurse -Filter *.* | ? { $_.length -ge 100000000 }) | Sort-Object { $_.Length } 
$largeFiles | % { Write-Host "$(($_.Length / 1024 / 1024).ToString("#,##0.00")) MB`t`t$($_.LastWriteTime.ToString("dd-MMM-yyyy hh:mm:ss"))`t`t$($_.Extension)`t`t$($_.FullName)" }