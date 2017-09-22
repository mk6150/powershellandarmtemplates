#Login to Azure RM Account
Login-AzureRmAccount

#Set Azure RM Location variable
$location = "East US"

#Set Azure RM Resource Group variable
$resourceGroupName = "iaas-ps1-lab-1"

#Set subnet variable
$subnets = @()
$subnets += New-AzureRmVirtualNetworkSubnetConfig -Name "Apps" -AddressPrefix 10.0.1.0/24
$subnets += New-AzureRmVirtualNetworkSubnetConfig -Name "Data" -AddressPrefix 10.0.2.0/24

#Set virtual network variable
$vnetName = "IaasPs1Lab1"
$vnet = New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName `
                                    -Location $location -AddressPrefix 10.0.0.0/16 `
                                    -Subnet $subnets