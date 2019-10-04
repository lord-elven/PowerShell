<####################################################################### Name         : Web Servers Inventory Running IIS - DGRAY 2019																				# Version      : 1.0												# Description  : This script will collect some information about the IIS Servers in the domain												######################################################################>
import-module activedirectory
$servers=Get-ADComputer -Filter {operatingsystem -Like "Windows server*"} | select -ExpandProperty Name
$servers | Out-File "C:\Scripts\servers.txt" -append default
$serversall = (Get-Content "C:\Scripts\servers.txt") 
Start-Transcript -path "C:\Scripts\output.txt" -append default
foreach($vm in $serversall)
{ $iis = get-wmiobject Win32_Service -ComputerName $vm -Filter "name='W3SVC'"
if($iis.State -eq "Running") 
{
Write-Host "IIS is running on $vm" -BackgroundColor DarkBlue -ForegroundColor DarkYellow
$ipinfo=Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $vm | Select IPAddress,DefaultIPGateway,PSComputerName,Caption,DNSHostName,IPSubnet | 
Where-Object {$_.IPaddress -like "1*"}
$ipAddress=$ipinfo.IPAddress
$Gateway=$ipinfo.DefaultIPGateway
$ipsubnet=$ipinfo.IPSubnet
$hwinfo=Get-WmiObject Win32_Computersystem -ComputerName $vm | Select Name,Domain,Manufacturer,Model,PrimaryOwnerName,TotalPhysicalMemory,NumberOfLogicalProcessors 
$HostName=$hwinfo.Name
$DomainName=$hwinfo.Domain
$Man=$hwinfo.Manufacturer
$Model=$hwinfo.Model
$Memory=$hwinfo.TotalPhysicalMemory
$osinfo=Get-WmiObject Win32_OPERATingsystem -ComputerName $vm | Select Caption,CSName,OSArchitecture,ServicePackMajorVersion,SystemDrive,Version
$caption=$osinfo.Caption
$arch=$osinfo.OSArchitecture
$spversion=$osinfo.ServicePackMajorVersion
$drive=$osinfo.SystemDrive
$osver=$osinfo.Version
$allinfo=$HostName+";"+$DomainName+";"+$ipAddress+";"+$ipsubnet+";"+$Gateway+";"+$Memory+";"+$Man+";"+$Model+";"+$caption+";"+$arch+";"+$spversion+";"+$drive+";"+$osver
## Get the Service pack level
$allinfo | Out-File "C:\Scripts\WebServers.txt" -Append default 
}
}
Stop-Transcript