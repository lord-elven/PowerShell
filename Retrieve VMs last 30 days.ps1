Import-Module VMware.VimAutomation.Core

Connect-VIServer <VCENTER SERVER>

Write-Progress -Activity 'Running Script'

# Location of your report file.
$ReportPath = Read-Host "Enter Path eg E:\Reports\"
$ReportName = Read-Host "Enter FileName eg Report.csv"
$csv = "$ReportPath$ReportName"

#Creates New Directory for the Report
New-Item -ItemType Directory -Path $ReportPath -Force

#$vms = Get-VM -Name *

$CDT = Get-Date # CDT stands for 'Current Date and Time' :)
Get-Cluster -Name <CLUSTER NAME> | Get-VM |`
Get-VIEvent -Types Info -Start $CDT.AddDays(-30) -Finish $CDT |`
Where {`
      $_.Gettype().Name -eq "VmBeingDeployedEvent"`
  -or $_.Gettype().Name -eq "VmCreatedEvent"`
  -or $_.Gettype().Name -eq "VmRegisteredEvent"} |`
Select UserName, CreatedTime, FullFormattedMessage |`
Export-Csv $csv
Start-Process $csv

Write-Host 'Script Finished'


