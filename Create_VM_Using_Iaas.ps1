$location
$resourceGroupName

#Verify uniqueness of storage account
Get-AzureRmStorageAccountNameAvailability -Name "iaasps1lab1storage"

#Create a Azure RM Storage Account variable
$storageAcc = "iaasps1lab1storage"


#Create a Azure RM Storage Account
$storageAccount = New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Location $location -Name $storageAcc -Type Standard_LRS

#Variable for storage account URLs for VHD file paths
#$storageAcc = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccount
$blobEndpoint = $storageAccount.PrimaryEndpoints.Blob.ToString()

#Create Network Security rules configuration variable
$rules = @()
$rules += New-AzureRmNetworkSecurityRuleConfig -Name "RDP" -Protocol Tcp -SourcePortRange "*" -SourceAddressPrefix "*" -DestinationPortRange "3389" `
                                                    -DestinationAddressPrefix "*" -Access Allow -Description "Remote Desktop Access" -Priority 100 -Direction Inbound


#Create Network Security Group
$netsecgro = New-AzureRmNetworkSecurityGroup -Name "websitensg" -ResourceGroupName $resourceGroupName -Location $location -SecurityRules $rules



#Create a variable for the virtual network
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName -Name $vnetName


#Test availability of DNS name for web application
Test-AzureRmDnsAvailability -DomainQualifiedName "iaas-ps1-lab-1-web" -Location $location

#Set a variable for the DNS
$dnsName = "iaas-ps1-lab-1-web"

#Create a public ip address variable
$ipName = "websiteVMPublicIP"

#Create a public IP
$pubip = New-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $resourceGroupName -Location $location -AllocationMethod Dynamic -DomainNameLabel $dnsName

#Create nic variable
$nicName = "websiteVMNIC"

#creating a nic
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $resourceGroupName -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pubip.Id -NetworkSecurityGroupId $netsecgro.Id

#Create an AV Set
$avSet = New-AzureRmAvailabilitySet -ResourceGroupName $resourceGroupName -Name "websiteAVSet" -Location $location

#Configure VM

#variable for VM Config
$vmName = "website-VM-1"
$vmSize = "Standard_DS2_v2"
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $avSet.Id

#Attach VM to NIC
$vmConfig | Add-AzureRmVMNetworkInterface -Id $nic.Id





#Attach additional storage to the VM
$dataDiskName = "web-vm-1-data-disk-1"
$dataDiskURI = $blobEndpoint + "vhds/" + $dataDiskName + ".vhd"
$vmConfig | Add-AzureRmVMDataDisk -Name "data-disk-1" -VhdUri $dataDiskURI -Caching None -DiskSizeInGB 1023 -Lun 0 -CreateOption Empty

#Set User Credentials for VM
$cred = Get-Credential -Message "Enter admin credentials"
$vmConfig | Set-AzureRmVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent

#Machine image
$publishName = "MicrosoftWindowsServer"
$offerName = "WindowsServer"
$skuName = "2016-Datacenter"
$vmConfig | Set-AzureRmVMSourceImage -PublisherName $publishName -Offer $offerName -Skus $skuName -Version "latest"

#Provision the VM point to OS disk location
$osDiskName = "website-vm-1-osdisk1"
$osDiskURI = $blobEndpoint + "vhds/" + $osDiskName + ".vhd"

$vmConfig | Set-AzureRmVMOSDisk -Name $osDiskName -VhdUri $osDiskURI -CreateOption FromImage

$vmConfig | New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $location




