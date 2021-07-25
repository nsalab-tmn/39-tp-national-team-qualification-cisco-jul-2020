param (
    $RGPrefix,
    $vmPrefix,
    $location,
    $vmSize,
    $CData
    )
$random = $(Get-Random)
$resourceGroup = "$RGPrefix-$random"
$vmName = "$vmPrefix-$random"

# Definer user name and blank password
$securePassword = ConvertTo-SecureString 'TBIczH2ax8UrvHD7KHQP' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("nsaadmin", $securePassword)

New-AzResourceGroup -Name $resourceGroup -Location $location

# Create a subnet configuration
$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name Subnet-$random -AddressPrefix 10.0.0.0/24

# Create a virtual network
$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroup -Location $location -Name "$vmPrefix-vNET-$random" -AddressPrefix 10.0.0.0/16 -Subnet $subnetConfig

# Create a public IP address and specify a DNS name
$pip = New-AzPublicIpAddress -ResourceGroupName $resourceGroup -Location $location -Name "$vmPrefix-PUB-$random" -AllocationMethod Dynamic -IdleTimeoutInMinutes 4

# Create an inbound network security group rule for port 3389
$nsgRuleAllHTTP = New-AzNetworkSecurityRuleConfig -Name Permit_HTTP  -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80 -Access Allow
$nsgRuleAllSSH = New-AzNetworkSecurityRuleConfig -Name Permit_SSH  -Protocol Tcp -Direction Inbound -Priority 1002 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow
$nsgRuleAllICMP = New-AzNetworkSecurityRuleConfig -Name Permit_icmp  -Protocol Icmp -Direction Inbound -Priority 1010 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange * -Access Allow
# Create a network security group
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location -Name "$vmPrefix-NSG-$random" -SecurityRules $nsgRuleAllHTTP,$nsgRuleAllSSH,$nsgRuleAllICMP

# Create a virtual network card and associate with public IP address and NSG
$nic = New-AzNetworkInterface -Name "$vmPrefix-NIC-$random" -ResourceGroupName $resourceGroup -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

# Create a virtual machine configuration
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize | Set-AzVMOperatingSystem -Linux -ComputerName $vmName -Credential $cred -CustomData $CData | Set-AzVMSourceImage -PublisherName Canonical -Offer UbuntuServer -Skus 16.04-LTS -Version latest | Add-AzVMNetworkInterface -Id $nic.Id

# Create a virtual machine
New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig