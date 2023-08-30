#Detect Local Admins - DGray 30/08/23

#Predefined List of Admins to Check
$adminList = @("Administrator", "ANO Admin etc...")

#Get the list of Admins
$localAdmins = Get-LocalGroupMember "Administrators"

# Initialize an array to store the matching Admin usernames
$matchingAdmins = @()

try {
    
    # Check if each local Admin username exists in the predefined list
    foreach ($admin in $localAdmins) {
        
        $adminUsername = $admin.Name -replace ".*\\", ""

        if ($adminList -contains $adminUsername) {
            $matchingAdmins += $adminUsername
        }
    }

    # Display the matching Admin usernames
    if ($matchingAdmins.Count -gt 0) {
        Write-Host "Matching Admin Usernames:"
        $matchingAdmins | ForEach-Object {
            Write-Host $_
        }
    } else {
        Write-Host "No matching admin usernames found."
    }
}

catch {
    $errorMsg = $_.Exception.Message
    Write-Error $errorMsg
    exit
}