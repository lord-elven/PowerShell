﻿New-Item -Path "Registry::HKEY_CLASSES_ROOT\Microsoft.PowershellScript.1\Shell\runas\command" `
-Force -Name '' -Value '"c:\windows\system32\windowspowershell\v1.0\powershell.exe" -noexit "%1"'