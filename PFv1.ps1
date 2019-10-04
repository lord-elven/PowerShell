Function ConnectVIServer {
    param($Username,$Password,$Server)
    $Credentials = New-Object System.Management.Automation.PsCredential -ArgumentList $Username,($Password | ConvertTo-SecureString -AsPlainText -Force)
    Connect-VIServer -Server $Server -Credential $Credentials
}

Import-Module "C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1"

ConnectVIServer -Username 'Administrator@vsphere.local' -Password '<Password>' -Server '<Server>'

$VMs = Get-VM | ? {$_.Guest.OSFullName -like "*Windows*"} | Sort Name

foreach($VM in $VMs){
    Start-Job -Name $VM.Name -ArgumentList $VM.Name -ScriptBlock {
        Import-Module "C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1"
        Connect-VIServer PEG-VC01.insurance.financial.local
        $Server = Get-VM $args[0]
        Invoke-VMScript -VM $Server -ScriptText "Get-WmiObject Win32_PageFileusage | Select-Object Name"
    }
    #Start-Sleep 1
}

Get-Job