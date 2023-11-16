# Load Azure PowerShell module if not already loaded
#Import-Module Az
#Update-Module -Name Az

# Define the path to the CSV file
$csvFile = "C:\Users\cavuss\OneDrive - FUJITSU\Documents\Accounts\DXP\Scripts\Disks.csv"

#Sample CSV file
#   VMName,DiskName,DiskSizeGB,SkuName,DiskCaching
#   MyVM1,DataDisk11,128,Standard_LRS,ReadWrite
#   MyVM1,DataDisk12,256,Standard_LRS,ReadWrite
#   MyVM1,DataDisk13,256,Standard_LRS,ReadWrite
#   MyVM1,DataDisk14,64,Standard_LRS,ReadWrite
#   MyVM2,DataDisk21,256,Standard_LRS,ReadWrite
#   MyVM2,DataDisk22,512,Standard_LRS,ReadWrite
#   MyVM2,DataDisk23,256,Standard_LRS,ReadWrite

# Import the data from the CSV file
$diskInfo = Import-Csv -Path $csvFile

# Initialize variables
$dataDiskLun = 0
$currentVM = ""

# Iterate through each row in the CSV
foreach ($row in $diskInfo) {
    $location = "Location"  # Replace with actual location
    $resourceGroupName = "Resource Group Name"  # Replace with your actual resource group name
    $vmName = $row.VMName
    $dataDiskName = $row.DiskName
    $dataDiskSizeGB = [int]$row.DiskSizeGB
    $skuName = $row.SkuName
    $dataDiskCaching = $row.DiskCaching

    # Check if the current VM is different from the previous one
    if ($vmName -ne $currentVM) {
        # Reset the LUN for the new VM
        $dataDiskLun = 0
        $currentVM = $vmName
    }

    # Create a data disk configuration
    $dataDiskConfig = New-AzDiskConfig -SkuName $skuName -Location $location -CreateOption Empty -DiskSizeGB $dataDiskSizeGB

    # Create the data disk
    $dataDisk = New-AzDisk -ResourceGroupName $resourceGroupName -DiskName $dataDiskName -Disk $dataDiskConfig

    # Get the VM
    $vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName

    # Attach the data disk to the VM
    Add-AzVMDataDisk -VM $vm -Name $dataDiskName -CreateOption Attach -ManagedDiskId $dataDisk.Id -Caching $dataDiskCaching -Lun $dataDiskLun

    # Increment the LUN for the next data disk
    $dataDiskLun++

    # Update the VM to apply the changes
    Update-AzVM -ResourceGroupName $resourceGroupName -VM $vm
}
