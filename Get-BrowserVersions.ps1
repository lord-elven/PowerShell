#Set file path to store data
$exportdata = 'c:\scripts\browser_version.txt'

#Add Date and Time
$CDate = Get-Date

#Get Servers
#$hostname = Get-Content env:computername
$servers = gc 'c:\scripts\Servers.txt'

foreach ($server in $servers){
    if((Test-Connection -ComputerName $server -Quiet) -eq $true){

        #Get Google Chrome Version
        $GCVersionInfo = (Get-Item (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe').'(Default)').VersionInfo
        
        #Get Microsoft Internet Explorer Version
        $IEVersionInfo = (Get-Item (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\iexplore.exe').'(Default)').VersionInfo
        
        #Get Mozilla Firefox Version
        $FFVersionInfo = (Get-Item (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\firefox.exe').'(Default)').VersionInfo
    
        #Get Microsoft Edge Version
        $productPath = $Env:WinDir + "\SystemApps\Microsoft.MicrosoftEdge_*\MicrosoftEdge.exe" 
        If(Test-Path $productPath) { 
            $MSEVersionInfo = (Get-Item (Get-ItemProperty -Path $productPath)).VersionInfo  
        } 
        Else { 
            $MSEVersionInfo = "Microsoft Edge Not found." 
        }
    
    }   
    Else {
        #Server not contactable
    }


write-host "Checking Server: $Server" -ForegroundColor Yellow
Write-Host "Chrome: "$GCVersionInfo.ProductVersion
Write-Host "IE: " $IEVersionInfo.ProductVersion
Write-Host "Firefox: " $FFVersionInfo.ProductVersion
write-host "Edge: "$MSEVersionInfo.ProductVersion 

$GCVersion = $GCVersionInfo.ProductVersion
$IEVersion = $IEVersionInfo.ProductVersion
$FFVersion = $FFVersionInfo.ProductVersion
$MSEVersion = $MSEVersionInfo.ProductVersion



$lineToWriteInFile = "$Server, Chrome: $GCVersion, IE: $IEVersion, FireFox: $FFVersion, Edge: $MSEVersion, $CDate"


#Writeversions in file
$lineToWriteInFile | Out-File -Encoding unicode -Append $exportdata
$lineToWriteInFile | Out-File -Encoding unicode -Append '´n'
}
# | Export-Csv C:\scripts\Broswers.csv -NoTypeInformation -Encoding UTF8