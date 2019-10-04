# a PowerShell script, licensed under GPL ;)
#
# importing dependancy, assuming it's already installed.
# Install RSAT for Windows workstation, AD DS role for Windows Server if missing
Import-Module "ActiveDirectory"

# an array containing the OU paths we'll enumerate
$OUpaths = @("OU=Domain Member Servers,DC=<DC>,DC=<DC>,DC=<DC>","OU=<OU>,DC=<DC>,DC=<DC>,DC=<DC>")

# loop though the array of OUs, adding the computers to a list ('Object' really)
foreach ($iOUpath in $OUpaths)
    {
        ($objComputers += Get-ADComputer -SearchBase $iOUpath -Filter *)    #You might need to refine the query witha 'Filter' depending on your AD structure
    }

# dump the list to a file
$objComputers | Select name | out-file -LiteralPath "C:\scripts\ADServers.txt"
#Export-Csv -LiteralPath "C:\scripts\ADServers.txt" -NoTypeInformation