
Function ConnectVIServer {
    param($Username,$Password,$Server)
    $Credentials = New-Object System.Management.Automation.PsCredential -ArgumentList $Username,($Password | ConvertTo-SecureString -AsPlainText -Force)
    Connect-VIServer -Server $Server -Credential $Credentials
}

Import-Module "C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1"

ConnectVIServer -Username 'Administrator@vsphere.local' -Password '<Password>' -Server '<ServerName>'

$VMs = Get-VM | ? {$_.Guest.OSFullName -like "*Windows*"} | Sort Name

foreach($VM in $VMs){
    Start-Job -Name $VM.Name -ArgumentList $VM.Name -ScriptBlock {
        Import-Module "C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1"
        Connect-VIServer PEG-VC01.insurance.financial.local
        $Server = Get-VM $args[0]
        Invoke-VMScript -VM $Server -ScriptText "Stop-Service Snare -Force"
        Invoke-VMScript -VM $Server -ScriptText "Set-Service Snare -StartupType Disabled"
    }
    Start-Sleep 1
}

Get-Job

foreach($VM in $VMs){
    Start-Job -Name $VM.Name -ArgumentList $VM.Name -ScriptBlock {
        Import-Module "C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1"
        Connect-VIServer PEG-VC01.insurance.financial.local
        $Server = Get-VM $args[0]
        Invoke-VMScript -VM $VM -ScriptText "Set-Service Snare -StartupType Automatic"
        Invoke-VMScript -VM $VM -ScriptText "Start-Service Snare"
    }
}