$strComputers = Get-Content -Path "C:\Temp\Finding .vmdk\Physicals.txt"
$Admin = "Admin"
$Pass = "Password"

# ---------- Step 1: Get ALL vmdk files from physical hosts

[bool]$firstOutput = $true
foreach($strComputer in $strComputers)
{
    $UserName = $Admin + $strComputer.Substring($strComputer.Length - 5,5)

    $Cred = New-Object System.Management.Automation.PSCredential -ArgumentList @($UserName,(ConvertTo-SecureString -String $Pass -AsPlainText -Force))

    If ($strComputer -ne $env:COMPUTERNAME) {
        $colFiles = Get-Wmiobject -namespace "root\CIMV2" -computername $strComputer -Credential $Cred -Query "Select * from CIM_DataFile Where Extension = 'vmdk'"
    } else {
        $colFiles = Get-Wmiobject -namespace "root\CIMV2" -computername $strComputer -Query "Select * from CIM_DataFile Where Extension = 'vmdk'"
    }
    $colFiles

    foreach ($objFile in $colFiles)
    {.
        if($objFile.FileName -ne $null)
        {
            $filepath = $objFile.Drive + $objFile.Path + $objFile.FileName + "." `
            + $objFile.Extension;
            $query = "ASSOCIATORS OF {Win32_LogicalFileSecuritySetting='" `
            + $filepath `
            + "'} WHERE AssocClass=Win32_LogicalFileOwner ResultRole=Owner"

            If ($strComputer -ne $env:COMPUTERNAME) {
                $colOwners = Get-Wmiobject -namespace "root\CIMV2" `
                -computername $strComputer `
                -Credential $Cred `
                -Query $query
            } else { 
                $colOwners = Get-Wmiobject -namespace "root\CIMV2" -computername $strComputer -Query $query
            }
            $output = $strComputer + "," + $filepath
            if($firstOutput)
            {
                Write-output "Host,FilePath" | Out-File -Encoding ascii -filepath "C:\Temp\Finding .vmdk\PhysicalNamesWithIPs.csv"
                Write-output $output | Out-File -Encoding ascii -filepath "C:\Temp\Finding .vmdk\PhysicalNamesWithIPs.csv" -append
                $firstOutput = $false
            }
            else
            {
                Write-output $output | Out-File -Encoding ascii -filepath "C:\Temp\Finding .vmdk\PhysicalNamesWithIPs.csv" -append
            }
        }
    }
}

# ---------- Step 2: Remove all but 'real' .vmdk files from csv file

$vmdkList = import-csv "C:\Temp\Finding .vmdk\PhysicalNamesWithIPs.csv" 

$i = 0

$realVmdks = @()

Foreach ($vmdkFile in $vmdkList) {
    If (!($vmdkFile.FilePath.Contains("-000"))) { 
        $realVmdks = $realVmdks + $vmdkFile
    }
}

$realVmdks | Export-Csv "C:\Temp\Finding .vmdk\PhysicalNamesWithIPs.csv" -NoTypeInformation

# ---------- Step 3: Send soft shutdown command to all vms in csv

$vmdkList = import-csv "C:\Temp\Finding .vmdk\PhysicalNamesWithIPs.csv" 
Foreach ($vmdkFile in $vmdkList) {
    $strComputer = $vmdkFile.Host

    $UserName = $Admin + $strComputer.Substring($strComputer.Length - 5,5)

    $Cred = New-Object System.Management.Automation.PSCredential -ArgumentList @($UserName,(ConvertTo-SecureString -String $Pass -AsPlainText -Force))
    
    $vmName = $($vmdkFile.FilePath).Split("\")[$($vmdkFile.FilePath).Split("\").length-1].TrimEnd(".vmdk")
    
    $vmName
    
    invoke-command -cn $strComputer -credential $Cred {
        if (Test-Connection -ComputerName $args[0] -quiet) {
            vmrun -t ws stop $args[1] soft #hard
        }
    } -argumentlist @($vmName,$vmdkFile.FilePath.Replace(".vmdk",".vmx"))
}
