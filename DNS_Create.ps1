$DNS_Create_List = 'DB-ADM-ADMDEV-Test','DB-BRC-DialerDM-Test','DB-BRC-LSDM-Test','DB-BRC-PortfolioReporting-Test','DB-RTL-LeadStrategy-Test','DB-RTL-RetailReporting-Test','DB-RTL-RiskManagement-Test','DB-TLS-SystemControl-Test'

    $DNS_Create_List | ForEach-Object {    
        Add-DnsServerResourceRecordA -Name $_ -ZoneName "coexist.local" -AllowUpdateAny -IPv4Address "10.128.180.84" -TimeToLive 01:00:00 -ComputerName "SP-DC-04"
        #Rollback
        #Add-DnsServerResourceRecordA -Name $_ -ZoneName "coexist.local" -AllowUpdateAny -IPv4Address "10.10.0.123" -TimeToLive 01:00:00 -ComputerName "SP-DC-04"
    }