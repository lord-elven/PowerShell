$regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

$proxyServer = ""

$proxyServerToDefine = "<PROXY Address>:<PORT>"



#Write-Host "Retrieve the proxy server ..."

$proxyServer = Get-ItemProperty -path $regKey ProxyServer -ErrorAction SilentlyContinue


Write-Host $proxyServer


if([string]::IsNullOrEmpty($proxyServer))

{

#    Write-Host "Proxy is actually disabled"

    Set-ItemProperty -path $regKey ProxyEnable -value 1

    Set-ItemProperty -path $regKey ProxyServer -value $proxyServerToDefine

    Write-Host "Proxy ENABLED"

}

else

{

#   Write-Host "Proxy is actually enabled"

    Set-ItemProperty -path $regKey ProxyEnable -value 0

    Remove-ItemProperty -path $regKey -name ProxyServer

    Write-Host "Proxy DISABLED"

}
start-sleep 1
