Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '400,400'
$Form.text                       = "Form"
$Form.TopMost                    = $false

$btnEventVwr                     = New-Object system.Windows.Forms.Button
$btnEventVwr.text                = "Event Viewer"
$btnEventVwr.width               = 86
$btnEventVwr.height              = 30
$btnEventVwr.location            = New-Object System.Drawing.Point(29,27)
$btnEventVwr.Font                = 'Microsoft Sans Serif,10'

$Form.controls.AddRange(@($btnEventVwr))

$btnEventVwr.Add_Click({ EventVwrAdmin $this $_ })