#This PS will perform the following tasks
#Turns local firewall off
#Activates Windows
#Adds machine to domain and renames it based on the prompts

start-process powershell -verb runas
#netsh advfirewall set allprofiles state off
#cscript c:\windows\system32\slmgr.vbs /ato
#Add-Computer -Credential <username> -DomainName <FQDN> –OUPath “OU=<OU>,OU=<OU>,DC=<DC>,DC=<DC>” -passthru -verbose;restart-computer

$oldName = Read-Host -Prompt "Enter Original Computer Name"
$newName = Read-Host -Prompt "Enter New Computer Name"
$username = Read-Host -Prompt "Enter Domain user name"
$password = Read-Host -Prompt "Enter password for $user" -AsSecureString 
$credential = New-Object System.Management.Automation.PSCredential($username,$password) 
#Rename-Computer -NewName $newName -LocalCredential admin -Force
$ComputerInfo = Get-WmiObject -Class Win32_ComputerSystem
$ComputerInfo.Rename($NewName)
Write-Host "Changing name and joining ESI domain, please wait..." -ForegroundColor Red
Add-Computer -ComputerName $oldName -NewName $newName -DomainName <FQDN> –OUPath “OU=<OU>,DC=<DC>,DC=<DC>” -Credential $credential -verbose
#restart-computer