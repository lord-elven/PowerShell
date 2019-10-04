# List files that have not been accessed for a determined amount of time.
#
# Usage: Get-NeglectedFiles -path <file path> -numberDays <days> | select name, lastaccesstime
# Example: Get-NeglectedFiles -path d:\userscratch -numberDays 90 | select name, lastaccesstime
#
# To auto remove file over a certain time period:
# Get-NeglectedFiles -path d:\userscratch -numberDays 90 | Remove-Item -Force
#

Function Get-NeglectedFiles
{
 Param([string[]]$path,
       [int]$numberDays)
 $cutOffDate = (Get-Date).AddDays(-$numberDays)
 Get-ChildItem -Path $path |
 Where-Object {$_.LastAccessTime -le $cutOffDate}
}