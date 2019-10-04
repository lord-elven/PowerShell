param ([string] $share=$null)

function Test-UNCPath ($incUNC)
    {
    return [bool]([System.Uri]$incUNC).IsUnc  
    }

function Test-UNCPathIsLocal ($incUNC)
    {
    $localMachine = ([System.Net.Dns]::GetHostName()).substring(0,15)
    "USING: $localMachine"
    $uri = new-object System.Uri($incUNC)

    if(($uri.host).substring(0,15) -eq $localMachine)
        { return $true }
    else
        { return $false }
    }

function Convert-UNC2Local ($incUNC)
    {
    $uri = new-object System.Uri($incUNC)

    $localpath=gwmi win32_share | ? { $_.Name -eq ($uri.Segments[1]).Replace("/","") } | select -expand path
    if(!$localpath)
        {
        throw "ERROR"
        exit(2)
        }
    for ($i=2; $i -le ($uri.Segments.Count)-1; $i++)
        {
        $localpath=$localpath + "\" + ($uri.Segments[$i]) -replace "/",""
        }
    return $localpath
    }
#7za x Deployment.zip

if(!(Test-Path $share))
    {
    throw "ERROR: $share DOESN'T exist"
    }

if(Test-UNCPath $share)
    {
    if(Test-UNCPathIsLocal $share)
        {
        $localPath=Convert-UNC2Local $share

        sl "$localPath"
        & 7za x Deployment.zip
        }
    else
        { throw "ERROR: NOT LOCAL TO THIS BOX ($share)" }
    }
else
    { throw "ERROR: NOT A UNC PATH ($share)" }