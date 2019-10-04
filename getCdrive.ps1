<#
.Synopsis
This is the short decsr
.Description
Long descr
.Parameter ComputerName
Used to coneect to the computer
.Example
Diskinfo -ComputerName remote
This is for a remote computer
#>
function Get-diskinfo{
    [cmdletbinding()]
    param(
        [parameter(mandatory=$True)]
        [string[]]$ComputerNanme
    )
    get-wmiobject -computername $ComputerName -class win32_logicaldisk -Filter "deviceid='c:'" | select @{n='freegb';e={$_.freespace / 1gb -as [int]}}
}