#Remote rename script v1 - DGRAY Sept 2012
#Change <nameofcomputer> to the name you wish to create

$computers = Get-adcomputer | where {$_.name –like “<nameofcomputer>*”}
 
$num = 0
 
Foreach($computer in $computers)
 
{
 
For($num=1;$num –lt $computers.count;$num++)
 
{
 
Rename-computer –computername $computer –newname “s-$num” –domaincredential domain\user –force –restart
 
        }
