# ----------------------------------------------------------------------------------
#
# Copyright Microsoft Corporation
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ----------------------------------------------------------------------------------

# Warning: This code was generated by a tool.
# 
# Changes to this file may cause incorrect behavior and will be lost if the
# code is regenerated.


function get_vm_config_object
{
    param ([string] $rgname, [string] $vmsize)
    
    $st = Write-Verbose "Creating VM Config Object - Start";

    $vmname = 'vm' + $rgname;
    $p = New-AzureVMConfig -VMName $vmname -VMSize $vmsize;

    $st = Write-Verbose "Creating VM Config Object - End";

    return $p;
}


function get_created_storage_account_name
{
    param ([string] $loc, [string] $rgname)

    $st = Write-Verbose "Creating and getting storage account for '${loc}' and '${rgname}' - Start";

    $stoname = 'sto' + $rgname;
    $stotype = 'Standard_GRS';

    $st = Write-Verbose "Creating and getting storage account for '${loc}' and '${rgname}' - '${stotype}' & '${stoname}'";

    $st = New-AzureStorageAccount -ResourceGroupName $rgname -Name $stoname -Location $loc -Type $stotype;
    $st = Get-AzureStorageAccount -ResourceGroupName $rgname -Name $stoname;
    
    $st = Write-Verbose "Creating and getting storage account for '${loc}' and '${rgname}' - End";

    return $stoname;
}


function create_and_setup_nic_ids
{
    param ([string] $loc, [string] $rgname, $vmconfig)

    $st = Write-Verbose "Creating and getting NICs for '${loc}' and '${rgname}' - Start";

    $subnet = New-AzureVirtualNetworkSubnetConfig -Name ('subnet' + $rgname) -AddressPrefix "10.0.0.0/24";
    $vnet = New-AzureVirtualNetwork -Force -Name ('vnet' + $rgname) -ResourceGroupName $rgname -Location $loc -AddressPrefix "10.0.0.0/16" -DnsServer "10.1.1.1" -Subnet $subnet;
    $vnet = Get-AzureVirtualNetwork -Name ('vnet' + $rgname) -ResourceGroupName $rgname;
    $subnetId = $vnet.Subnets[0].Id;
    $nic_ids = @($null) * 1;
    $nic0 = New-AzureNetworkInterface -Force -Name ('nic0' + $rgname) -ResourceGroupName $rgname -Location $loc -SubnetId $subnetId;
    $nic_ids[0] = $nic0.Id;
    $vmconfig = Add-AzureVMNetworkInterface -VM $vmconfig -Id $nic0.Id -Primary;
    $st = Write-Verbose "Creating and getting NICs for '${loc}' and '${rgname}' - End";

    return $nic_ids;
}

function create_and_setup_vm_config_object
{
    param ([string] $loc, [string] $rgname, [string] $vmsize)

    $st = Write-Verbose "Creating and setting up the VM config object for '${loc}', '${rgname}' and '${vmsize}' - Start";

    $vmconfig = get_vm_config_object $rgname $vmsize

    $user = "Foo12";
    $password = "BaR#123" + $rgname;
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
    $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
    $computerName = "cn" + $rgname;
    $vmconfig = Set-AzureVMOperatingSystem -VM $vmconfig -Windows -ComputerName $computerName -Credential $cred;

    $st = Write-Verbose "Creating and setting up the VM config object for '${loc}', '${rgname}' and '${vmsize}' - End";

    return $vmconfig;
}


function setup_image_and_disks
{
    param ([string] $loc, [string] $rgname, [string] $stoname, $vmconfig)

    $st = Write-Verbose "Setting up image and disks of VM config object jfor '${loc}', '${rgname}' and '${stoname}' - Start";

    $osDiskName = 'osDisk';
    $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
    $osDiskCaching = 'ReadWrite';

    $vmconfig = Set-AzureVMOSDisk -VM $vmconfig -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

    # Image Reference;
    $vmconfig.StorageProfile.SourceImage = $null;
    $imgRef = Get-DefaultCRPImage;
    $vmconfig = ($imgRef | Set-AzureVMSourceImage -VM $vmconfig);

    # Do not add any data disks
    $vmconfig.StorageProfile.DataDisks = $null;

    $st = Write-Verbose "Setting up image and disks of VM config object jfor '${loc}', '${rgname}' and '${stoname}' - End";

    return $vmconfig;
}


function ps_vm_dynamic_test_func_3_pstestrg7743
{
    # Setup
    $rgname = 'pstestrg7743';

    try
    {
        $loc = 'East Asia';
        $vmsize = 'Standard_A2';

        $st = Write-Verbose "Running Test ps_vm_dynamic_test_func_3_pstestrg7743 - Start ${rgname}, ${loc} & ${vmsize}";

        $st = Write-Verbose 'Running Test ps_vm_dynamic_test_func_3_pstestrg7743 - Creating Resource Group';
        $st = New-AzureResourceGroup -Location $loc -Name $rgname;

        $vmconfig = create_and_setup_vm_config_object $loc $rgname $vmsize;

        # Setup Storage Account
        $stoname = get_created_storage_account_name $loc $rgname;

        # Setup Network Interface IDs
        $nicids = create_and_setup_nic_ids $loc $rgname $vmconfig;

        # Setup Image and Disks
        $st = setup_image_and_disks $loc $rgname $stoname $vmconfig;

        # Virtual Machine
        $st = Write-Verbose 'Running Test ps_vm_dynamic_test_func_3_pstestrg7743 - Creating VM';

        $vmname = 'vm' + $rgname;
        $st = New-AzureVM -ResourceGroupName $rgname -Location $loc -Name $vmname -VM $vmconfig;

        # Get VM
        $st = Write-Verbose 'Running Test ps_vm_dynamic_test_func_3_pstestrg7743 - Getting VM';
        $vm1 = Get-AzureVM -Name $vmname -ResourceGroupName $rgname;

        # Remove
        $st = Write-Verbose 'Running Test ps_vm_dynamic_test_func_3_pstestrg7743 - Removing VM';
        $st = Remove-AzureVM -Name $vmname -ResourceGroupName $rgname -Force;

        $st = Write-Verbose 'Running Test ps_vm_dynamic_test_func_3_pstestrg7743 - End';
    }
    finally
    {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}

