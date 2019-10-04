Import-Module -Name ActiveDirectory
$UsernameVariable = read-host "Enter the username"
Unlock-ADAccount -Identity $UsernameVariable -Credential <Domain>\<Username>  