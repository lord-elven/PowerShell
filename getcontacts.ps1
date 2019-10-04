$assemblyPath = “C:\Program Files (x86)\Microsoft Office\Office15\LyncSDK\Assemblies\Desktop\Microsoft.Lync.Model.DLL”

Import-module $assemblyPath

 

$DisplayName = 10

$PrimaryEmailAddress = 12

$Title = 14

$Company = 15

$Phones = 27

$FirstName = 37

$LastName = 38

 

$objExcel = New-Object -ComObject Excel.Application

 

$wb = $objExcel.Workbooks.Add()

$item = $wb.Worksheets.Item(1)

 

$item.Cells.Item(1,1) = "Contact Group"

$item.Cells.Item(1,2) = "Last Name"

$item.Cells.Item(1,3) = "First Name"

$item.Cells.Item(1,4) = "Title"

$item.Cells.Item(1,5) = "Company"

$item.Cells.Item(1,6) = "Primary Email Address"

$item.Cells.Item(1,7) = "Work Phone"

$item.Cells.Item(1,8) = "Mobile Phone"

$item.Cells.Item(1,9) = "Home Phone"

 

 

$cl = [Microsoft.Lync.Model.LyncClient]::GetClient()

 

$gs = $cl.ContactManager.Groups

 

$i = 2

 

foreach ($g in $gs)

{

    $gn = $g.Name

   

    foreach ($contact in $g)

    {

        $ln = $contact.GetContactInformation($LastName)

        $fn = $contact.GetContactInformation($FirstName)

        $t =  $contact.GetContactInformation($Title)

        $c =  $contact.GetContactInformation($Company)

        $email = $contact.GetContactInformation($PrimaryEmailAddress)

        $eps = $contact.GetContactInformation($Phones)

       

        foreach ($ep in $eps)

        {

            switch ($ep.type)

            {

                "WorkPhone" {$work = $ep.DisplayName}

                "MobilePhone" {$mobile = $ep.DisplayName}

                "HomePhone" {$homep = $ep.DisplayName}

             }

        }

           

        $item.Cells.Item($i,1) = $gn

        $item.Cells.Item($i,2) = $ln

        $item.Cells.Item($i,3) = $fn

        $item.Cells.Item($i,4) = $t

        $item.Cells.Item($i,5) = $c

        $item.Cells.Item($i,6) = $email

        $item.Cells.Item($i,7) = $work

        $item.Cells.Item($i,8) = $mobile

        $item.Cells.Item($i,9) = $homep

          

        $ln     = ""

        $fn     = ""

        $t      = ""

        $c      = ""

        $email  = ""

        $work   = ""

        $mobile = ""

        $homep  = ""

         

        $i++

          

    }

}

 

$objExcel.Visible = $True

 

# Remove the comment marks from the following lines to save

# the worksheet, close Excel, and clean up.

 

# $wb.SaveAs("C:\Scripts\LyncContacts.xlsx")

# $objExcel.Quit()

 

# [System.Runtime.Interopservices.Marshal]::ReleaseComObject($wb) | Out-Null

# [System.Runtime.Interopservices.Marshal]::ReleaseComObject($item) | Out-Null

# [System.Runtime.Interopservices.Marshal]::ReleaseComObject($objExcel) | Out-Null

# [System.GC]::Collect()

# [System.GC]::WaitForPendingFinalizers()

 

Remove-Variable objExcel

Remove-Variable wb

Remove-Variable item