# connect-AzAccount -subscription '45281fc4-c2b7-4b8c-b6d8-38887ee8a127' -UseDeviceAuthentication

$RG="rg-DualStack-eastus"
$RTName="Firewall-route"
$Resource = Get-AzResource -ResourceGroupName $RG -ResourceName $RTName
#Export Template based on resourceid
$JsonPath="/tmp/rt-dualstack-east-asr.json"
$template = Export-AzResourcegroup -ResourceGroupName $RG -Resource $Resource.ResourceId -Path $JsonPath
#Import back as JSON
$VNetJson = get-content $template.Path | ConvertFrom-Json

## Edit file manually for now


Add to:

Check parameters.json file when using Portal

"parameters": {
    "routeTables_Firewall_route_name": {

"defaultValue" : "firewall-routetable-asr", 


line 16:

Note: REgion change not working on Azure Portal, only through Powershell or AZ CLI

 "location": "westus",


New-AzResourceGroupDeployment `
  -Name ExampleDeployment `
  -ResourceGroupName $RG `
  -TemplateFile $JsonPath
