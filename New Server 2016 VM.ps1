# Variables to copy and rename a sysprepped VHD.
$VHDPath = '<PATH>\SVR2016.vhdx'
$VHDDestination = '<PATH>'
$Ext = '.vhdx'

# Variables for a New VM.
$VMName = Read-Host "Enter the VM Name"
$VMGeneration = '2'

# Copy the VHD file and rename it.
Copy-Item -Path $VHDPath -Destination "$VHDDestination"
Rename-Item $VHDDestination\SVR2016.vhdx -NewName "$VMName$Ext"

# Create a New VM
New-VM -Name $VMName -MemoryStartupBytes 4GB -Generation $VMGeneration | Add-VMHardDiskDrive -Path "$VHDDestination\$VMName$Ext"
Start-VM -Name $VMName
