$path = "C:\temp\computers.csv"
$csv = (Import-csv -path $path -Header Name) | sort-object -Property Name -Unique

<#
Get-ADComputer -Filter * | select name | % {
    $csv += $_
    }
#>

$hotfixes = "KB3205409", "KB3210720", "KB3210721", "KB3212646", "KB3213986", "KB4012212",
            "KB4012213", "KB4012214", "KB4012215", "KB4012216", "KB4012217", "KB4012218",
            "KB4012220", "KB4012598", "KB4012606", "KB4013198", "KB4013389", "KB4013429",
            "KB4015217", "KB4015438", "KB4015546", "KB4015547", "KB4015548", "KB4015549",
            "KB4015550", "KB4015551", "KB4015552", "KB4015553", "KB4015554", "KB4016635",
            "KB4019213", "KB4019214", "KB4019215", "KB4019216", "KB4019263", "KB4019264",
            "KB4019472", "KB4015221", "KB4019474", "KB4015219", "KB4019473", "KB4019218",
            "KB4019265"

foreach ($computer in ($csv | sort-object -Property Name -Unique)) {
    try {
        $bob = [System.Net.Dns]::GetHostAddresses($computer.Name)
        switch -Wildcard ($computer.Name) { 
            "*.DOMAIN.COM" {
                $secpasswd = ConvertTo-SecureString “Password” -AsPlainText -Force
                $mycreds = New-Object System.Management.Automation.PSCredential (“ES\bmsbuildteamsa”, $secpasswd)
                break
                } 
            "*Domain.com" {
                $secpasswd = ConvertTo-SecureString “Password” -AsPlainText -Force
                $mycreds = New-Object System.Management.Automation.PSCredential (“hybidom\administrator”, $secpasswd)
                break
                }
            }
    
        try {
            $hotfix = Get-HotFix -ComputerName $($computer.Name) -Credential $mycreds | Where-Object {$hotfixes -contains $_.HotfixID} | Select-Object -property "HotFixID"
            if ($hotfix) {
                $IDs = ""
                $hotfix | %{$IDs += ($(if($IDs){", "}) + $_.HotFixID)}

                Write-Host "$($computer.Name) : Found HotFix(es): $IDs" -Foreground Green
                $HotfixInstalled = '1'
                $HotfixName = "$IDs"
                }
            else {
                Write-Host "$($computer.Name) : Did not Find HotFix. Please check and update this device." -Foreground Red
                $HotfixInstalled = '0'
                $HotfixName = 'N/A'
                }
            }
        catch {
            Write-Host "$($computer.Name) : $($_.Exception.Message) (User: $($mycreds.UserName))" -Foreground Yellow
            $HotfixInstalled = '0'
            $HotfixName = 'N/A'
            }
        }
    catch {
        Write-Host "$($computer.Name) : Unable to resolve name to IP address" -Foreground Yellow
        $HotfixInstalled = '0'
        $HotfixName = 'N/A'
        }
    } 
