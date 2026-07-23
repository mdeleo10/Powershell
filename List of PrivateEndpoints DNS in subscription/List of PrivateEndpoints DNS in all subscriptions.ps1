# Lists all private endpoints in a all the Subscriptions. Then it checks to verify if the DNS responds to the same address and needs
# verification.
#
# Might require:
# Install-Module -Name Az -Repository PSGallery -Force  
# 
# Perform 
# Connect-AzAccount before running

# Reference https://learn.microsoft.com/en-us/answers/questions/1265387/is-there-a-way-to-list-all-the-private-dns-zones-l

param (
    [string]$reportName1 = "PrivateDNSZone.csv",
    [string]$reportName2 = "PrivateDNSZone2.csv"
)

$report = @()
$subscriptions = Get-AzSubscription

foreach ($subscription in $subscriptions) {
        Set-AzContext -SubscriptionId $subscription.Id | Out-Null
        $subName = $subscription.Name
        $Zones = Get-AzPrivateDnsZone
        foreach ($zone in $Zones){ 
            $vnet_link = Get-AzPrivateDnsVirtualNetworkLink -ResourceGroupName $zone.ResourceGroupName -ZoneName $zone.Name
            $record_set = Get-AzPrivateDnsRecordSet -ResourceGroupName $zone.ResourceGroupName -ZoneName $zone.Name
            foreach ($record in $record_set){
                $info = "" | Select Subscription, ResourceGroupName, PrivateDNSZoneName, RecordSet, RecordType, Records, Ttl, IsAutoRegistered, VnetLinkName, VnetLinkId, RegistrationEnabled, VirtualNetworkLinkState, ProvisioningState

                $info.Subscription = $subName
                $info.ResourceGroupName = $zone.ResourceGroupName
                #$info.Location = $zone.Location
                $info.PrivateDNSZoneName = $zone.Name

                $info.RecordSet = $record.Name
                $info.RecordType = $record.RecordType
                if ($record.RecordType -eq 'A'){
                    $info.Records = $record.Records.Ipv4Address -join ","
                }
                elseif ($record.RecordType -eq 'CNAME'){
                    $info.Records = $record.Records.Cname -join ","
                }
                elseif ($record.RecordType -eq 'SOA') {
                    $info.Records = $record.Records.Host -join ","
                }
                else{
                    $info.Records = $record.Records
                }
                $info.Ttl = $record.Ttl
                $info.IsAutoRegistered = $record.IsAutoRegistered

                if ($vnet_link.Count -gt 0) {
                    $link = $vnet_link[0]
                    $info.VnetLinkName = $link.Name 
                    $info.VnetLinkId = $link.VirtualNetworkId
                    $info.RegistrationEnabled = $link.RegistrationEnabled
                    $info.VirtualNetworkLinkState = $link.VirtualNetworkLinkState
                    $info.ProvisioningState = $link.ProvisioningState
                }
                $report += $info 
            }
        }
        # $report | ft Subscription, ResourceGroupName, PrivateDNSZoneName, RecordSet, RecordType, Records, Ttl, IsAutoRegistered, VnetLinkName, VnetLinkId, RegistrationEnabled, VirtualNetworkLinkState, ProvisioningState
    }
# Eliminate duplicate records before export
$report = $report | Sort-Object -Property PrivateDNSZoneName, RecordSet, RecordType -Unique
$report | Export-CSV "$reportName1" -Encoding Default -NoTypeInformation

# Process A records and do a DNS lookup to verify
#
$desiredColumns = 'PrivateDNSZoneName','RecordSet','RecordType','Records',@{Name="FQDN";Expression={$_.RecordSet+"."+$_.PrivateDNSZoneName}}

# Select Enpoint A records
$DNSrecords = Import-Csv "$reportName1" | Where-Object -FilterScript {$_.RecordType -EQ 'A'}  | Select-Object $desiredColumns `
| Sort-Object -Property PrivateDNSZoneName,FQDN | Group-Object -Property FQDN | ForEach-Object { $_.Group[0] } 

# For each A record verify DNS lookup to verify
$report2 = @()
foreach ($DNSrecord in $DNSrecords){ 
    $info = "" | Select Status, PrivateDNSZoneName, Records, FQDN, DNSRecords, Description 

    # Initialize with existing values in the Record
    $info.PrivateDNSZoneName = $DNSrecord.PrivateDNSZoneName

    $info.Records = $DNSrecord.Records
    $info.FQDN=$DNSrecord.FQDN

    if ($DNSrecord.RecordType -eq 'A'){
        $temp=$DNSrecord.FQDN

        #For Windows only
        $temp=Resolve-DnsName $info.FQDN -Type A
        $dnslookup=$temp.IPAddress
        
        #For Linux only
        #$dnsLookup = dig +short A $info.FQDN | Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}$' }
        
        if($dnsLookup -eq ""){
            #echo "MISSING: $($info.FQDN) : DNS doesn't show Private Endpoint Address, should be $($DNSrecord.Records)"
            $info.Status="MISSING"
            $info.DNSRecords=$($DNSrecord.Records)
            $info.Description="DNS doesn't show Private Endpoint Address"
        }
        else{
            if ($dnsLookup -eq $DNSrecord.Records){
                #echo "EXISTING $($info.FQDN) : DNS returns Existing Record"
                $info.Status="EXISTING"
                $info.DNSRecords=$($dnsLookup)
                $info.Description="DNS returns Existing Record"
            }
            else 
            {
                $info.Status="DIFFERENT"
            #    echo "DIFFERENT : $($info.FQDN) : DNS returns different than Private Endpoint Address, $($DNSrecord.Records) for Private Endpoint and $($dnsLookup) in DNS"
                #Write-Host "DIFFERENT : $($info.FQDN) :  " -ForegroundColor red -NoNewline
                #Write-Host "DNS returns different than Private Endpoint Address, $($DNSrecord.Records) for Private Endpoint and $($dnsLookup) in DNS"
                $info.DNSRecords=$($dnsLookup)
                $info.Description="DNS returns different than Private Endpoint Address, $($DNSrecord.Records) for Private Endpoint and $($dnsLookup) in DNS"
            }
        }
    }
    $report2 += $info 
}
#echo $report2
echo $report2 |  Format-Table
$report2 | Export-CSV "$reportName2" -Encoding Default
