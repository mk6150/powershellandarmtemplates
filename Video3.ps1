#subnets
$subnets = @()
$subnets += New-AzureRmVirtualNetworkSubnetConfig -Name "AppsTest" -AddressPrefix 10.1.1.0/24
$subnets += New-AzureRmVirtualNetworkSubnetConfig -Name "DataTest" -AddressPrefix 10.1.2.0/24
$vnetName = "IaasLabPs1Vnet"
$vnet = New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName iaas-ps1-lab -Location `
                                    $location -AddressPrefix 10.0.0.0/8 -Subnet $subnets

Get-AzureRmVirtualNetwork