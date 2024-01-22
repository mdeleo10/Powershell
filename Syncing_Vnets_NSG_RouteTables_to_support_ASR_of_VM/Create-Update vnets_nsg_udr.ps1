ssh az-west.mdeleo.com



pwsh

Connect-AzAccount

or 

Connect-AzAccount -UseDeviceAuthentication

Set-AzContext -Subscription "Connectivity"


$ResourceGroup="PrimaryRegion"
$PrimaryRegion="eastus"
$BackupRegion="westus"


# Notes:
# Vnets, NGSs and UDRs are regional only. If your vnet needs an NSG or UDR, it must also exist in the same region.

# Export VNET
$ResourceGroup="PrimaryRegion"
$PrimaryRegion="eastus"
$BackupRegion="westus"
Export-AzResourceGroup `
  -ResourceGroupName $ResourceGroup `
  -IncludeParameterDefaultValue `
  -Force `
  -Resource "/subscriptions/45281fc4-c2b7-4b8c-b6d8-38887ee8a127/resourceGroups/PrimaryRegion/providers/Microsoft.Network/virtualNetworks/vnet10primary"

# Export NSG(s)
$PrimaryRegion="westus3"
$ResourceGroup="rg-DualStack-westus3"
Export-AzResourceGroup `
  -ResourceGroupName $ResourceGroup `
  -IncludeParameterDefaultValue `
  -Force `
  -Resource "/subscriptions/45281fc4-c2b7-4b8c-b6d8-38887ee8a127/resourceGroups/rg-DualStack-westus3/providers/Microsoft.Network/networkSecurityGroups/ubuntu-NetworkSecurityGroup-westus3"


# Export UDR
$PrimaryRegion="eastus"
$ResourceGroup="rg-DualStack-eastus"
Export-AzResourceGroup `
  -ResourceGroupName $ResourceGroup `
  -IncludeParameterDefaultValue `
  -Force `
  -Resource "/subscriptions/45281fc4-c2b7-4b8c-b6d8-38887ee8a127/resourceGroups/rg-DualStack-eastus/providers/Microsoft.Network/routeTables/Firewall-route"


# Create Vnet Duplicate in Secondary Region
#$File="PrimaryRegion.json"
#$FindStr="`"defaultValue`": `"vnet10primary`","
#$ReplaceStr="`"defaultValue`": `"vnet10primary-backup-asr`","
#(Get-Content $File) | 
#Foreach-Object {$_ -replace $FindStr,$ReplaceStr}  | 
#Out-File $File-out

$File="PrimaryRegion.json"
$FindStr="eastus"
$ReplaceStr="westus"
(Get-Content $File) | 
Foreach-Object {$_ -replace $FindStr,$ReplaceStr}  | 
Out-File $File-out

$File="PrimaryRegion.json-out"

$ResourceGroup="PrimaryRegion-backupasr"
# New-AzResourceGroup -Name $ResourceGroup -Location $BackupRegion
New-AzResourceGroupDeployment `
    -ResourceGroupName $ResourceGroup `
    -Tag @{ 'CreatedBy'='PowerShellScrupt' } `
    -virtualNetworks_vnet10primary_name "vnet10primary-backup-asr"
    -TemplateFile $File

Remove-AzResourceGroup -Name $ResourceGroup -Force

# Create NSG Duplicate in Secondary Region
$File="rg-DualStack-westus3.json"
$FindStr="`"defaultValue`": `"ubuntu-NetworkSecurityGroup-westus3`","
$ReplaceStr="`"defaultValue`": `"ubuntu-NetworkSecurityGroup-westus3-backup-asr`","
(Get-Content $File) | 
Foreach-Object {$_ -replace $FindStr,$ReplaceStr}  | 
Out-File $File-out

$File="rg-DualStack-westus3.json-out"
$FindStr="eastus"
$ReplaceStr="westus"
(Get-Content $File) | 
Foreach-Object {$_ -replace $FindStr,$ReplaceStr}  | 
Out-File $File

# Create UDR Duplicate in Secondary Region
$File="rg-DualStack-eastus.json"
$FindStr="`"defaultValue`": `"Firewall-route`","
$ReplaceStr="`"defaultValue`": `"Firewall-route-backup-asr`","
(Get-Content $File) | 
Foreach-Object {$_ -replace $FindStr,$ReplaceStr}  | 
Out-File $File-out

$File="rg-DualStack-eastus.json-out"
$FindStr="eastus"
$ReplaceStr="westus"
(Get-Content $File) | 
Foreach-Object {$_ -replace $FindStr,$ReplaceStr}  | 
Out-File $File


