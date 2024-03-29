Function Get-DellServerHealth
{
    <#
    .SYNOPSIS
       Gather hardware health information specific to Dell servers.
    .DESCRIPTION
       Gather hardware health information specific to Dell servers.
    .PARAMETER ComputerName
       Specifies the target computer for data query.
    .PARAMETER ESMLogStatus
       Include ESM logs in the results.
    .PARAMETER FanHealthStatus
       Include individual fan status information.
    .PARAMETER SensorStatus
       Include individual sensor status information.
    .PARAMETER TempSensorStatus
       Include individual temperature sensor status information.
    .PARAMETER ThrottleLimit
       Specifies the maximum number of systems to inventory simultaneously 
    .PARAMETER Timeout
       Specifies the maximum time in second command can run in background before terminating this thread.
    .PARAMETER ShowProgress
       Show progress bar information
    .EXAMPLE
       #$cred = Get-Credential
       $server = 'SERVER-01'
       $a = Get-DellServerHealth -ComputerName $server `
                                 -Credential $cred `
                                 -ESMLogStatus `
                                 -FanHealthStatus `
                                 -SensorStatus `
                                 -TempSensorStatus `
                                 -verbose
       $a
       
        ComputerName : SERVER-01
        Status       : OK
        EsmLogStatus : OK
        FanStatus    : OK
        MemStatus    : OK
        Model        : PowerEdge R210 II
        ProcStatus   : OK
        TempStatus   : OK
        VoltStatus   : OK
        
       Description
       -----------
       Sonnects to SERVER-01 with alternate credentials, queries the dell WMI provider for hardware
       health information, then displays the overall hardware health. $a also includes detailed information
       in the _ESMLogs, _Fans, _Sensors, and _TempSensors properties.

    .NOTES
       Author: Zachary Loeber
       Site: http://www.the-little-things.net/
       Requires: Powershell 2.0

       Version History
       1.0.0 - 09/25/2013
        - Initial release
    #>
    [CmdletBinding()]
    PARAM
    (
        [Parameter(HelpMessage="Computer or computers to gather information from",
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias('DNSHostName','PSComputerName')]
        [string[]]
        $ComputerName=$env:computername,
        
        [Parameter(HelpMessage="Include individual fan status information.")]
        [switch]
        $FanHealthStatus,
        
        [Parameter(HelpMessage="Include individual temperature sensor status information.")]
        [switch]
        $TempSensorStatus,
        
        [Parameter(HelpMessage="Include individual sensor status information.")]
        [switch]
        $SensorStatus,
        
        [Parameter(HelpMessage="Include esm log information.")]
        [switch]
        $ESMLogStatus,
       
        [Parameter(HelpMessage="Maximum number of concurrent threads")]
        [ValidateRange(1,65535)]
        [int32]
        $ThrottleLimit = 32,
 
        [Parameter(HelpMessage="Timeout before a thread stops trying to gather the information")]
        [ValidateRange(1,65535)]
        [int32]
        $Timeout = 120,
 
        [Parameter(HelpMessage="Display progress of function")]
        [switch]
        $ShowProgress,
        
        [Parameter(HelpMessage="Set this if you want the function to prompt for alternate credentials")]
        [switch]
        $PromptForCredential,
        
        [Parameter(HelpMessage="Set this if you want to provide your own alternate credentials")]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    BEGIN
    {
        # Gather possible local host names and IPs to prevent credential utilization in some cases
        Write-Verbose -Message 'Dell Server Health: Creating local hostname list'
        $IPAddresses = [net.dns]::GetHostAddresses($env:COMPUTERNAME) | Select-Object -ExpandProperty IpAddressToString
        $HostNames = $IPAddresses | ForEach-Object {
            try {
                [net.dns]::GetHostByAddress($_)
            } catch {
                # We do not care about errors here...
            }
        } | Select-Object -ExpandProperty HostName -Unique
        $LocalHost = @('', '.', 'localhost', $env:COMPUTERNAME, '::1', '127.0.0.1') + $IPAddresses + $HostNames
 
        Write-Verbose -Message 'Dell Server Health: Creating initial variables'
        $runspacetimers       = [HashTable]::Synchronized(@{})
        $runspaces            = New-Object -TypeName System.Collections.ArrayList
        $bgRunspaceCounter    = 0
        
        if ($PromptForCredential)
        {
            $Credential = Get-Credential
        }
        
        Write-Verbose -Message 'Dell Server Health: Creating Initial Session State'
        $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        foreach ($ExternalVariable in ('runspacetimers', 'Credential', 'LocalHost'))
        {
            Write-Verbose -Message "Dell Server Health: Adding variable $ExternalVariable to initial session state"
            $iss.Variables.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList $ExternalVariable, (Get-Variable -Name $ExternalVariable -ValueOnly), ''))
        }
        
        Write-Verbose -Message 'Dell Server Health: Creating runspace pool'
        $rp = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $ThrottleLimit, $iss, $Host)
        $rp.ApartmentState = 'STA'
        $rp.Open()
 
        # This is the actual code called for each computer
        Write-Verbose -Message 'Dell Server Health: Defining background runspaces scriptblock'
        $ScriptBlock = {
            [CmdletBinding()]
            Param
            (
                [Parameter(Position=0)]
                [string]
                $ComputerName,
 
                [Parameter(Position=1)]
                [int]
                $bgRunspaceID,
                
                [Parameter()]
                [switch]
                $FanHealthStatus,
                
                [Parameter()]
                [switch]
                $TempSensorStatus,
                
                [Parameter()]
                [switch]
                $SensorStatus,
                
                [Parameter()]
                [switch]
                $ESMLogStatus
            )
            $runspacetimers.$bgRunspaceID = Get-Date

            try
            {
                Write-Verbose -Message ('Dell Server Health: Runspace {0}: Start' -f $ComputerName)
                $WMIHast = @{
                    ComputerName = $ComputerName
                    ErrorAction = 'Stop'
                }
                if (($LocalHost -notcontains $ComputerName) -and ($Credential -ne $null))
                {
                    $WMIHast.Credential = $Credential
                }

                # General variables
                $PSDateTime = Get-Date
                
                #region Data Collection
                Write-Verbose -Message ('Dell Server Health: Runspace {0}: information' -f $ComputerName)

                # Modify this variable to change your default set of display properties
                $defaultProperties    = @('ComputerName','Status','EsmLogStatus','FanStatus','MemStatus','Model','ProcStatus','TempStatus','VoltStatus')
                $WMI_CompProps = @('DNSHostName','Manufacturer')
                $wmi_compsystem = Get-WmiObject @WMIHast -Class Win32_ComputerSystem | select $WMI_CompProps
                if ($wmi_compsystem.Manufacturer -match "Dell")
                {
                    if (Get-WmiObject @WMIHast -Namespace 'root\CIMv2' -Class __NAMESPACE -filter "name='Dell'")
                    {
                        #region GeneralHardwareHealth
                        $HardwareStatus = Get-WmiObject @WMIHast -Namespace 'root\CIMV2\Dell' -class Dell_Chassis | 
                            Select Status,EsmLogStatus,FanStatus,MemStatus,Model,ProcStatus,TempStatus,VoltStatus
                            $ResultProperty = @{
                                'PSComputerName' = $ComputerName
                                'PSDateTime' = $PSDateTime
                                'ComputerName' = $ComputerName
                                'CustomData' = $CustomData
                                'Status' = $HardwareStatus.Status
                                'EsmLogStatus' = $HardwareStatus.EsmLogStatus
                                'FanStatus' = $HardwareStatus.FanStatus
                                'MemStatus' = $HardwareStatus.MemStatus
                                'Model' = $HardwareStatus.Model
                                'ProcStatus' = $HardwareStatus.ProcStatus
                                'TempStatus' = $HardwareStatus.TempStatus
                                'VoltStatus' = $HardwareStatus.VoltStatus
                            }
                        #endregion
                        #region FanHealth
                        if ($FanHealthStatus)
                        {
                            Write-Verbose -Message ('Dell Server Health: Runspace {0}: Del fan info' -f $ComputerName)
                            $Fans = Get-WmiObject @WMIHast -Namespace 'root\CIMV2\Dell' -class CIM_Fan | 
                                Select Name,Status
                            $_Fans = @()
                            foreach ($fan in $Fans)
                            {
                                $fanprop = @{
                                    'Name' = $fan.Name
                                    'Status' = $fan.Status
                                }
                                $_Fans += New-Object PSObject -Property $fanprop
                            }
                            $ResultProperty._Fans = @($_Fans)
                        }
                        #endregion
                        #region TempSensors
                        
                        if ($TempSensorStatus)
                        {
                            Write-Verbose -Message ('Dell Server Health: Runspace {0}: Del Temp Sensor info' -f $ComputerName)
                            $TempSensors = Get-WmiObject @WMIHast -Namespace 'root\CIMV2\Dell' -class CIM_TemperatureSensor | 
                                Select Name,Status,UpperThresholdCritical,CurrentReading
                            $_TempSensors = @()
                            foreach ($sensor in $TempSensors)
                            {
                                $PercentCrit = 0
                                if (($sensor.CurrentReading) -and ($sensor.UpperThresholdCritical))
                                {
                                    $PercentCrit = [math]::round((($sensor.CurrentReading/$sensor.UpperThresholdCritical)*100), 2)
                                }
                                $sensorprop = @{
                                    'Name' = $sensor.Name
                                    'Status' = $sensor.Status
                                    'Description' = $sensor.Description
                                    'CurrentReading' = $sensor.CurrentReading
                                    'UpperThresholdCritical' = $sensor.UpperThresholdCritical
                                    'PercentToCritical' = $PercentCrit
                                }
                                $_TempSensors += New-Object PSObject -Property $sensorprop
                            }
                            $ResultProperty._TempSensors = @($_TempSensors)
                        }
                        #endregion
                        #region Sensors
                        if ($SensorStatus)
                        {
                            Write-Verbose -Message ('Dell Server Health: Runspace {0}: Del Sensor info' -f $ComputerName)
                            $Sensors = Get-WmiObject @WMIHast -Namespace 'root\CIMV2\Dell' -class CIM_Sensor | 
                                Select Name,SensorType,OtherSensorTypeDescription,Status,CurrentReading
                            $_Sensors = @()
                            foreach ($sensor in $Sensors)
                            {
                                $sensorprop = @{
                                    'Name' = $sensor.Name
                                    'Type' = $sensor.SensorType
                                    'Description' = $sensor.OtherSensorTypeDescription
                                    'CurrentReading' = $sensor.CurrentReading
                                    'Status' = $sensor.Status
                                }
                                $_Sensors += New-Object PSObject -Property $sensorprop
                            }
                            $ResultProperty._Sensors = @($_Sensors)                                
                        }
                        #endregion
                        #region ESMLogs
                        if ($ESMLogStatus)
                        {
                            Write-Verbose -Message ('Dell Server Health: Runspace {0}: Del ESM Log info' -f $ComputerName)
                            $ESMLogs = Get-WmiObject @WMIHast -Namespace 'root\CIMV2\Dell' -class Dell_EsmLog | 
                                Select EventTime,LogRecord,RecordNumber,Status
                            $_ESMLogs = @()
                            foreach ($log in $ESMLogs)
                            {
                                $esmlogprop = @{
                                    'EventTime' = $log.EventTime
                                    'RecordNumber' = $log.RecordNumber
                                    'LogRecord' = $log.LogRecord
                                    'Status' = $log.Status
                                }
                                $_ESMLogs += New-Object PSObject -Property $esmlogprop
                            }
                            $ResultProperty._ESMLogs = @($_ESMLogs)   
                        }
                        #endregion
                    }
                    else
                    {
                        Write-Warning -Message ('Dell Server Health: {0}: WMI class not found!' -f $ComputerName)
                    }
                }
                                
                $ResultObject = New-Object -TypeName PSObject -Property $ResultProperty
                # Setup the default properties for output
                $ResultObject.PSObject.TypeNames.Insert(0,'My.DellHealth.Info')
                $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet',[string[]]$defaultProperties)
                $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
                $ResultObject | Add-Member MemberSet PSStandardMembers $PSStandardMembers

                Write-Output -InputObject $ResultObject
                #endregion Data Collection
            }
            catch
            {
                Write-Warning -Message ('Dell Server Health: {0}: {1}' -f $ComputerName, $_.Exception.Message)
            }
            Write-Verbose -Message ('Dell Server Health: Runspace {0}: End' -f $ComputerName)
        }
 
        Function Get-Result
        {
            [CmdletBinding()]
            Param 
            (
                [switch]$Wait
            )
            do
            {
                $More = $false
                foreach ($runspace in $runspaces)
                {
                    $StartTime = $runspacetimers.($runspace.ID)
                    if ($runspace.Handle.isCompleted)
                    {
                        Write-Verbose -Message ('Dell Server Health: Thread done for {0}' -f $runspace.IObject)
                        $runspace.PowerShell.EndInvoke($runspace.Handle)
                        $runspace.PowerShell.Dispose()
                        $runspace.PowerShell = $null
                        $runspace.Handle = $null
                    }
                    elseif ($runspace.Handle -ne $null)
                    {
                        $More = $true
                    }
                    if ($Timeout -and $StartTime)
                    {
                        if ((New-TimeSpan -Start $StartTime).TotalSeconds -ge $Timeout -and $runspace.PowerShell)
                        {
                            Write-Warning -Message ('Timeout {0}' -f $runspace.IObject)
                            $runspace.PowerShell.Dispose()
                            $runspace.PowerShell = $null
                            $runspace.Handle = $null
                        }
                    }
                }
                if ($More -and $PSBoundParameters['Wait'])
                {
                    Start-Sleep -Milliseconds 100
                }
                foreach ($threat in $runspaces.Clone())
                {
                    if ( -not $threat.handle)
                    {
                        Write-Verbose -Message ('Dell Server Health: Removing {0} from runspaces' -f $threat.IObject)
                        $runspaces.Remove($threat)
                    }
                }
                if ($ShowProgress)
                {
                    $ProgressSplatting = @{
                        Activity = 'Dell Server Health: Getting info'
                        Status = 'Dell Server Health: {0} of {1} total threads done' -f ($bgRunspaceCounter - $runspaces.Count), $bgRunspaceCounter
                        PercentComplete = ($bgRunspaceCounter - $runspaces.Count) / $bgRunspaceCounter * 100
                    }
                    Write-Progress @ProgressSplatting
                }
            }
            while ($More -and $PSBoundParameters['Wait'])
        }
    }
    PROCESS
    {
        foreach ($Computer in $ComputerName)
        {
        
            $psCMD = [System.Management.Automation.PowerShell]::Create().AddScript($ScriptBlock)
            $null = $psCMD.AddParameter('bgRunspaceID',$bgRunspaceCounter)
            $null = $psCMD.AddParameter('ComputerName',$Computer)
            $null = $psCMD.AddParameter('FanHealthStatus',$FanHealthStatus)
            $null = $psCMD.AddParameter('TempSensorStatus',$TempSensorStatus)
            $null = $psCMD.AddParameter('SensorStatus',$SensorStatus)
            $null = $psCMD.AddParameter('ESMLogStatus',$ESMLogStatus)
            $null = $psCMD.AddParameter('Verbose',$VerbosePreference)
            $psCMD.RunspacePool = $rp
 
            Write-Verbose -Message ('Dell Server Health: Starting {0}' -f $Computer)
            [void]$runspaces.Add(@{
                Handle = $psCMD.BeginInvoke()
                PowerShell = $psCMD
                IObject = $Computer
                ID = $bgRunspaceCounter
           })
           Get-Result
        }
    }
     END
    {
        Get-Result -Wait
        if ($ShowProgress)
        {
            Write-Progress -Activity 'Dell Server Health: Getting share session information' -Status 'Done' -Completed
        }
        Write-Verbose -Message "Dell Server Health: Closing runspace pool"
        $rp.Close()
        $rp.Dispose()
    }
}