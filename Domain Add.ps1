$Cred = Get-Credential
Add-Computer -DomainName "<FQDN Domain name>" -OUPath "<OU=xx,OU=xy,DC=xx>" -credential $Cred