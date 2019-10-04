Function ConnectVIServer {
    param($Username,$Password,$Server)
    $Credentials = New-Object System.Management.Automation.PsCredential -ArgumentList $Username,($Password | ConvertTo-SecureString -AsPlainText -Force)
    Connect-VIServer -Server $Server -Credential $Credentials
}

Import-Module "C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1"

ConnectVIServer -Username 'Administrator@vsphere.local' -Password '<Password>' -Server '<SERVER>'

Get-VM |
Select Name,
@{N="Datastore";E={[string]::Join(',',(Get-Datastore -Id $_.DatastoreIdList | Select -ExpandProperty Name))}},
@{N="UsedSpaceGB";E={[math]::Round($_.UsedSpaceGB,1)}},
@{N="ProvisionedSpaceGB";E={[math]::Round($_.ProvisionedSpaceGB,1)}},
@{N="Folder";E={$_.Folder.Name}} |
Export-Csv C:\scripts\VM_DS-report.csv -NoTypeInformation -UseCulture