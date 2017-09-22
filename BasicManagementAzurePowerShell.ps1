#region begin region ---> Basic ARM VM Management

#region begin region ---> Virtual Machine Status

Get-AzureRmVM

#endregion


#region begin region ---> Connect to VM via RDP/Local RDP File Save
Get-AzureRmRemoteDesktopFile -ResourceGroupName $resourceGroupName -Name $vmName -Launch

#OR to save the RDP agent locally
Get-AzureRmRemoteDesktopFile -ResourceGroupName $resourceGroupName -Name $vmName -LocalPath C:\kouamekiss\BasicMgmtVM.rdp
#endregion


#region begin region ---> Start and Stop Virtual Machines

#Stop VM
Stop-AzureRmVM -ResourceGroupName $resourceGroupName -Name $vmName

#Remain Provisioned
Stop-AzureRmVM -ResourceGroupName $resourceGroupName -Name $vmName -StayProvisioned

#Avoid prompts about IP Address Release
Stop-AzureRmVM -ResourceGroupName $resourceGroupName -Name $vmName -StayProvisioned -Force

#Start VM

Start-AzureRmVM -ResourceGroupName $resourceGroupName -Name $vmName

#endregion


#region begin region ---> Attach additional storage to a VM

#Get VM Current Configuration
$vm = Get-AzureRmVM -ResourceGroupName $resourceGroupName -Name $vmName

#Define Variables
$dataDisk2Name = "vm1-datadisk2"
$dataDisk2Uri = $blobEndpoint + "vhds/" + $dataDisk2Name + ".vhd"

#Pass the config to Add-AzureRmVMDataDisk cmdlet
$vm | Add-AzureRmVMDataDisk -Name $datadisk2Name -VhdUri $dataDisk2Uri -Caching None -DiskSizeInGB 1023 -Lun 1 -CreateOption Empty

#Pass the config to the UpdateAzureRmVM cmdlet
$vm | Update-AzureRmVm -ResourceGroupName $resourceGroupName


#endregion


#region begin region ---> Add a new rule to a Network Security Group

#Get the NSG associated with the VM
$netsecgro = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Name $netsecgroName

#Add new HTTP rule 
$netsecgro | Add-AzureRmNetworkSecurityRuleConfig -Name "HTTP" -Protocol Tcp -SourcePortRange "*" -DestinationPortRange "80" -SourceAddressPrefix "*" `
                                                    -DestinationAddressPrefix "*" -Access Allow -Description "Web Access" -Priority 200 -Direction Inbound

#Add new RDP rule to allow from a seperate management subnet
$netsecgro | Add-AzureRmNetworkSecurityRuleConfig -Name "RDPMgmt" -Protocol Tcp -SourcePortRange "*" -DestinationPortRange "3389" -SourceAddressPrefix "10.0.3.0/24" `
                                                    -DestinationAddressPrefix "*" -Access Allow -Description "RDP Management Access" -Priority 300 -Direction Inbound

#Update the network security group
$netsecgro | Set-AzureRmNetworkSecurityGroup

#Review updated network security group
Get-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroupName


#endregion


#region begin region ---> Extend the Virtual Network

#Get Network Security Group
$netsecgro = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Name $netsecgroName

#Get existing virtual network object and store it in a variable
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName -Name $vnetName

#Create a new subnet
$vnet | Add-AzureRmVirtualNetworkSubnetConfig -Name "Management" -AddressPrefix "10.0.3.0/24" -NetworkSecurityGroupId $netsecgro.Id

#Update the virtual network
$vnet |Set-AzureRmVirtualNetwork

#endregion

#endregion
