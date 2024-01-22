# connect-AzAccount -subscription '45281fc4-c2b7-4b8c-b6d8-38887ee8a127' -UseDeviceAuthentication

$RG="rg-DualStack-eastus"
$VNETName="ubuntu-Vnet-eastus"
$Resource = Get-AzResource -ResourceGroupName $RG -ResourceName $VNETName
#Export Template based on resourceid
$JsonPath="/tmp/vnet-dualstack-east-asr.json"
$template = Export-AzResourcegroup -ResourceGroupName $RG -Resource $Resource.ResourceId -Path $JsonPath
#Import back as JSON
$VNetJson = get-content $template.Path | ConvertFrom-Json

## Edit file manually for now


Add to:

Check parameters.json file when using Portal

  "parameters": {
    "virtualNetworks_ubuntu_Vnet_eastus_name": {

"defaultValue" : "ubuntu-Vnet-eastus-asr", 


line 21:

Note: REgion change not working on Azure Portal, only through Powershell or AZ CLI

 "location": "westus",


line 73:

Remove whole section:  "virtualNetworkPeerings": [

line: ?

Remove whole section: "type": "Microsoft.Network/virtualNetworks/virtualNetworkPeerings",


New-AzResourceGroupDeployment `
  -Name ExampleDeployment `
  -ResourceGroupName $RG `
  -TemplateFile $JsonPath
