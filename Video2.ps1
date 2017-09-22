#Populate Azure RM cmdlets
Get-Command | where Name -Like "*AzureRM*"

#Login
Login-AzureRmAccount

#Display Azure Subscription
Get-AzureRmSubscription

#Select Azure RM Subscription
Set-AzureRmContext -SubscriptionId "8e4b0a2e-2f06-4baf-a865-566a2f99f863"

#Set up Azure Region
(Get-AzureRmResourceProvider -ProviderNameSpace Microsoft.Compute).Locations | sort -Unique 

#Create variable for location
$location = "East US"

#Create a variable for resource group
$resourceGroupName = "iaas-ps1-lab-1"

#Populate resource groups
Get-AzureRMResourceGroup

#Create a resource group
New-AzureRmResourceGroup -name "iaas-ps1-lab-1" -Location $location
