# Powershell - List of PrivateEndpoints DNS in a subscription and checks local DNS to see if they match

  - Need to update the on-premise DNS table manually due to multiple Azure tenants or multiple Private DNS Zones (you can have one per Vnet)
  - Conditional Forwarding is not an option from on-premise to Azure