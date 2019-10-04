# Get-PageFileLocation.ps1
clear-host

$serverlist=get-content c:\scripts\servers.txt   -ErrorAction SilentlyContinue
$Export=@()

function Get-PageFileLocation()
{
# Regular Expression to extract the page file location from the registry key
	$Regex="^\\.{3}(.*)"
	$Object=New-Object PSObject 
	$Object1=New-Object PSObject 
	foreach ($server in $serverlist)
	{
        write-host "Checking Server: " $Server
		try
		{
			# Open the registry on multiple remote computers
			$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$server )
			$RegKeyPath= "SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
			$pageFileKey=$reg.OpenSubKey($RegKeyPath)
			$pageFileLocation=$pageFileKey.GetValue("ExistingPageFiles")
			if("$pageFileLocation" -match $Regex)
			{
				$pageFileLocation=$Matches[1]
				$Object | add-member Noteproperty ServerName $server -Force
				$Object | add-member Noteproperty PageFileLocation $pageFileLocation -Force
				$Export+=$Object
			}
		}	
		Catch [Exception] # To capture the non reachable servers
		{
			[string]$ExcepMsg=$_.Exception.Message
			#$Object1 | add-member Noteproperty ServerName $server -Force
			#$Object1 | add-member Noteproperty PageFileLocation $ExcepMsg -Force
			#$Export+=$Object1
		}	
    }
    write-output $Export
	
}

Get-PageFileLocation