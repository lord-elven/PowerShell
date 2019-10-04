#==========================[Hardware-Report]============================#
#																		#
#	Nom Du Script: Hardware-Report.ps1									#
#	Version: 0.3														#	
#	Auteur: Vincent KONIECZNY											#
#	Date: 26/06/2012													#
#																		#
#=======================================================================#

#$ErrorActionPreference = "SilentlyContinue"

$ComputerName = Read-Host 'Enter a computer name or press <Enter> for localhost'
if ($ComputerName.length -eq 0) {$ComputerName = "$env:computername"}

$computername

If (!(Test-Path "c:\scripts\")) {
	write-host "*********************************************************" -BackgroundColor DarkGray -ForegroundColor Yellow
	write-host "*  /!\ the C:\Scripts\ Directory Does Not Exist.  /!\   *" -BackgroundColor DarkGray -ForegroundColor Yellow
	Write-host "*       Please create it and restart the script.        *" -BackgroundColor DarkGray -ForegroundColor Yellow
	write-host "*********************************************************" -BackgroundColor DarkGray -ForegroundColor Yellow
}
$IE = New-Object -ComObject InternetExplorer.Application
$IE.Visible = $true
$IE.ToolBar = 0
$today = Get-Date -Format dd-MM-yyyy
$file = "c:\scripts\$ComputerName" + "-" + $today + "-Report.html"

######## Create HTML Page #######

$HTML= '<HTML>
	<style type="text/css">
		.entete{width:500px;margin:auto;text-align:left;border:1px dashed #004569;background-color:#bfd3fa;font-family:arial;font-size:10pt}
		TABLE{border-style:solid;border-color:#375D81;border-width:1px;font-family:arial;border-collapse:collapse;font-size:10pt;background-color:#375D81;}
		CAPTION{border-style:solid;border-color:#004569;border-width:1px;font-weight:bold;background-color:#004569;color:white;font-family: arial, sans-serif;letter-spacing: 1.2pt;word-spacing: 0.2pt;text-align:left;}
		TH{color:white}
		TR{}
		table TD.first{background-color:#bfd3fa}
		TD{background-color:white;border-bottom-style:solid;border-bottom-width:1px;border-bottom-color:#8fa3ca;}
	</style>
	<head>
		<title>Computer Report</title>
	</head>
	<BODY>
		<div class="entete"><b>Date: </b>' + $today + '<br><b>Machine: </b>' + $ComputerName + '</div><br>' | Out-File -FilePath ($file)

######## Ouverture d'IE #######
$IE.navigate($file)

######## Lecture WMI  #######
$W32OS = Get-WmiObject Win32_OperatingSystem -ComputerName $ComputerName
$hard = Get-WmiObject Win32_ComputerSystem -ComputerName $ComputerName
$proc = Get-WmiObject Win32_Processor -ComputerName $ComputerName | where {$_.DeviceID -eq "CPU0"}
$W32HDD =  Get-WmiObject win32_logicaldisk -ComputerName $ComputerName
$W32Shares = Get-WmiObject -query "SELECT name, path,caption FROM Win32_Share WHERE type!=1 AND path!=''" -computername $computername -namespace "root\CIMV2"
$SystEvent = Get-Eventlog -EntryType Error, Warning -log System -Newest 10 -ComputerName $ComputerName| Select-Object 
$AppEvent = Get-Eventlog -EntryType Error, Warning -log Application -Newest 10 -ComputerName $ComputerName
$NIC = Get-wmiObject Win32_NetworkAdapterConfiguration -ComputerName $ComputerName| Select-Object -Property index,Description,MACAddress,IPAddress,IPSubnet,DefaultIPGateway,DNSServerSearchOrder,DHCPEnabled,DHCPServer,DNSDomain,DNSDomainSuffixSearchOrder
######## Tableau System Information #######
$HTML += '<DIV style = "width:100%">
	<DIV style = "float:left;width:49%">
		<TABLE width=100%>
			<CAPTION>System Information</CAPTION>
			<TBODY>
				<TR>  
					<TD class="first">OS Version</TD>
					<TD>' + $W32OS.Caption + ' '+ $W32OS.OSArchitecture + '</TD>
				</TR>
				<TR>  
					<TD class="first">Version</TD>
					<TD>' + $W32OS.Version + '</TD>
				</TR>
				<TR>  
					<TD class="first">Service Pack</TD>
					<TD>' + $W32OS.CSDVersion + '</TD>
				</TR>
				<TR>  
					<TD class="first">Installation Date</TD>
					<TD>' + ([WMI]'').ConvertToDateTime($W32OS.InstallDate) + '</TD>
				</TR>
				<TR>  
					<TD class="first">Windows Directory</TD>
					<TD>' + $W32OS.WindowsDirectory + '</TD>
				</TR>
				<TR>  
					<TD class="first">Model</TD>
					<TD>' + $hard.Manufacturer + ' ' + $hard.Model + '</TD>
				</TR>
				<TR>  
					<TD class="first">Usable Memory</TD>
					<TD>' + [Math]::Round($hard.TotalPhysicalMemory/1GB,2) + ' Gb' + '</TD>
				</TR>
				<TR>  
					<TD class="first">Usable Swap</TD>
					<TD>' + [Math]::Round($W32OS.TotalVirtualMemorySize/1MB,2) + ' Gb' + '</TD>
				</TR>
				<TR>  
					<TD class="first">Processor</TD>
					<TD>' + $proc.name + '</TD>
				</TR>
				<TR>  
					<TD class="first">Logical Processors</TD>
					<TD>' + $proc.NumberOfLogicalProcessors + '</TD>
				</TR>
				<TR>  
					<TD class="first">Number Of Cores</TD>
					<TD>' + $proc.NumberOfCores + '</TD>
				</TR>
				<TR>  
					<TD class="first">Manufacturer</TD>
					<TD>' + $proc.Manufacturer + '</TD>
				</TR>
			</TBODY>
		</TABLE>
	</DIV>
	<DIV style = "float:right; width:49%;">
		<TABLE width=100%>
			<CAPTION>Drives</CAPTION>
			<THEAD>
		  		<TR>
					<TH>Volume</TH>
					<TH>Size (Gb)</TH>
					<TH>Free Space</TH>
					<TH>Usage</TH>
					<TH>Format</TH>
					<TH>Drive Type</TH>
		  		</TR>
			</THEAD>
			<TBODY>'| Out-File -FilePath ($file) -Append
######## Drives Table #######
$IE.Refresh()
foreach ($Drive in $W32HDD) {
	Switch ($Drive.DriveType) {
		1{ $Drivetype = " Unknown" } 
		2{ $Drivetype = " Floppy" } 
		3{ $Drivetype = " Hard Drive" } 
		4{ $Drivetype = " Network Drive" } 
		5{ $Drivetype = " CD" } 
		6{ $Drivetype = " RAM Disk" } 
	}
$Usage = [Math]::Round(100 - ((100* $Drive.FreeSpace)/$Drive.Size),0)	
$HTML += '		  <TR>  
			<TD Align ="center">' + $Drive.Caption + '</TD>
			<TD Align ="center"> '+ [Math]::Round(($Drive.Size/1GB),2) + '</TD>
			<TD Align ="center">'+ [Math]::Round(($Drive.FreeSpace/1GB),2) + '</TD>
			<TD Align ="center"><div style="margin: auto; text-align: center; width: 100%;" title="15%"><div style="text-align: left; margin: 2px auto; font-size: 0px; line-height: 0px; border: solid 1px #AAAAAA; background: #DDDDDD; overflow: hidden; "><div style="font-size: 0px; line-height: 0px; height: 3px; min-width: 0%; max-width: '+$Usage+'%; width: '+$Usage+'%; background: #1D3D8D; "><!----></div></div><div style="font-size: 8pt; font-family: sans-serif; "></div></div></TD>
			<TD Align ="center">' + $Drive.FileSystem + '</TD>
			<TD Align ="center">' + $Drivetype + '</TD>
		  </TR>'| Out-File -FilePath ($file) -Append
$Drivetype = $null
$Usage = 0
}
######## Shares Table #######
$HTML+='		</TBODY>
		</TABLE>
		<br>
		<TABLE width=100%>
			<CAPTION>Share List</CAPTION>
			<THEAD>
		  		<TR>
					<TH>Name</TH>
					<TH>Path</TH>
					<TH>Description</TH>
		  		</TR>
			</THEAD>
			<TBODY>'| Out-File -FilePath ($file) -Append
foreach ($Share in $W32Shares) {
$HTML += '		  <TR>  
			<TD Align ="left">' + $Share.Name + '</TD>
			<TD Align ="left">' + $Share.Path + '</TD>
			<TD Align ="left">' + $Share.Description + '</TD>
		  </TR>'| Out-File -FilePath ($file) -Append
}

######## System Events Table #######
$HTML += '			</TBODY>
		</TABLE>
	</DIV>
<div style="clear:both;"></div>
</DIV>
<DIV style = "width:100%;padding-top:10px;padding-bottom: 10px;">
	<DIV style = "float:left;width:49%;">
		<TABLE width=100%>
			<CAPTION>System Events</CAPTION>
			<THEAD>
		  		<TR>
					<TH>Type</TH>
					<TH>Time Generated</TH>
					<TH>Source</TH>
					<TH>ID</TH>
		  		</TR>
			</THEAD>
			<TBODY>'| Out-File -FilePath ($file) -Append
$IE.Refresh()
Foreach ($event in $SystEvent) {
$HTML += '		  <TR>  
			<TD Align ="center">' + $event.EntryType + '</TD>
			<TD Align ="center"> '+ $event.TimeGenerated + '</TD>
			<TD Align ="center">'+ $event.Source + '</TD>
			<TD Align ="center">' + $event.EventID + '</TD>
		  </TR>'| Out-File -FilePath ($file) -Append
$IE.Refresh()
}
######## Application Events Table #######
$HTML += '			</TBODY>
		</TABLE>
	</DIV>
	<DIV style = "float:right;width:49%">
		<TABLE width=100%>
			<CAPTION>Application Events</CAPTION>
			<THEAD>
		  		<TR>
					<TH>Type</TH>
					<TH>Time Generated</TH>
					<TH>Source</TH>
					<TH>ID</TH>
		  		</TR>
			</THEAD>
			<TBODY>'| Out-File -FilePath ($file) -Append
$IE.Refresh()
Foreach ($event in $AppEvent) {
$HTML += '		  <TR>  
			<TD Align ="center">' + $event.EntryType + '</TD>
			<TD Align ="center"> '+ $event.TimeGenerated + '</TD>
			<TD Align ="center">'+ $event.Source + '</TD>
			<TD Align ="center">' + $event.EventID + '</TD>
		  </TR>'| Out-File -FilePath ($file) -Append
$IE.Refresh()
}
######## Network Cards Table #######
$HTML += '			</TBODY>
		</TABLE>
	</DIV>
	<div style="clear:both;"></div>
</DIV>
<DIV style = "width:100%">
<TABLE width=100%>
			<CAPTION>Network Cards</CAPTION>
			<THEAD>
		  		<TR>
					<TH>ID</TH>
					<TH>Description</TH>
					<TH>MAC Address</TH>
					<TH>IP Address</TH>
					<TH>Subnet</TH>
					<TH>Gateway</TH>
					<TH>DNS Servers</TH>
					<TH>DHCP?</TH>
					<TH>DHCP Server</TH>
					<TH>DNS Domain</TH>
					<TH>DNS Suffixes</TH>
		  		</TR>
			</THEAD>
			<TBODY>'| Out-File -FilePath ($file) -Append
$IE.Refresh()
Foreach ($card in $NIC) {
	$HTML += '		  <TR>  
			<TD Align ="center"; style = "font-size: 8pt;background-color:#bfd3fa">' + $card.index + '</TD>
			<TD Align ="center"; style = "font-size: 8pt;"> '+ $card.Description + '</TD>
			<TD Align ="center"; style = "font-size: 8pt;background-color:#bfd3fa">'+ $card.MACAddress + '</TD>
			<TD Align ="center"; style = "font-size: 8pt;">' + $card.IPAddress + '</TD>
			<TD Align ="center"; style = "font-size: 8pt;background-color:#bfd3fa">' + $card.IPSubnet + '</TD>
			<TD Align ="center"; style = "font-size: 8pt;">' + $card.DefaultIPGateway + '</TD>
			<TD Align ="center"; style = "font-size: 8pt;background-color:#bfd3fa">' + $card.DNSServerSearchOrder + '</TD>
			<TD Align ="center"; style = "font-size: 8pt;">' + $card.DHCPEnabled + '</TD>
			<TD Align ="center"; style = "font-size: 8pt;background-color:#bfd3fa">' + $card.DHCPServer + '</TD>
			<TD Align ="center"; style = "font-size: 8pt;">' + $card.DNSDomain + '</TD>
			<TD Align ="center"; style = "font-size: 8pt;background-color:#bfd3fa">' + $card.DNSDomainSuffixSearchOrder + '</TD>
		  </TR>'| Out-File -FilePath ($file) -Append
$IE.Refresh()
}
######## Software Table #######
$HTML += '			</TBODY>
		</TABLE>
	<div style="clear:both;"></div>
	</DIV>
	<DIV style = "width:100%;padding-top:10px;padding-bottom: 10px;">
<TABLE width=100%>
			<CAPTION>Installed Software</CAPTION>
			<THEAD>
		  		<TR>
					<TH>Name</TH>
					<TH>Version</TH>
					<TH>Publisher</TH>
					<TH>Install Date</TH>
		  		</TR>
			</THEAD>
			<TBODY>'| Out-File -FilePath ($file) -Append
$IE.Refresh()	
	
IF ($proc.Addresswidth -eq 32){
		$SubBranch="SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
		$registry=[microsoft.win32.registrykey]::OpenRemoteBaseKey("LocalMachine","$ComputerName") 
		$SoftList=$registry.OpenSubKey($Subbranch)
	foreach ($Software in $SoftList.GetSubKeyNames()) {   
		IF ($SoftList.OpenSubKey($Software).getvalue("Displayname") -notlike "*KB*" -and $SoftList.OpenSubKey($Software).getvalue("Displayname") -ne $null) {
			$HTML += '		  <TR>  
						<TD Align ="center">' + $SoftList.OpenSubKey($Software).getvalue("Displayname") + '</TD>
						<TD Align ="center"> '+ $SoftList.OpenSubKey($Software).getvalue("DisplayVersion") + '</TD>
						<TD Align ="center"> '+ $SoftList.OpenSubKey($Software).getvalue("Publisher") + '</TD>
						<TD Align ="center"> '+ ([datetime]::ParseExact($SoftList.OpenSubKey($Software).getvalue("InstallDate"),”yyyyMMdd”,$null)).toshortdatestring() + '</TD>
		  </TR>'| Out-File -FilePath ($file) -Append
		}
	} 
}
elseif ($proc.Addresswidth -eq 64) {
	$SubBranch="SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
	$registry=[microsoft.win32.registrykey]::OpenRemoteBaseKey("LocalMachine","$ComputerName") 
	$SoftList=$registry.OpenSubKey($Subbranch)
	foreach ($Software in $SoftList.GetSubKeyNames()) {
		IF ($SoftList.OpenSubKey($Software).getvalue("Displayname") -notlike "*KB*" -and $SoftList.OpenSubKey($Software).getvalue("Displayname") -ne $null) {
				$HTML += '		  <TR>  
			<TD Align ="center">' + $SoftList.OpenSubKey($Software).getvalue("Displayname") + '</TD>
			<TD Align ="center"> '+ $SoftList.OpenSubKey($Software).getvalue("DisplayVersion") + '</TD>
			<TD Align ="center"> '+ $SoftList.OpenSubKey($Software).getvalue("Publisher") + '</TD>
			<TD Align ="center"> '+ ([datetime]::ParseExact($SoftList.OpenSubKey($Software).getvalue("InstallDate"),”yyyyMMdd”,$null)).toshortdatestring() + '</TD>
</TR>'| Out-File -FilePath ($file) -Append
			}
	}
			
	$SubBranch="SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
	$registry=[microsoft.win32.registrykey]::OpenRemoteBaseKey("LocalMachine","$ComputerName") 
	$SoftList=$registry.OpenSubKey($Subbranch)

	foreach ($Software in $SoftList.GetSubKeyNames()) {
			IF ($SoftList.OpenSubKey($Software).getvalue("Displayname") -notlike "*KB*" -and $SoftList.OpenSubKey($Software).getvalue("Displayname") -ne $null) {
				$HTML += '		  <TR>  
			<TD Align ="center">' + $SoftList.OpenSubKey($Software).getvalue("Displayname") + '</TD>
			<TD Align ="center"> '+ $SoftList.OpenSubKey($Software).getvalue("DisplayVersion") + '</TD>
			<TD Align ="center"> '+ $SoftList.OpenSubKey($Software).getvalue("Publisher") + '</TD>
			<TD Align ="center"> '+ ([datetime]::ParseExact($SoftList.OpenSubKey($Software).getvalue("InstallDate"),”yyyyMMdd”,$null)).toshortdatestring() + '</TD>
</TR>'| Out-File -FilePath ($file) -Append
			}
	}
}

######## Page End #######

$HTML += '			</TBODY>
		</TABLE>
	<div style="clear:both;"></div>
	</DIV>
</BODY>
</HTML>'| Out-File -FilePath ($file) -Append
$IE.Refresh()

write-host "*************************" -BackgroundColor DarkGreen -ForegroundColor Green
write-host "*  Inventory Finished!  *" -BackgroundColor DarkGreen -ForegroundColor Green
write-host "*************************" -BackgroundColor DarkGreen -ForegroundColor Green
write-host "File Path: [" $file "]" -ForegroundColor Magenta