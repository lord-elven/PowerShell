$userName = Read-Host -Prompt "Enter The users username"
net localgroup Administrators <Domain>\<Admin Group> /add
net localgroup Administrators <Domain>\$userName /add