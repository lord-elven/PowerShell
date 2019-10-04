<# 
.Synopsis 
   The purpose of this tool is to give you an easy front end for backing up and restoring Lync 2013 contacts.  
   You will have the ability to review the contents of your contact backups before you restore them,
   so you can be assured that you're always using the correct data.  It is also important to note that
   this tool uses the update-csuserdata method, which will merge the contact data rather than replace it, 
   this method is used because it does not require a reboot. 
   This is also the reason the tool only works with Lync 2013.  
 
.DESCRIPTION 
   PowerShell GUI script which allows for flexibility in the backup and restore of Lync contacts
 
.Notes 
     NAME:      lync2013_contact_restore_tool.ps1
     VERSION:   1.0 
     AUTHOR:    C. Anthony Caragol 
     LASTEDIT:  07/10/2014 
      
   V 1.0 - July 10 2014 - Initial release 
    
.Link 
   Website: http://www.lyncfix.com
   Twitter: http://www.twitter.com/canthonycaragol
   LinkedIn: http://www.linkedin.com/in/canthonycaragol
 
.EXAMPLE 
   .\lync2013_contact_restore_tool.ps1.ps1 

.TODO
  1) I'm considering adding multi-select to the user selection box, your thoughts?
  2) I should probably add some comments, see .APOLOGY

.APOLOGY
  Please excuse the sloppy coding for now, I don't use a development environment, IDE or ISE.  I use notepad, 
  not even Notepad++, just notepad.  I am not a developer, just an enthusiast so some code may be redundant or
  inefficient.
#>


Function ShutDownForm()
{
	$TempFolder = (Get-Item -Path ".\" -Verbose).FullName
	$TempFolder = $TempFolder + "\Contact_Restore_Tool_Temp"
	If(Test-Path $TempFolder)
	{
		Remove-Item "$TempFolder" -ErrorAction:Stop -recurse
	}
	$objForm.Close()
}


Function OpenFileDialog()
{   
	$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
	$OpenFileDialog.filter = "Lync UserData Export files (*.zip)| *.zip"
	[void] $OpenFileDialog.ShowDialog() 
	return $OpenFileDialog.filename
} 

Function SaveFileDialog()
{ 
	$SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
	$SaveFileDialog.filter = "Lync UserData Export files (*.zip)| *.zip"
	[void] $SaveFileDialog.ShowDialog()
	return $SaveFileDialog.filename
} 



function LoadContactsFromBackup()
{
	$BackupContactGridView.Rows.Clear()
	$TempFolder = (Get-Item -Path ".\" -Verbose).FullName
	$TempFolder = $TempFolder + "\Contact_Restore_Tool_Temp"
	$BackupContentFolder = $TempFolder + "\Backup_Content"	
	[xml]$LyncXMLFile = Get-Content "$BackupContentFolder\DocItemSet.xml"
	$SelectedUser="urn:lcd:" + $objListBox.SelectedItem
	$XMLHolder = $LyncXMLFile.DocItemSet.DocItem| ?{$_.Name -like $SelectedUser}
 	$ContactGroups = @($XMLHolder.Data.HomedResource.ContactGroups.ContactGroup)

	foreach ($x in $ContactGroups) 
	{ 
		if ($x.DisplayName -eq "fg==") 
		{
			$ContactGroupArray+=(,($x.Number,"Other Contacts",""))
		}
		else
		{
			$ContactGroupArray+=(,($x.Number,[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($x.DisplayName)),[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($x.ExternalUri))))
		}
	}

	$ExistingContacts = @($XMLHolder.Data.HomedResource.Contacts.Contact)
	$UsedGroupArray = @()	
	foreach ($x in  $ExistingContacts) { 
		if ($x.Buddy -ne $null) 
		{
			$BuddyName=$x.Buddy.tostring()
			$DisplayName = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($x.DisplayName))
			$GroupArray = $x.Groups -split " "
			foreach ($y in $GroupArray) 
			{ 
				$ContactGroup=$y
				for($i=0;$i-le $ContactGroupArray.length-1;$i++) { if ($y -eq $ContactGroupArray[$i][0]) { $ContactGroup = $ContactGroupArray[$i][1] } }
				if ($UsedGroupArray -notcontains $ContactGroup) { $UsedGroupArray += $ContactGroup }		
				$BackupContactGridView.Rows.Add($ContactGroup, $BuddyName, $DisplayName)
			}
		}
	 }

	
	for($i=0;$i-le $ContactGroupArray.length-1;$i++) 
	{
		if ($UsedGroupArray -notcontains $ContactGroupArray[$i][1]) { 
			if ($ContactGroupArray[$i][2].length -gt 0) {
				$BackupContactGridView.Rows.Add($ContactGroupArray[$i][1], "(Distribution Group)", "(Distribution Group)")
			}
			else
			{
				$BackupContactGridView.Rows.Add($ContactGroupArray[$i][1], "(Empty Group?)", "(Empty Group?)")
			}
		}		
	}
}

function LoadContactsFromCurrent()
{

	$TempFolder = (Get-Item -Path ".\" -Verbose).FullName
	$TempFolder = $TempFolder + "\Contact_Restore_Tool_Temp"
	$CurrentContentFolder = $TempFolder + "\Current_Content"
	$CurrentContentFilename = $CurrentContentFolder + "\ExportedUserData.zip"

	If(Test-Path $CurrentContentFolder)
	{
 		Remove-Item "$CurrentContentFolder" -ErrorAction:Stop -Recurse
	}

	If(!(Test-Path $CurrentContentFolder))
	{
		New-Item -ItemType Directory -Path $CurrentContentFolder
	}

	$SelectedUser="sip:" + $objListBox.SelectedItem
	$TempUser = Get-CSUser | where {$_.SipAddress -like $SelectedUser}
	$RegistrarPool = $TempUser.RegistrarPool.tostring()

	Export-CsUserData -PoolFqdn $RegistrarPool -FileName $CurrentContentFilename -UserFilter $objListBox.SelectedItem
	[System.IO.Compression.ZipFile]::ExtractToDirectory("$CurrentContentFilename", "$CurrentContentFolder")
	$CurrentContactGridView.Rows.Clear()
	[xml]$LyncXMLFile = Get-Content "$CurrentContentFolder\DocItemSet.xml"
	$SelectedUser="urn:lcd:" + $objListBox.SelectedItem
	$XMLHolder = $LyncXMLFile.DocItemSet.DocItem| ?{$_.Name -like $SelectedUser}
 	$ContactGroups = @($XMLHolder.Data.HomedResource.ContactGroups.ContactGroup)
	foreach ($x in $ContactGroups) { 
		if ($x.DisplayName -eq "fg==") 
		{
			$ContactGroupArray+=(,($x.Number,"Other Contacts",""))
		}
		else
		{
			$ContactGroupArray+=(,($x.Number,[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($x.DisplayName)),[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($x.ExternalUri))))
		}
	}

	$ExistingContacts = @($XMLHolder.Data.HomedResource.Contacts.Contact)
	$UsedGroupArray = @()
	foreach ($x in  $ExistingContacts) 
	{ 
		if ($x.Buddy -ne $null) 
		{
			$BuddyName=$x.Buddy.tostring()
			$DisplayName = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($x.DisplayName))
			$GroupArray = $x.Groups -split " "
			foreach ($y in $GroupArray)
			{ 
				$ContactGroup=$y
				for($i=0;$i-le $ContactGroupArray.length-1;$i++) { if ($y -eq $ContactGroupArray[$i][0]) { $ContactGroup = $ContactGroupArray[$i][1] } }	
				if ($UsedGroupArray -notcontains $ContactGroup) { $UsedGroupArray += $ContactGroup }		
				$CurrentContactGridView.Rows.Add($ContactGroup,  $BuddyName, $DisplayName)
			}
		}	
	 }

	for($i=0;$i-le $ContactGroupArray.length-1;$i++) 
	{
		if ($UsedGroupArray -notcontains $ContactGroupArray[$i][1]) { 
			if ($ContactGroupArray[$i][2].length -gt 0) {
				$CurrentContactGridView.Rows.Add($ContactGroupArray[$i][1], "(Distribution Group)", "(Distribution Group)")
			}
			else
			{
				$CurrentContactGridView.Rows.Add($ContactGroupArray[$i][1], "(Empty Group?)", "(Empty Group?)")
			}
		}			
	}  
}

	
Function LoadUsersFromZip()
{
	$TempFolder = (Get-Item -Path ".\" -Verbose).FullName
	$TempFolder = $TempFolder + "\Contact_Restore_Tool_Temp"
	$BackupContentFolder = $TempFolder + "\Backup_Content"

	If(Test-Path $BackupContentFolder)
	{
		Remove-Item "$BackupContentFolder\*" -ErrorAction:Stop -Recurse
	}

	If(!(Test-Path $TempFolder))
	{
		New-Item -ItemType Directory -Path $TempFolder
	}

	If(!(Test-Path $BackupContentFolder))
	{
		New-Item -ItemType Directory -Path $BackupContentFolder
	}

	[System.IO.Compression.ZipFile]::ExtractToDirectory("$ZipFile", "$BackupContentFolder")
	[xml]$LyncXMLFile = Get-Content "$BackupContentFolder\DocItemSet.xml"
	$XMLHolder = $LyncXMLFile.DocItemSet.DocItem| ?{$_.Name -like "urn:lcd:*"}
	Foreach ($x in $XMLHolder) 
	{ 
		$SipName=$x.Name.substring(8, $x.Name.length - 8)
		[void] $objListBox.Items.Add($SipName)
	}
}

$CAC_FormSizeChanged = { 
	
	$BackupContactGridView.Width=($objForm.Width - $BackupContactGridView.Left) / 2 - 20
	$CurrentContactGridView.Left = $BackupContactGridView.Left + $BackupContactGridView.Width + 10
	$CurrentContactGridView.Width=($objForm.Width - $BackupContactGridView.Left) / 2 - 20
	$Step2Button.Width=$BackupContactGridView.Width
	$Step3Button.Left=$CurrentContactGridView.Left
	$Step3Button.Width=$CurrentContactGridView.Width
} 
 
   
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") 
[void] [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')

$objForm = New-Object System.Windows.Forms.Form 
$objForm.Text = "Lync 2013 Contact Backup and Restore Tool"
$objForm.Size = New-Object System.Drawing.Size(960,600) 
$objForm.StartPosition = "CenterScreen"
$ObjForm.Add_SizeChanged($CAC_FormSizeChanged)
$objForm.KeyPreview = $True

$TitleLabel = New-Object System.Windows.Forms.Label
$TitleLabel.Location = New-Object System.Drawing.Size(10,10) 
$TitleLabel.Size = New-Object System.Drawing.Size(900,60) 
$TitleLabel.Text = "The purpose of this tool is to give you an easy front end for backing up and restoring Lync 2013 contacts.  You will have the ability to review the contents of your contact backups before you restore them, so you can be assured that you're always using the correct data.  It is also important to note that this tool uses the update-csuserdata method, which will merge the contact data rather than replace it, this method is used because it does not require a reboot.  This is also the reason the tool only works with Lync 2013.  Please use the Q/A section of the TechNet gallery to suggest features you would like to see.  Use only at your own risk."
$objForm.Controls.Add($TitleLabel) 

$objListBox = New-Object System.Windows.Forms.ListBox 
$objListBox.Location = New-Object System.Drawing.Size(10,80) 
$objListBox.Size = New-Object System.Drawing.Size(200,400) 
$objListBox.Anchor = 'Top, Bottom,Left'
$objListBox.Sorted = $True
$objForm.Controls.Add($objListBox) 

$Step1Button = New-Object System.Windows.Forms.Button
$Step1Button.Location = New-Object System.Drawing.Size(10,480)
$Step1Button.Size = New-Object System.Drawing.Size(200,25)
$Step1Button.Text = "Step 1: Load Users"
$Step1Button.Add_Click({
	$Step1Button.Enabled=$False
	$Step1Button.Text = "Loading..."
	$objListBox.Items.Clear()
	$ZipFile=OpenFileDialog 
	$objLabel.Text = "Selected File:" + $ZipFile
	LoadUsersFromZip
	$Step1Button.Text = "Step 1: Load Users"
	$Step1Button.Enabled=$True
})
$Step1Button.Anchor = 'Bottom, Left'
$objForm.Controls.Add($Step1Button)


$BackupContactGridView = New-Object System.Windows.Forms.DataGridView
$BackupContactGridView.Location = New-Object System.Drawing.Size(220,80) 
$BackupContactGridView.Size = New-Object System.Drawing.Size(350,400) 
$BackupContactGridView.Anchor = 'Top, Bottom, Left'
$BackupContactGridView.ColumnCount = 3
$BackupContactGridView.Columns[0].Width = 150
$BackupContactGridView.Columns[1].Width = 200
$BackupContactGridView.Columns[2].Width = 200
$BackupContactGridView.Columns[0].Name = "Group"
$BackupContactGridView.Columns[1].Name = "Contact URI"
$BackupContactGridView.Columns[2].Name = "Contact Name"
$objForm.Controls.Add($BackupContactGridView) 

$Step2Button = New-Object System.Windows.Forms.Button
$Step2Button.Location = New-Object System.Drawing.Size(220,480)
$Step2Button.Size = New-Object System.Drawing.Size(350,25)
$Step2Button.Text = "Step 2: Review Backup Contacts"
$Step2Button.Add_Click({
	if ($objListBox.SelectedIndex -gt -1) 
	{
		$Step2Button.Enabled=$False
		$Step2Button.Text = "Loading..."
		LoadContactsFromBackup
		$Step2Button.Text = "Step 2: Review Backup Contacts"
		$Step2Button.Enabled=$True
	}
	else
	{
	[Microsoft.VisualBasic.Interaction]::MsgBox("I'm sorry, I couldn't determine which user you selected. Please highlight a user in the Step 1 box.",'OKOnly,Critical', "No User Selected!")
	}
})
$Step2Button.Anchor = 'Bottom, Left'
$objForm.Controls.Add($Step2Button)

$CurrentContactGridView = New-Object System.Windows.Forms.DataGridView
$CurrentContactGridView.Location = New-Object System.Drawing.Size(580,80) 
$CurrentContactGridView.Size = New-Object System.Drawing.Size(350,400) 
$CurrentContactGridView.Anchor = 'Top, Bottom'
$CurrentContactGridView.ColumnCount = 3
$CurrentContactGridView.Columns[0].Width = 150
$CurrentContactGridView.Columns[1].Width = 200
$CurrentContactGridView.Columns[2].Width = 200
$CurrentContactGridView.Columns[0].Name = "Group"
$CurrentContactGridView.Columns[1].Name = "Contact URI"
$CurrentContactGridView.Columns[2].Name = "Contact Name"
$objForm.Controls.Add($CurrentContactGridView) 

$Step3Button = New-Object System.Windows.Forms.Button
$Step3Button.Location = New-Object System.Drawing.Size(580,480)
$Step3Button.Size = New-Object System.Drawing.Size(350,25)
$Step3Button.Text = "Step 3: Review Current Contacts"
$Step3Button.Add_Click({
	if ($objListBox.SelectedIndex -gt -1) 
	{
		$Step3Button.Enabled=$False
		$Step3Button.Text = "Loading..."
		LoadContactsFromCurrent
		$Step3Button.Text = "Step 3: Review Current Contacts"
		$Step3Button.Enabled=$True
	}
	else
	{
	[Microsoft.VisualBasic.Interaction]::MsgBox("I'm sorry, I couldn't determine which user you selected. Please highlight a user in the Step 1 box.",'OKOnly,Critical', "No User Selected!")
	}
})
$Step3Button.Anchor = 'Bottom, Right'
$objForm.Controls.Add($Step3Button)


$UserBackupButton = New-Object System.Windows.Forms.Button
$UserBackupButton.Location = New-Object System.Drawing.Size(330,525)
$UserBackupButton.Size = New-Object System.Drawing.Size(150,25)
$UserBackupButton.Text = "Create A User Backup"
$UserBackupButton.Add_Click({
	$UserBackupButton.Enabled=$False
	$UserBackupButton.Text = "Working..."
	$usersipquery = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the SIP address of a user to back up", "SIP Address", "") 
	if ($usersipquery.length -gt 0) {
		$savelocation = SaveFileDialog
		if ($savelocation.length -gt 0) {
			$SelectedUser="sip:" + $usersipquery
			$TempUser = Get-CSUser | where {$_.SipAddress -like $SelectedUser}
			$RegistrarPool = $TempUser.RegistrarPool.tostring()
			Export-CsUserData -PoolFqdn $RegistrarPool -FileName $savelocation -UserFilter $usersipquery
		}
	}
	$UserBackupButton.Text = "Create A User Backup"
	$UserBackupButton.Enabled=$True

})
$UserBackupButton.Anchor = 'Bottom, Right'
$objForm.Controls.Add($UserBackupButton)

$PoolBackupButton = New-Object System.Windows.Forms.Button
$PoolBackupButton.Location = New-Object System.Drawing.Size(480,525)
$PoolBackupButton.Size = New-Object System.Drawing.Size(150,25)
$PoolBackupButton.Text = "Create A Pool Backup"
$PoolBackupButton.Add_Click({
	$PoolBackupButton.Enabled=$False
	$PoolBackupButton.Text = "Working..."
	$poolfqdnquery = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the FQDN of a front end pool to back up", "Front End Pool", "") 
	if ($poolfqdnquery.length -gt 0) {
		$savelocation = SaveFileDialog
		if ($savelocation.length -gt 0) {
			Export-CsUserData -PoolFqdn $poolfqdnquery -FileName $savelocation
		}
	}
	$PoolBackupButton.Text = "Create A Pool Backup"
	$PoolBackupButton.Enabled=$True

})
$PoolBackupButton.Anchor = 'Bottom, Right'

$objForm.Controls.Add($PoolBackupButton)
$MergeButton = New-Object System.Windows.Forms.Button
$MergeButton.Location = New-Object System.Drawing.Size(630,525)
$MergeButton.Size = New-Object System.Drawing.Size(150,25)
$MergeButton.Text = "Merge Selected User"
$MergeButton.Add_Click({
	$MergeButton.Enabled=$False
	$MergeButton.Text = "Merging..."

	if ($objListBox.SelectedIndex -gt -1) {
		$SelectedUser = $objListBox.SelectedItem.tostring()
		$SelectedFile = $objLabel.Text.substring(14, $objLabel.Text.length - 14)
		$ConfirmIt=[Microsoft.VisualBasic.Interaction]::MsgBox("Are you sure you want to merge the contacts of $SelectedUser from $SelectedFile ?",'YesNoCancel,Question', "Use at your own risk!")
		if ($ConfirmIt -eq "Yes") { 
		Update-CsUserData -Filename $SelectedFile -UserFilter $SelectedUser -confirm:$false
		}
	}
	else 
	{
		[Microsoft.VisualBasic.Interaction]::MsgBox("I'm sorry, I couldn't determine which user you selected. Please highlight a user in the Step 1 box.",'OKOnly,Critical', "No User Selected!")
	}
	$MergeButton.Text = "Merge Selected User"
	$MergeButton.Enabled=$True
})
$MergeButton.Anchor = 'Bottom, Right'
$objForm.Controls.Add($MergeButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Size(780,525)
$CancelButton.Size = New-Object System.Drawing.Size(150,25)
$CancelButton.Text = "Quit"
$CancelButton.Add_Click({ShutDownForm})
$CancelButton.Anchor = 'Bottom, Right'
$objForm.Controls.Add($CancelButton)

$objLabel = New-Object System.Windows.Forms.Label
$objLabel.Location = New-Object System.Drawing.Size(10,510) 
$objLabel.Size = New-Object System.Drawing.Size(400,20) 
$objLabel.Text = "Selected File:"
$objLabel.Anchor = 'Bottom, Left'
$objForm.Controls.Add($objLabel) 

#LyncFix LinkLabel
$LyncFixLinkLabel = New-Object System.Windows.Forms.LinkLabel
$LyncFixLinkLabel.Location = New-Object System.Drawing.Size(10,538) 
$LyncFixLinkLabel.Size = New-Object System.Drawing.Size(150,20)
$LyncFixLinkLabel.text = "http://www.lyncfix.com"
$LyncFixLinkLabel.add_Click({Start-Process $LyncFixLinkLabel.text})
$LyncFixLinkLabel.Anchor = 'Bottom, Left'
$objForm.Controls.Add($LyncFixLinkLabel)

$objForm.Add_Shown({$objForm.Activate()})
[void] $objForm.ShowDialog()


