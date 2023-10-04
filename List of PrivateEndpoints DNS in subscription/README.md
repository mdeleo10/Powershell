# Powershell - List of PrivateEndpoints DNS in a subscription and checks local DNS to see if they match

This might be useful when updating or reviewing Private Endpoint IP addresses that not using conditional forwarding from the local DNS to the Azure DNS for resolution of the Azure Private DNS Zone(s). There can be many valid reasons for this
  - Many tenants and no way to point to a single Azure DNS for resolution
  - Many subscriptions and managed independently
  - Operational concerns

This is a report for ONE subscription. Work would be needed to add many subscriptions.

