#Populate Azure Resource Manager Cmdlets
Get-Command | where Name -Like "*AzureRM*"

#Login
Login-AzureRmAccount

#Set Azure Subscription
Set-AzureRmContext -SubscriptionId "8e4b0a2e-2f06-4baf-a865-566a2f99f863"

#Azure Regions
(Get-AzureRmResourceProvider -ProviderNamespace Microsoft.Compute).Locations | sort -Unique

#Define variable to store region
$location = "East US"

#Define variable to store Resource Group
$resourceGroupName = "iaas-ps1-lab"

#Create new resource group
New-AzureRmResourceGroup -Name $resourceGroupName -Location $location

#Populate resource groups within subscription
Get-AzureRmResourceGroupn