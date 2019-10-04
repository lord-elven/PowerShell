add-pssnapin microsoft.sharepoint.powershell -EA 0
 
# Select Options
Write-Host -ForegroundColor Yellow "'Document' will create a CSV dump of users to convert. 'Convert' will use the data in the CSV to perform the migrations."
Write-Host -ForegroundColor Cyan "1. Document"
Write-Host -ForegroundColor Cyan "2. Convert"
Write-Host -ForegroundColor Cyan " "
$Choice = Read-Host "Select an option 1-2: "
 
switch($Choice)
{
    1 {$convert = $false}
    2 {$convert = $true}
    default {Write-Host "Invalid selection! Exiting... "; exit}
}
Write-Host ""
 
if($convert-eq $true)
{
    $csvPath = Read-Host "Please enter the path to the .csv file. (Ex. C:\migration)"
 
    $objCSV = Import-CSV "$csvPath\MigrateUsers.csv"
 
    foreach ($object in $objCSV)
    {
        $user = Get-SPUser -web $object.SiteCollection -Limit All | ?{$_.UserLogin -eq $object.OldLogin}
        move-spuser -identity $user -newalias $object.NewLogin -ignoresid -Confirm:$false
    }
}
else
{
    $objCSV = @()
 
    # Select Options
    Write-Host -ForegroundColor Yellow "Choose the scope of the migration - Farm, Web App, or Site Collection"
    Write-Host -ForegroundColor Cyan "1. Entire Farm"
    Write-Host -ForegroundColor Cyan "2. Web Application"
    Write-Host -ForegroundColor Cyan "3. Site Collection"
    Write-Host -ForegroundColor Cyan " "
    $scopeChoice = Read-Host "Select an option 1-3: "
 
    switch($scopeChoice)
    {
        1 {$scope = "Farm"}
        2 {$scope = "WebApp"}
        3 {$scope = "SiteColl"}
        default {Write-Host "Invalid selection! Exiting... "; exit}
    }
    Write-Host ""
 
    if($scope -eq "Farm")
    {
        $sites = get-spsite -Limit All
    }
    elseif($scope -eq "WebApp")
    {
        $url = Read-Host "Enter the Url of the Web Application: "
        $sites = get-spsite -WebApplication $url -Limit All
    }
    elseif($scope -eq "SiteColl")
    {
        $url = Read-Host "Enter the Url of the Site Collection: "
        $sites = get-spsite $url
    }
 
    $oldprovider = Read-Host "Enter the Old Provider Name (Example -> Domain\ or i:0#.f|MembershipProvider|) "
    $newprovider = Read-Host "Enter the New Provider Name (Example -> Domain\ or i:0#.f|MembershipProvider|) "
    $csvPath = Read-Host "Please enter the path to save the .csv file to. (Ex. C:\migration)"
 
    foreach($site in $sites)
    {
        $webs = $site.AllWebs
 
        foreach($web in $webs)
        {
            # Get all of the users in a site
            $users = get-spuser -web $web
 
            # Loop through each of the users in the site
            foreach($user in $users)
            {
                # Create an array that will be used to split the user name from the domain/membership provider
                $a=@()
                $displayname = $user.DisplayName
                $userlogin = $user.UserLogin
 
                if(($userlogin -like "$oldprovider*") -and ($objCSV.OldLogin -notcontains $userlogin))
                {
                    # Separate the user name from the domain/membership provider
                    if($userlogin.Contains('|'))
                    {
                        $a = $userlogin.split("|")
                        $username = $a[1]
 
                        if($username.Contains('\'))
                        {
                            $a = $username.split("\")
                            $username = $a[1]
                        }
                    }
                    elseif($userlogin.Contains('\'))
                    {
                        $a = $userlogin.split("\")
                        $username = $a[1]
                    }
 
                    # Create the new username based on the given input
                    $newalias = $newprovider + $username
 
                    $objUser = "" | select OldLogin,NewLogin,SiteCollection
	                $objUser.OldLogin = $userLogin
                    $objUser.NewLogin = $newAlias
	                $objUser.SiteCollection = $site.Url
 
	                $objCSV += $objUser
                }   
            }
        }
    }
    $sites.Dispose()
 
    $objCSV | Export-Csv "$csvPath\MigrateUsers.csv" -NoTypeInformation   
}
