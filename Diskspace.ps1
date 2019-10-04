
$Excel = New-Object -Com Excel.Application
$Excel.visible = $True
$Excel = $Excel.Workbooks.Add()
$Sheet = $Excel.WorkSheets.Item(1)
$ws1 = $Excel.worksheets | where {$_.name -eq "sheet1"}
$ws2 = $Excel.worksheets | where {$_.name -eq "sheet2"}
$Sheet.Cells.Item(1,1) = “Server Name”
$Sheet.Cells.Item(1,2) = “Drive Letter”
$Sheet.Cells.Item(1,3) = “FileSystem”
$Sheet.Cells.Item(1,4) = “Size(GB)”
$Sheet.Cells.Item(1,5) = “FreeSpace(GB)”
$Sheet.Cells.Item(1,6) = “FreeSpace(%)”
$ws2.Cells.Item(1,1) = "Server Name"
$ws2.Cells.Item(1,2) = "Error"

$WorkBook = $Sheet.UsedRange
$WorkBook.Font.Bold = $True
$intRow = 2

$servers = gc c:\scripts\Servers.txt

foreach ($server in $servers){
    $ping = Test-Connection $server -Quiet
    
    if ($ping = "True") {
        $colItems = Get-wmiObject Win32_LogicalDisk -computername $server | where-object {$_.DeviceID -eq "C:"}
        $Sheet.Cells.Item($intRow,1) = $colItems.SystemName
        $Sheet.Cells.Item($intRow,2) = $colItems.DeviceID
        $Sheet.Cells.Item($intRow,3) = $colItems.FileSystem
        $Sheet.Cells.Item($intRow,4) = [MATH]::Round(($colItems.Size / 1GB),2)
        $Sheet.Cells.Item($intRow,5) = [MATH]::Round(($colItems.FreeSpace / 1GB),2)
        $Sheet.Cells.Item($intRow,6) = "{0:P2}" -f ($colItems.FreeSpace / $colItems.Size)
        $data = [MATH]::Round(($colItems.FreeSpace * 100 / $colItems.Size ),2)

        If ($data -lt "10"){$Sheet.Cells.Item($intRow,6).Interior.ColorIndex = 3} # red
        If ($data -lt "20"){$Sheet.Cells.Item($intRow,6).Interior.ColorIndex = 45} # orange
        Else {$Sheet.Cells.Item($intRow,6).Interior.ColorIndex = 0}
        $intRow = $intRow + 1
    }
    Else {$ws2.Active}
}
$WorkBook.EntireColumn.AutoFit()
