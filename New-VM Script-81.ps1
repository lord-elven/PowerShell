# Required Variables.
$VMName = Read-Host "Enter the VM Name"



# These variables must be changed per Hyper-V system you run it on, unless the locations are the same.
$VMGeneration = '2'
$VHDPath = 'C:\VirtualDisks\Template\Win81-SysPrep.vhdx'
$NewVHDDirectory = 'C:\VirtualDisks\'
$VHDDestination = "C:\VirtualDisks\$VMName"
$Ext = '.vhdx'



# Create a new folder and copy the VHD file and rename it.
New-Item -Name $VMName -Path $NewVHDDirectory -ItemType Directory -ErrorAction SilentlyContinue
Copy-Item -Path $VHDPath -Destination $VHDDestination -verbose
Rename-Item $VHDDestination\Win81-SysPrep.vhdx -NewName "$VMName$Ext" -Verbose

# Create and start the New VM.

New-VM -Name $VMName -MemoryStartupBytes 5GB -Generation $VMGeneration | Add-VMHardDiskDrive -Path "$VHDDestination\$VMName$Ext"
Start-VM -Name $VMName
