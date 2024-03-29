############################################################################
#                                                                          #
#                                                                          #
# This script will allow you to start the wuauserv service and force       #
# a WSUS checkin.                                                          #           
#                                                                          #
############################################################################


# Define a service variable
$service = get-service -Name wuauserv

# Check to see if the service variable is stopped
if ($service.Status -eq "Stopped"){
    
    # If the service is stopped we're going to start it and force WSUS checkin
    # and Exit
    Write-host -foregroundcolor Cyan "1. WUAUSERV is stopped... starting"
    Start-Service wuauserv 
        [System.Threading.Thread]::Sleep(1500)
    Write-host -foregroundcolor Cyan "2. WUAUSERV started"    
        [System.Threading.Thread]::Sleep(1500)
    Write-host -foregroundcolor Cyan "3. Forcing WSUS Checkin"
    Invoke-Command {wuauclt.exe /detectnow}
        [System.Threading.Thread]::Sleep(1500)
    Write-host -foregroundcolor Cyan "4. Checkin Complete"
    Exit  
    
    } else {
    
    # If the service is started we'll just for the WSUS checkin and Exit
    Write-host -foregroundcolor Cyan "1. Forcing WSUS Checkin"
    Invoke-Command {wuauclt.exe /detectnow}
        [System.Threading.Thread]::Sleep(1500)
    Write-host -foregroundcolor Cyan "2. Checkin Complete"
    Exit
    
    }