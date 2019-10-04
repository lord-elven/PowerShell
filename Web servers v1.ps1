
# Run with Admin priviledges
<#if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){   
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}#>

$Credentials = Get-Credential
$Export = @()

Get-ADComputer -Filter {enabled -eq $true} -SearchBase "OU=<OU>,DC=<DC>,DC=<DC>" | % {
    $Name = $_.DNSHostName
    IF(Test-NetConnection $Name){
        IF(Get-Service -ComputerName $Name -Name W3svc){
            $Export += $Name
        }
    }
}

$Export