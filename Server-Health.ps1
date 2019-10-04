<#===================================================================================================================
Name	: Server-Health.ps1
Purpose	: Produces a Health Report for servers including RAM, CPU, Uptime and these services: BladeLogic / CrowdStrike / WSUS 
Author  : DGray
Date Created : 01/03/2018
Last Revised : 27/03/2018
=====================================================================================================================
TODO:
# Get list of servers from vCenter and / or OU
# Check services (derived from checkmyserver.ps1)
====================================================================================================================#>
$DateStamp = (Get-Date -Format D)
$FileDateStamp = Get-Date -Format ddMMyyyy
$ServerList = "servers.txt"
$ScriptPath = Get-Location
$ReportFileName = "$ScriptPath\ServerHealthStatus-$FileDateStamp.html"
$ReportTitle = "Server Health Status"

<#=================================================================
Email settings (Commented out for now - might use at a later date)
$EmailTo = "EMAIL Address"
$EmailFrom = "EMAIL Address"
$EmailSubject = "Server Health Status for $DateStamp"
$SMTPServer = "SMTP SERVER"
==================================================================#>
$BGcolourTbl = "#EAECEE" #grey
$BGcolourGood = "#4CBB17" #green
$BGcolourWarn = "#FFFC33" #yellow
$BGcolourCrit = "#FF0000" #red

# Number of days for patch day tolerance
$PatchDaysWarning = 30
$PatchDaysCritical = 90

# Max uptime in days we are going to allow a server to be up without a reboot
$UptimeDayMax = 60

# Min % of RAM free before we are concerned
$RAMFree = 15

# Thresholds: % of available disk space to trigger colours in report. Warning is yellow, Critical is red
$Warning = 15
$Critical = 5

# Clear screen then show progress
Clear
Write-Host "Creating report..." -foreground "Yellow"

# Create output file and nullify display output
New-Item -ItemType file $ReportFileName -Force > $null

<#==================================================
Write the HTML Header to the file
==================================================#>
Add-Content $ReportFileName "<html>"
Add-Content $ReportFileName "<head>"
Add-Content $ReportFileName "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>"
Add-Content $ReportFileName '<title>Server Health Status</title>'
Add-Content $ReportFileName '<STYLE TYPE="text/css">'
Add-Content $ReportFileName "td {"
Add-Content $ReportFileName "font-family: Tahoma;"
Add-Content $ReportFileName "font-size: 11px;"
Add-Content $ReportFileName "border-top: 1px solid #999999;"
Add-Content $ReportFileName "border-right: 1px solid #999999;"
Add-Content $ReportFileName "border-bottom: 1px solid #999999;"
Add-Content $ReportFileName "border-left: 1px solid #999999;"
Add-Content $ReportFileName "padding-top: 0px;"
Add-Content $ReportFileName "padding-right: 0px;"
Add-Content $ReportFileName "padding-bottom: 0px;"
Add-Content $ReportFileName "padding-left: 0px;"
Add-Content $ReportFileName "}"
Add-Content $ReportFileName "body {"
Add-Content $ReportFileName "margin-left: 5px;"
Add-Content $ReportFileName "margin-top: 5px;"
Add-Content $ReportFileName "margin-right: 0px;"
Add-Content $ReportFileName "margin-bottom: 10px;"
Add-Content $ReportFileName "table {"
Add-Content $ReportFileName "border: thin solid #000000;"
Add-Content $ReportFileName "}"
Add-Content $ReportFileName "</style>"
Add-Content $ReportFileName "</head>"
Add-Content $ReportFileName "<body>"
Add-Content $ReportFileName "<table width='75%' align=`"center`">"
Add-Content $ReportFileName "<tr bgcolor=$BGcolourTbl>"
Add-Content $ReportFileName "<td colspan='10' height='25' align='center'>"
Add-Content $ReportFileName "<font face='Tahoma' color='#003399' size='4'><strong>$ReportTitle<br/></strong></font>"
Add-Content $ReportFileName "<font face='Tahoma' color='#003399' size='2'>$DateStamp</font><br><br>"  
Add-Content $ReportFileName "<b>Thresholds: </b>RAM will be in <FONT color=$BGcolourCrit>RED</FONT> if % free is less than $RAMFree. UPTIME will be in <FONT color=$BGcolourCrit>RED</FONT> if greater than $UptimeDayMax days.</FONT>"
Add-Content $ReportFileName "</td>"
Add-Content $ReportFileName "</tr>"
Add-Content $ReportFileName "</table>"


<#==================================================
Add Disk Space colour key
==================================================#>
Add-content $ReportFileName "<table width='60%' align=`"center`">"  
Add-Content $ReportFileName "<tr>"  
Add-Content $ReportFileName "<td width='20%' bgcolor=$BGcolourGood align='center'><B>Disk Space > $Warning% Free</B></td>"  
Add-Content $ReportFileName "<td width='20%' bgcolor=$BGcolourWarn align='center'><B>Disk Space $Critical-$Warning% Free</B></td>"  
Add-Content $ReportFileName "<td width='20%' bgcolor=$BGcolourCrit align='center'><B>Disk Space < $Critical% Free</B></td>"
Add-Content $ReportFileName "</tr>"
Add-Content $ReportFileName "</table>"

<#==================================================
Add Patch colour key
==================================================#>
Add-content $ReportFileName "<table width='60%' align=`"center`">"  
Add-Content $ReportFileName "<tr>"  
Add-Content $ReportFileName "<td width='30%' bgcolor=$BGColourGood align='center'><strong>Patched < $PatchDaysWarning Days</strong></td>"  
Add-Content $ReportFileName "<td width='30%' bgcolor=$BGColourWarn align='center'><strong>Patched $PatchDaysWarning - $PatchDaysCritical Days</strong></td>"  
Add-Content $ReportFileName "<td width='30%' bgcolor=$BGColourCrit align='center'><strong>Patched > $PatchDaysCritical Days</strong></td>"
Add-Content $ReportFileName "</tr>"
Add-Content $ReportFileName "</table>"

<#==================================================
Function to write the HTML header
==================================================#>
Function writeTableHeader
{
	param($fileName)
	Add-Content $fileName "<tr bgcolor=$BGcolourTbl>"
	Add-Content $fileName "<td width='10%' align='center'>Drive</td>"
	Add-Content $fileName "<td width='10%' align='center'>Drive Label</td>"
	Add-Content $fileName "<td width='15%' align='center'>Total Capacity (GB)</td>"
	Add-Content $fileName "<td width='15%' align='center'>Used Capacity (GB)</td>"
	Add-Content $fileName "<td width='15%' align='center'>Free Space (GB)</td>"
	Add-Content $fileName "<td width='10%' align='center'>Free Space %</td>"
	Add-Content $fileName "</tr>"
}

<#==================================================
Function to write the HTML footer
==================================================#>
Function writeHtmlFooter
{
	param($FileName)
	Add-Content $FileName "</table>"
	Add-content $FileName "<table width='75%' align=`"center`">"  
	Add-Content $FileName "<tr bgcolor=$BGColorTbl>"  
	Add-Content $FileName "<td width='75%' align='center'><strong>Total Servers: $ServerCount</strong></td>"
	Add-Content $FileName "</tr>"
	Add-Content $FileName "</table>"
	Add-Content $FileName "</body>"
	Add-Content $FileName "</html>"
}

<#==================================================
Function to write Disk info to the file
==================================================#>
Function writeDiskInfo
{
	param(
			$fileName
			,$devId
			,$volName
			,$frSpace
			,$totSpace
		)
	$totSpace 	= [math]::Round(($totSpace/1073741824),2)
	$frSpace 	= [Math]::Round(($frSpace/1073741824),2)
	$usedSpace 	= $totSpace - $frspace
	$usedSpace 	= [Math]::Round($usedSpace,2)
	$freePercent 	= ($frspace/$totSpace)*100
	$freePercent 	= [Math]::Round($freePercent,0)
	Add-Content $fileName "<tr>"
	Add-Content $fileName "<td align='center'>$devid</td>"
	Add-Content $fileName "<td align='center'>$volName</td>"
	Add-Content $fileName "<td align='center'>$totSpace</td>"
	Add-Content $fileName "<td align='center'>$usedSpace</td>"
	Add-Content $fileName "<td align='center'>$frSpace</td>"

	if ($freePercent -gt $Warning)
	{
	# Green for Good
		Add-Content $fileName "<td bgcolor=$BGcolourGood align='center'>$freePercent</td>"
		Add-Content $fileName "</tr>"
	}
	elseif ($freePercent -le $Critical)
	{
	# Red for Critical
		Add-Content $fileName "<td bgcolor=$BGcolourCrit align=center>$freePercent</td>"
		Add-Content $fileName "</tr>"
	}
	else
	{
	# Yellow for Warning
		Add-Content $fileName "<td bgcolor=$BGcolourWarn align=center>$freePercent</td>"
		Add-Content $fileName "</tr>"
	}
    
}

<#==================================================
MAIN - Query servers
==================================================#>
Write-Host "Collecting data for servers in list..." -foreground "Yellow"
$ServerCount = 0
foreach ($server in Get-Content $serverlist)
{
    try
    {
        Write-host "Checking $Server..."
        $ServerCount ++
        
        # DNS Check
		$ServerName = [System.Net.Dns]::gethostentry($server).hostname
        $DNS_Check = "DNS Record Valid"
    }
    catch
    {
        $DNS_Check = "DNS Not found"
    }

	if ($ServerName -eq $null)
    {
		$ServerName = $Server
	}

	Add-Content $ReportFileName "</table>"
	Add-Content $ReportFileName "<br>"

    # CPU Info
    $CPUs = (Get-WMIObject Win32_ComputerSystem -Computername $ServerName).numberofprocessors
    $TotalCores = 0 
    Get-WMIObject -computername $ServerName -class win32_processor | ForEach {$TotalCores = $TotalCores + $_.numberofcores}

    # RAM Info
    $ComputerSystem = Get-WmiObject -ComputerName $Servername -Class Win32_operatingsystem -Property CSName, TotalVisibleMemorySize, FreePhysicalMemory
    $MachineName = $ComputerSystem.CSName
    $FreePhysicalMemory = ($ComputerSystem.FreePhysicalMemory) / (1mb)
    $TotalVisibleMemorySize = ($ComputerSystem.TotalVisibleMemorySize) / (1mb)
    $TotalVisibleMemorySizeR = "{0:N2}" -f $TotalVisibleMemorySize
    $TotalFreeMemPerc = ($FreePhysicalMemory/$TotalVisibleMemorySize)*100
    $TotalFreeMemPercR = "{0:N2}" -f $TotalFreeMemPerc
    
    If ($TotalCores -eq 1)
	{
        $CPUSpecs = "CPU: $CPUs with 1 Core"
    }
    else
	{
        $CPUSpecs = "CPU: $CPUs with $TotalCores Cores"
    }
    
    # Uptime
    $BootTime = (Get-WmiObject win32_operatingSystem -computer $ServerName -ErrorAction stop).lastbootuptime
    $BootTime = [System.Management.ManagementDateTimeconverter]::ToDateTime($BootTime)
    $Now = Get-Date
    $span = New-TimeSpan $BootTime $Now 
	    $Days	 = $span.days
	    $Hours   = $span.hours
	    $Minutes = $span.minutes 
	    $Seconds = $span.seconds

    # Remove plurals if the value = 1 (so 1 day not 1 days)
	If ($Days -eq 1)
	{
        $Day = "1 day "
    }
	else
	{
        $Day = "$Days days "
    }

	If ($Hours -eq 1)
	{
        $Hr = "1 hr "
    }
	else
	{
        $Hr = "$Hours hrs "
    }

	If ($Minutes -eq 1)
	{
        $Min = "1 min "
    }
	else
	{
        $Min = "$Minutes mins "
    }

	If ($Seconds -eq 1)
	{
        $Sec = "1 sec"
    }
	else
	{
        $Sec = "$Seconds secs"
    }

    $Uptime = $Day + $Hr + $Min + $Sec
    $ServerUptime = $Uptime

    #Set FONT colour for health stats visual alerts % of free RAM
    If ($TotalFreeMemPerc -le $RAMFree)
	{
		$FontcolourRAM=$BGcolourCrit
	}
	else
	{
		$FontcolourRAM=$BGcolourGood
	}

    #UPTime days
    If ($Days -gt $UptimeDayMax)
	{
		$FontcolourUp=$BGcolourCrit
	}
	else
	{
		$FontcolourUp=$BGcolourGood
	}

    <#==================================================
    Check Patch Update History - Try registry first, if error Get-Hotfix
    ==================================================#>
    Try
    {
        $key = "SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Install"
        $keytype = [Microsoft.Win32.RegistryHive]::LocalMachine 
        $RemoteBase = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($keytype,$Server)
        $regKey = $RemoteBase.OpenSubKey($key)
        $KeyValue = ""
        $KeyValue = $regkey.GetValue("LastSuccessTime")
        $InstalledOn = ""
        $InstalledOn = Get-Date $KeyValue -Format 'dd/MM/yyyy hh:mm:ss'
    }

    Catch 
    {
        $ServerLastUpdate = (Get-HotFix -ComputerName $Server | Sort-Object -Descending -Property InstalledOn -ErrorAction SilentlyContinue | Select-Object -First 1)
		$InstalledOn = $ServerLastUpdate.InstalledOn
    }

    If ($InstalledOn -eq "")
    {
	    $InstalledOn = "Error collecting data"
    }

    If ($InstalledOn -eq "Error collecting data") 
    { 
        $DaySpanDays = "Error"
    }
    Else
    {
        $System = (Get-Date -Format "dd/MM/yyyy hh:mm:ss")
        $DaySpan = New-TimeSpan -Start $InstalledOn -End $System
        $DaySpanDays = $DaySpan.Days
    }

    # Colour FONT depending on $PatchDaysWarning and $PatchDaysCritical days set in script
	If ($InstalledOn -eq "Error collecting data" -or $DaySpan.Days -gt $PatchDaysCritical)
	{
    	$FontcolourPatch = $BGColourCrit
	}
	ElseIf ($DaySpan.Days -le $PatchDaysWarning)
	{
	    $FontcolourPatch = $BGcolourGood
	}
	Else
	{
	    $FontcolourPatch = $BGcolourWarn
	}

    <#==================================================
    Server Header
    ==================================================#>
    Add-Content $ReportFileName "<table width='75%' align=`"Center`">"
    Add-Content $ReportFileName "<tr bgcolor=$BGcolourTbl>"
    Add-Content $ReportFileName "<td width='75%' align='center' colSpan=6><font face='Tahoma' colour='#003399' size='2'><strong> $Server </strong></font><br>"
    Add-Content $ReportFileName "$DNS_Check<br>"
    Add-Content $ReportFileName "$CPUSpecs<br>"
    Add-Content $ReportFileName "<font color='Black'><strong>RAM: <font color=$FontcolourRAM>$TotalVisibleMemorySizeR GB with <font color=$FontcolourRAM>$TotalFreeMemPercR% Free</strong></font><br>"
    Add-Content $ReportFileName "<font color='Black'><strong>UPTIME: <font color=$FontcolourUp><strong>$ServerUptime</strong></font><br>"
    Add-Content $ReportFileName "<font color='Black'><strong>Days Since Last Patch: <font color=$FontcolourPatch>$DaySpanDays Days</strong></font></td>"

    Add-Content $ReportFileName "</tr>"
    writeTableHeader $ReportFileName

    # Begin Server Disk tables
	$dp = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" -Computer $server
	foreach ($item in $dp)
	{
		Write-Host  $ServerName $item.DeviceID  $item.VolumeName $item.FreeSpace $item.Size
		writeDiskInfo $ReportFileName $item.DeviceID $item.VolumeName $item.FreeSpace $item.Size
	}

	$ServerName = $NULL
}

Write-Host "Finishing report..." -foreground "Yellow"
writeHtmlFooter $ReportFileName
Write-Host

<#===================================================================================================
# Send Email
$BodyReport = Get-Content "$ReportFileName" -Raw
$StopEmailLoop=$false
[int]$RetryCount=0

Do
{
    Try
    {
	    Send-MailMessage -To $EmailTo `
		    -Subject 	$EmailSubject `
		    -From 		$EmailFrom `
		    -SmtpServer 	$SMTPServer `
			-BodyAsHtml	-Body $BodyReport `
			-ErrorAction Stop;
			Write-Host "Sending email..."
		    $StopEmailLoop = $true
	}
	Catch
    {
	    If ($RetryCount -gt 5)
        {
		    Write-Host "Cannot send email. exiting script..."
			$StopEmailLoop = $true
		}
		Else
        {
		    Write-Host "Cannot send email. Trying again in 10 seconds..."
			Start-Sleep -Seconds 10
			$RetryCount ++
		}
	}
}
While ($StopEmailLoop -eq $false)
===================================================================================================#>