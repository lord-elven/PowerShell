if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

Import-Module VMware.VimAutomation.Core

Connect-VIServer <VM SERVER>

Write-Progress -Activity 'Running Script'

New-Item -ItemType Directory -Path <PATH> -Force

$vms = Get-VM -Name *
$vms | Export-Csv '<PATH>\VMReport.csv'
Start-Process '<PATH>\VMReport.csv'

Write-Host 'Script Finished'



