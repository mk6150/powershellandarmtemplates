
Get-AzureRmRemoteDesktopFile -ResourceGroupName $resourceGroupNameHIPPA -Name $vmNameHIPPA1 -Launch
#region begin region ----> Resource Group and Location

#Set location and Resource Group Name Variables
$location = "East US"
$resourceGroupNameHIPPA = "HIPPA-appgw-rg"


# Create new resource group for the applciation gateway
New-AzureRMResourceGroup -Name $resourceGroupNameHIPPA -Location $location

#endregion

#region begin region --- > Virtual Network Configurations

#Create subnet array for application gateway subnet and backend pool subnet

$subnetsHIPPA = @()
$subnetsHIPPA += New-AzureRmVirtualNetworkSubnetConfig -Name "HIPPAappGWSubnet" -AddressPrefix 10.0.0.0/24
$subnetsHIPPA += New-AzureRmVirtualNetworkSubnetConfig -Name "HIPPAappsBEPSubnet" -AddressPrefix 10.0.2.0/24


#Create a virtual network name variable
$vnetNameHIPPA = "HIPPAappGWVnet"

#Create virtual network and assign it to a variable
$vnetHIPPA = New-AzureRmVirtualNetwork -Name $vnetNameHIPPA `
                                        -ResourceGroupName $resourceGroupNameHIPPA `
                                        -Location $location `
                                        -AddressPrefix 10.0.0.0/16 `
                                        -Subnet $subnetsHIPPA
#Get virtual network object
$vnetHIPPA = Get-AzureRmVirtualNetwork -Name $vnetNameHIPPA `
                                        -ResourceGroupName $resourceGroupNameHIPPA


#Assign variables to the subnets
$gatewaySubnetHIPPA = $vnetHIPPA.Subnets[0]
$backendPoolSubnetHIPPA = $vnetHIPPA.Subnets[1]

#endregion

#region begin region --- > Network Security Group Configurations

#Create Network Security rules configuration variable
$rulesHIPPA = @()
$rulesHIPPA += New-AzureRmNetworkSecurityRuleConfig -Name "RDP" `
                                                        -Protocol Tcp `
                                                        -SourcePortRange "*" `
                                                        -SourceAddressPrefix "*" `
                                                        -DestinationPortRange "3389" `
                                                        -DestinationAddressPrefix "*" `
                                                        -Access Allow -Description "Remote Desktop Access" `
                                                        -Priority 100 `
                                                        -Direction Inbound


#Create Network Security Group
$netsecgroHIPPA = New-AzureRmNetworkSecurityGroup -Name "appGWnsg" `
                                                    -ResourceGroupName $resourceGroupNameHIPPA `
                                                    -Location $location `
                                                    -SecurityRules $rulesHIPPA

$netsecgroHIPPA = Get-AzureRmNetworkSecurityGroup -Name "appGWnsg" `
                                                    -ResourceGroupName $resourceGroupNameHIPPA

#endregion

#region begin region --- > Storage Account Configurations

#Verify uniqueness of storage account
Get-AzureRmStorageAccountNameAvailability -Name "hippaappgwlabstorage"

#Create a Azure RM Storage Account variable
$storageAccountHIPPA = "hippaappgwlabstorage"


#Create a Azure RM Storage Account
New-AzureRmStorageAccount -ResourceGroupName $resourceGroupNameHIPPA `
                            -Location $location `
                            -Name $storageAccountHIPPA `
                            -Type Standard_LRS

$hippaStorageAccountObject = Get-AzureRmStorageAccount -Name $storageAccountHIPPA -ResourceGroupName $resourceGroupNameHIPPA

#endregion

#region begin region --- > NIC #1 Configurations 

#Create nic variable
$nicNameHIPPA1 = "HIPPAappGWVMNIC1"

#creating a nic
$nicHIPPA1 = New-AzureRmNetworkInterface -Name $nicNameHIPPA1 `
                                            -ResourceGroupName $resourceGroupNameHIPPA `
                                            -Location $location `
                                            -SubnetId $vnetHIPPA.Subnets[0].Id `
                                            -NetworkSecurityGroupId $netsecgroHIPPA.Id

#Store nicHIPPA1 object in variable
$nicHIPPA1 = Get-AzureRmNetworkInterface -Name $nicNameHIPPA1 -ResourceGroupName $resourceGroupNameHIPPA

#Get nicHIPPA1 configuration and store in a config variable
$nicHIPPA1Config = Get-AzureRmNetworkInterfaceIpConfig -Name ipconfig1 -NetworkInterface $nicHIPPA1

#Get nicHIPPA1 private IP address and store it in a variable
$nicHIPPA1PrivateIp = $nicHIPPA1Config.PrivateIpAddress


                                       
#endregion

#region begin region --- > NIC #2 Configurations 

#Create nic variable
$nicNameHIPPA2 = "HIPPAappGWVMNIC2"

#creating a nic
$nicHIPPA2 = New-AzureRmNetworkInterface -Name $nicNameHIPPA2 `
                                            -ResourceGroupName $resourceGroupNameHIPPA `
                                            -Location $location `
                                            -SubnetId $vnetHIPPA.Subnets[0].Id `
                                            -NetworkSecurityGroupId $netsecgroHIPPA.Id

#Store nicHIPPA2 object in variable
$nicHIPPA1 = Get-AzureRmNetworkInterface -Name $nicNameHIPPA1 -ResourceGroupName $resourceGroupNameHIPPA




#Get nicHIPPA2 configuration and store in a config variable
$nicHIPPA2Config = Get-AzureRmNetworkInterfaceIpConfig -Name ipconfig1 -NetworkInterface $nicHIPPA2

#Get nicHIPPA2 private IP address and store it in a variable
$nicHIPPA2PrivateIp = $nicHIPPA2Config.PrivateIpAddress

#Store nicHIPPA2 object in variable
$nicHIPPA2 = Get-AzureRmNetworkInterface -Name $nicNameHIPPA2 -ResourceGroupName $resourceGroupNameHIPPA


#endregion

#region begin region --- > Availability Set Configurations

#Create an AV Set
$avSetHIPPA2 = New-AzureRmAvailabilitySet -ResourceGroupName $resourceGroupNameHIPPA `
                                            -Name "HIPPAappgwAVSet2" `
                                            -Location $location

#Store AV Set object in variable
$avSetHIPPA2 = Get-AzureRmAvailabilitySet -ResourceGroupName $resourceGroupNameHIPPA `
                                            -Name "HIPPAappgwAVSet2"

#endregion

#region begin region --- > Virtual Machine #1 Configurations

#Configure VM

#variable for VM Config
$vmNameHIPPA1 = "HIPPA-VM-1"
$vmSizeHIPPA1 = "Standard_DS2_v2"
$vmConfigHIPPA1 = New-AzureRmVMConfig -VMName $vmNameHIPPA1 `
                                        -VMSize $vmSizeHIPPA1 `
                                        -AvailabilitySetId $avSetHIPPA2.Id

#Attach VM to NIC
$vmConfigHIPPA1 | Add-AzureRmVMNetworkInterface -Id $nicHIPPA1.Id


#Variable for storage account URLs for VHD file paths
$storageAccHIPPA1 = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupNameHIPPA -Name $storageAccountHIPPA
$blobEndpointHIPPA = $storageAccHIPPA1.PrimaryEndpoints.Blob.ToString()


#Attach additional storage to the VM
$dataDiskNameHIPPA1 = "hippa-vm-1-data-disk-1"
$dataDiskURIHIPPA1 = $blobEndpointHIPPA + "vhds/" + $dataDiskNameHIPPA1 + ".vhd"
$vmConfigHIPPA1 | Add-AzureRmVMDataDisk -Name "hippa-vm-1-data-disk-1" `
                                            -VhdUri $dataDiskURIHIPPA1 `
                                            -Caching None `
                                            -DiskSizeInGB 1023 `
                                            -Lun 0 `
                                            -CreateOption Empty

#Set User Credentials for VM
$credHIPPA1 = Get-Credential -Message "Enter admin credentials"
$vmConfigHIPPA1 | Set-AzureRmVMOperatingSystem -Windows `
                                                -ComputerName $vmNameHIPPA1 `
                                                -Credential $credHIPPA1 `
                                                -ProvisionVMAgent

#Machine image
$publishNameHIPPA = "MicrosoftWindowsServer"
$offerNameHIPPA = "WindowsServer"
$skuNameHIPPA = "2016-Datacenter"
$vmConfigHIPPA1 | Set-AzureRmVMSourceImage -PublisherName $publishNameHIPPA `
                                            -Offer $offerNameHIPPA `
                                            -Skus $skuNameHIPPA `
                                            -Version "latest"

#Provision the VM point to OS disk location
$osDiskNameHIPPA1 = "hippa-vm-1-osdisk1"
$osDiskURIHIPPA1 = $blobEndpointHIPPA + "vhds/" + $osDiskNameHIPPA1 + ".vhd"

$vmConfigHIPPA1 | Set-AzureRmVMOSDisk -Name $osDiskNameHIPPA1 `
                                        -VhdUri $osDiskURIHIPPA1 `
                                        -CreateOption FromImage

$vmConfigHIPPA1 | New-AzureRmVM -ResourceGroupName $resourceGroupNameHIPPA -Location $location

#endregion

#region begin region --- > Virtual Machine #2 Configurations

#Configure VM

#variable for VM Config
$vmNameHIPPA2 = "HIPPA-VM-2"
$vmSizeHIPPA2 = "Standard_DS2_v2"
$vmConfigHIPPA2 = New-AzureRmVMConfig -VMName $vmNameHIPPA2 `
                                        -VMSize $vmSizeHIPPA2 `
                                        -AvailabilitySetId $avSetHIPPA2.Id

#Attach VM to NIC
$vmConfigHIPPA2 | Add-AzureRmVMNetworkInterface -Id $nicHIPPA2.Id


#Variable for storage account URLs for VHD file paths
$storageAccHIPPA2 = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupNameHIPPA -Name $storageAccountHIPPA
$blobEndpointHIPPA = $storageAccHIPPA2.PrimaryEndpoints.Blob.ToString()


#Attach additional storage to the VM
$dataDiskNameHIPPA2 = "hippa-vm-2-data-disk-2"
$dataDiskURIHIPPA2 = $blobEndpointHIPPA + "vhds/" + $dataDiskNameHIPPA2 + ".vhd"
$vmConfigHIPPA2 | Add-AzureRmVMDataDisk -Name "hippa-vm-2-data-disk-2" `
                                            -VhdUri $dataDiskURIHIPPA2 `
                                            -Caching None `
                                            -DiskSizeInGB 1023 `
                                            -Lun 0 `
                                            -CreateOption Empty

#Set User Credentials for VM
#$credHIPPA2 = Get-Credential -Message "Enter admin credentials"
#$vmConfigHIPPA1 | Set-AzureRmVMOperatingSystem -Windows `
                                                #-ComputerName $vmNameHIPPA1 `
                                                #-Credential $credHIPPA1 `
                                                #-ProvisionVMAgent
#Pass user credentials as a secure object
$credHIPPA2path = "C:\kouamekiss\HIPPAVM2Credential.xml"

New-Object System.Management.Automation.PSCredential("marcel", `
    (ConvertTo-SecureString -AsPlainText -Force "Password123")) | `
    Export-CliXml $credHIPPA2path

$credHIPPA2 = import-clixml -path $credHIPPA2path

#Pass config
$vmConfigHIPPA2 | Set-AzureRmVMOperatingSystem -Windows `
                                                -ComputerName $vmNameHIPPA2 `
                                                -Credential $credHIPPA2 `
                                                -ProvisionVMAgent


#Machine image
$publishNameHIPPA = "MicrosoftWindowsServer"
$offerNameHIPPA = "WindowsServer"
$skuNameHIPPA = "2016-Datacenter"
$vmConfigHIPPA2 | Set-AzureRmVMSourceImage -PublisherName $publishNameHIPPA `
                                            -Offer $offerNameHIPPA `
                                            -Skus $skuNameHIPPA `
                                            -Version "latest"

#Provision the VM point to OS disk location
$osDiskNameHIPPA2 = "hippa-vm-2-osdisk2"
$osDiskURIHIPPA2 = $blobEndpointHIPPA + "vhds/" + $osDiskNameHIPPA2 + ".vhd"

$vmConfigHIPPA2 | Set-AzureRmVMOSDisk -Name $osDiskNameHIPPA2 `
                                        -VhdUri $osDiskURIHIPPA2 `
                                        -CreateOption FromImage

$vmConfigHIPPA2 | New-AzureRmVM -ResourceGroupName $resourceGroupNameHIPPA -Location $location

#endregion




#region begin region --- > Public IP Configurations

#Create a public ip address variable
$ipNameHIPPA = "appGWVMPublicIP"

#Create a public IP
$pubipHIPPA = New-AzureRmPublicIpAddress -Name $ipNameHIPPA `
                                            -ResourceGroupName $resourceGroupNameHIPPA `
                                            -Location $location `
                                            -AllocationMethod Dynamic
                     

#endregion

#region begin region --- > Application Gateway Configuration Object

$hippaAuthCertFile = "C:\kouamekiss\"
$hippaCertFile = C:\kouamekiss\hippaAppGatewayPrivateKey.pfx
$hippaCertPass = Password123

$hippaBEIpAdd = @()
$hippaBEIpAdd += $nicHIPPA1PrivateIp
$hippaBEIpAdd += $nicHIPPA2PrivateIp

#Create a gateway IP configuration
$hippaGatewayIpConfig = New-AzureRmApplicationGatewayIPConfiguration -Name "gatewayconfig" -Subnet $vnetHIPPA.Subnets[0]

#Create a front-end IP configuration
$hippaFrontEndIpConfig = New-AzureRmApplicationGatewayFrontendIpConfig -Name "HIPPAFrontEndIP01" -PublicIPAddress $pubipHIPPA

#Configure backend IP Address Pool or FQDN -BackendFqdns
$hippaBackEndPool = New-AzureRmApplicationGatewayBackendAddressPool -Name "HIPPAPool01" -BackendIPAddresses $hippaBEIpAdd 

#Configure a front-end IP Port for public IP endpoint
$hippaFrontEndPort = New-AzureRmApplicationGatewayFrontendPort -Name "HIPPAFrontEndPort01" -Port 443

#Create the certificate for the application gateway. Used to decrypt and re-encrypt the traffic on the application gateway
$hippaCert = New-AzureRmApplicationGatewaySslCertificate -Name hippacert01 -CertificateFile $hippaCertFile -Password $hippaCertPass

#Create an HTTP listener for the application gateway and assign the front-end IP configuration port
$hippaListener = New-AzureRmApplicationGatewayHttpListener -Name hippalistener01 `
                                                            -Protocol Https `
                                                            -FrontendIPConfiguration $hippaFrontEndIpConfig `
                                                            -FrontendPort $hippaFrontEndPort `
                                                            -SslCertificate $hippaCert

#Upload the certificate to be used on the ssl enabled backend pool resources

#region begin region -----> Additional SSL Tools

#Get-SslCertificateBinding for default SSL binding. Use the public key from this request in the following section.
#If youre using host headers and SNI on HTTPS bindings and you do not recieve a response and certificate from a manual browser request to 127.0.0.1 on the backends, 
#you must setup a default SSL binding on the backends or else the probes will fail and the backend will not be whitelisted.
#https://docs.microsoft.com/en-us/iis/configuration/system.applicationhost/sites/sitedefaults/bindings/binding


#endregion

$hippaAuthCert = New-AzureRmApplicationGatewayAuthenticationCertificate -Name "HIPPAWhiteListCert1" -CertificateFile $hippaAuthCertFile

#Configure the application gateway back-end http settings. Assign the certificate uploaded in the preceding step to the http settings
$hippaPoolSetting = New-AzureRmApplicationGatewayBackendHttpSettings -Name "HIPPASetting01" `
                                                                        -Port 443 -Protocol Https `
                                                                        -CookieBasedAffinity Enabled `
                                                                        -AuthenticationCertificates $hippaAuthCert

#Create a load balancer routing rule that configures the load balancer behavior - basic round robin will be created
$hippaLBRule = New-AzureRmApplicationGatewayRequestRoutingRule -Name "HIPPALBRule01" `
                                                                    -RuleType Basic `
                                                                    -BackendHttpSettings $hippaPoolSetting `
                                                                    -HttpListener $hippaListener `
                                                                    -BackendAddressPool $hippaBackEndPool

#Configure the instance size of the application gateway in Standard_Small, Standard_Medium, and Standard_Large. For capacity the available values are 1-10
$hippaSku = New-AzureRmApplicationGatewaySku -Name Standard_Small -Tier Standard -Capacity 4

#Configure SSL Policy to be used on the application gateway. The following has disabled TLSv1.0 
$hippaSSLPolicy = New-AzureRmApplicationGatewaySslPolicy -DisabledSslProtocols TLSv1_0


#endregion

#region begin region --- > Create the Application Gateway

$hippaAppGW = New-AzureRmApplicationGateway -Name hippaAppGateway `
                                                -SslCertificates $hippaCert `
                                                -ResourceGroupName $resourceGroupNameHIPPA `
                                                -Location $location `
                                                -BackendAddressPools $hippaBackEndPool `
                                                -BackendHttpSettingsCollection $hippaPoolSetting `
                                                -FrontendIPConfigurations $hippaFrontEndIpConfig `
                                                -GatewayIPConfiguration $hippaGatewayIpConfig `
                                                -FrontendPorts $hippaFrontEndPort `
                                                -HttpListeners $hippaListener `
                                                -RequestRoutingRules $hippaLBRule `
                                                -Sku $hippaSku `
                                                -SslPolicy $hippaSSLPolicy `
                                                -AuthenticationCertificates $hippaAuthCert `
                                                -Verbose


#endregion

#region begin region ---> Application Gateway Basic Management

#Disable SSL protocol versions on existing application gateway

#Get Application Gateway
$gateway = Get-AzureRmApplicationGateway -Name hippaAppGateway -ResourceGroupName $resourceGroupNameHIPPA

#Define the SSL Policy
Set-AzureRmApplicationGatewaySslPolicy -DisabledSslProtocols TLSv1_0, TLSv1_1 -ApplicationGateway $gateway

#Update the gateway
$gateway | Set-AzureRmApplicationGateway

#Get Application Gateway DNS Name
Get-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupNameHIPPA -Name $ipNameHIPPA




#endregion




















#region begin region --- > DNS Name Configurations


#Test availability of DNS name for web application
Test-AzureRmDnsAvailability -DomainQualifiedName "hippa-app-gateway-lab" -Location $location

#Set a variable for the DNS
$dnsNameHIPPA = "hippa-app-gateway-lab"

#endregion



Get-AzureRmRemoteDesktopFile -ResourceGroupName $resourceGroupNameHIPPA -Name $vmNameHIPPA1 -Launch

Get-AzureRmRemoteDesktopFile -ResourceGroupName $resourceGroupNameHIPPA -Name $vmNameHIPPA1 -LocalPath C:\kouamekiss\HIPPAVM1.rdp

#Create a public ip address variable
$ipNameHIPPAVM1 = "HIPPA-VM-1-PubIP"

#Create a public IP
$pubipHIPPAVM1 = New-AzureRmPublicIpAddress -Name $ipNameHIPPAVM1 -ResourceGroupName $resourceGroupNameHPPA -Location $location -AllocationMethod Dynamic

#Set Network Interface
Set-NetworkInterface -Name $nicNameHIPPA1 -PublicIpAddress 

Get-AzureRmRemoteDesktopFile -ResourceGroupName $resourceGroupNameHIPPA -Name $vmNameHIPPA1 -LocalPath C:\kouamekiss\HIPPAVM1.rdp
Get-AzureRmRemoteDesktopFile -ResourceGroupName $resourceGroupNameHIPPA -Name $vmNameHIPPA2 -LocalPath C:\kouamekiss\HIPPAVM2.rdp



