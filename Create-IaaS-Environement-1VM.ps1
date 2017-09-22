#Author: Marcel Kouame
#Site: https://www.kouamekiss.com 
#Email: m@kouamekiss.com
#LinkedIn: http://www.linkedin.com/in/kouame
#Twitter: http://www.twitter.com/marcelaepila
#Microsoft 70-533 Facebook Study Group: https://www.facebook.com/groups/107507613208191


#Begin Infrastructure Configuration

#Populate Azure Resource Manager Cmdlets
#Get-Command | where Name -Like "*AzureRM*"

#Login
Login-AzureRmAccount

#Set Azure Subscription
Set-AzureRmContext -SubscriptionId "YOU SUBSCRIPTION ID HERE"

#Azure Regions
#(Get-AzureRmResourceProvider -ProviderNamespace Microsoft.Compute).Locations | sort -Unique

#Define variable to store region
$location = "East US"

#Define variable to store Resource Group
$resourceGroupName = "basicMgmtLab"

#Create new resource group
New-AzureRmResourceGroup -Name $resourceGroupName -Location $location

#Populate resource groups within subscription
#Get-AzureRmResourceGroup

#subnets
$subnets = @()
$subnets += New-AzureRmVirtualNetworkSubnetConfig -Name "basicMgmtApps" -AddressPrefix 10.0.1.0/24
$subnets += New-AzureRmVirtualNetworkSubnetConfig -Name "basicMgmtData" -AddressPrefix 10.0.2.0/24
$vnetName = "BasicMgmtVnet"
$vnet = New-AzureRmVirtualNetwork -Name $vnetName `
                                    -ResourceGroupName $resourceGroupName `
                                    -Location $location `
                                    -AddressPrefix 10.0.0.0/16 `
                                    -Subnet $subnets

#Check the Virtual Network Creation
Get-AzureRmVirtualNetwork


#Create the network security group variable
$netsecgroName = "basicMgmtNSG"

#Verify uniqueness of storage account
Get-AzureRmStorageAccountNameAvailability -Name "basicmgmtlabstorage"

#Create a Azure RM Storage Account variable
$storageAcc = "basicmgmtlabstorage"


#Create a Azure RM Storage Account
$storageAccount = New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName `
                                                -Location $location `
                                                -Name $storageAcc `
                                                -Type Standard_LRS

#Variable for storage account URLs for VHD file paths
#$storageAcc = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccount
$blobEndpoint = $storageAccount.PrimaryEndpoints.Blob.ToString()

#Create Network Security rules configuration variable
$rules = @()
$rules += New-AzureRmNetworkSecurityRuleConfig -Name "RDP" 
                                                -Protocol Tcp -SourcePortRange "*" `
                                                -SourceAddressPrefix "*" `
                                                -DestinationPortRange "3389" `
                                                -DestinationAddressPrefix "*" `
                                                -Access Allow `
                                                -Description "Remote Desktop Access" `
                                                -Priority 100 `
                                                -Direction Inbound


#Create Network Security Group
$netsecgro = New-AzureRmNetworkSecurityGroup -Name $netsecgroName `
                                                -ResourceGroupName $resourceGroupName `
                                                -Location $location `
                                                -SecurityRules $rules



#Create a variable for the virtual network
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName -Name $vnetName


#Test availability of DNS name for web application
Test-AzureRmDnsAvailability -DomainQualifiedName "basic-management-lab-kouamekiss" -Location $location

#Set a variable for the DNS
$dnsName = "basic-management-lab-kouamekiss"

#Create a public ip address variable
$ipName = "basicMgmtVMPublicIP"

#Create a public IP
$pubip = New-AzureRmPublicIpAddress -Name $ipName `
                                    -ResourceGroupName $resourceGroupName ` 
                                    -Location $location `
                                    -AllocationMethod Dynamic `
                                    -DomainNameLabel $dnsName

#Create nic variable
$nicName = "basicMgmtVMNIC"

#creating a nic
$nic = New-AzureRmNetworkInterface -Name $nicName 
                                    -ResourceGroupName $resourceGroupName `
                                    -Location $location `
                                    -SubnetId $vnet.Subnets[0].Id `
                                    -PublicIpAddressId $pubip.Id `
                                    -NetworkSecurityGroupId $netsecgro.Id

#Create an AV Set
$avSet = New-AzureRmAvailabilitySet -ResourceGroupName $resourceGroupName `
                                    -Name "basicMgmtVMAVSet" `
                                    -Location $location

#Configure VM

#variable for VM Config
$vmName = "website-VM-1"
$vmSize = "Standard_DS2_v2"
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $avSet.Id

#Attach VM to NIC
$vmConfig | Add-AzureRmVMNetworkInterface -Id $nic.Id

#Attach additional storage to the VM
$dataDiskName = "basic-mgmt-vm-1-data-disk-1"
$dataDiskURI = $blobEndpoint + "vhds/" + $dataDiskName + ".vhd"
$vmConfig | Add-AzureRmVMDataDisk -Name "data-disk-1" `
                                    -VhdUri $dataDiskURI `
                                    -Caching None `
                                    -DiskSizeInGB 1023 `
                                    -Lun 0 `
                                    -CreateOption Empty

#Set User Credentials for VM
$cred = Get-Credential -Message "Enter admin credentials"
$vmConfig | Set-AzureRmVMOperatingSystem -Windows `
                                            -ComputerName $vmName `
                                            -Credential $cred `
                                            -ProvisionVMAgent

#Machine image
$publishName = "MicrosoftWindowsServer"
$offerName = "WindowsServer"
$skuName = "2016-Datacenter"
$vmConfig | Set-AzureRmVMSourceImage -PublisherName $publishName `
                                        -Offer $offerName `
                                        -Skus $skuName `
                                        -Version "latest"

#Provision the VM point to OS disk location
$osDiskName = "basic-mgmt-vm-1-osdisk1"
$osDiskURI = $blobEndpoint + "vhds/" + $osDiskName + ".vhd"

$vmConfig | Set-AzureRmVMOSDisk -Name $osDiskName -VhdUri $osDiskURI -CreateOption FromImage

$vmConfig | New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $location


#End Infrastructure Configuration

#Author: Marcel Kouame
#Site: https://www.kouamekiss.com
#Email: m@kouamekiss.com
#LinkedIn: http://www.linkedin.com/in/kouame
#Twitter: http://www.twitter.com/marcelaepila
#Microsoft 70-533 Facebook Study Group: https://www.facebook.com/groups/107507613208191