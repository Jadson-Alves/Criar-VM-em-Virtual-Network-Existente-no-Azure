# Esse script cria uma VM e adiciona em uma virtual network existente

# Definindo as variáveis de rede
$ResourceGroup  = "RG-VM-01"                        # Variavel com o nome do grupo de recursos  
$ResourceGroupvnet = "RG-FW"                        # Variavel com o nome do grupo de recursos onde a rede virtual está
$Location       = "EastUS"                          # Variavel com o nome do grupo de recursos
$vNetName       = "Vnet-Servidores"                 # Variavel com o nome da rede virtual
$SubnetName     = "subnet-Servidores"               # Variavel com o nome da sub-rede
$nsgName        = "nsg-Vnet-Servidores"             # Variavel com o nome do grupo de segurança de rede
$adminUsername  = 'jadson.alves'                    # Variavel com o nome do administardor da máquina            
$adminPassword  = 'Pa$$w0rd.qwe1234'                # Variavel com a senha do usuário adiministrador da máquina         
$vmName 	    = "VM-01"                           # Variavel com o nome da máquina virtual

                      
# Criar o Resource Group
New-AzResourceGroup -name $ResourceGroup -Location $Location

# Criando o Network Security Group
$nsgRuleVMAccess = New-AzNetworkSecurityRuleConfig -Name 'allow-vm-access' -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389,443,80 -Access Allow
New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroup -Location $location -Name $nsgName -SecurityRules $nsgRuleVMAccess

# Definindo as variáveis da máquina virtual
$vNet       = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupvnet -Name $vNetName
$Subnet     = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $vNet
$nsg        = Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroup -Name $NsgName
$pubName	= "MicrosoftWindowsServer"
$offerName	= "WindowsServer"
$skuName	= "2016-Datacenter"
$vmSize 	= "Standard_DS2_v2"
$pipName    = "$vmName-pip" 
$nicName    = "$vmName-nic"
$osDiskName = "$vmName-OsDisk"
$osDiskType = "Standard_LRS"

# Definindo as credenciais de administrador
$pw = ConvertTo-SecureString $adminPassword -AsPlainText -Force
$adminCreds  = New-Object System.Management.Automation.PSCredential ("$adminUsername", $pw)

# Criando IP público e interface de rede NIC
$pip = New-AzPublicIpAddress -Name $pipName -ResourceGroupName $ResourceGroup -Location $location -AllocationMethod Static 
$nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $ResourceGroup -Location $location -SubnetId $Subnet.Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

# Adicionando as configurações da máquina virtual
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize
Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id

# Setando os parâmetros do sistema operacional 
Set-AzVMOperatingSystem -VM $vmConfig -Windows -ComputerName $vmName -Credential $adminCreds

# Setando a imagem utilizada na máquina virtual
Set-AzVMSourceImage -VM $vmConfig -PublisherName $pubName -Offer $offerName -Skus $skuName -Version 'latest'

# Setando as configurações de disco
Set-AzVMOSDisk -VM $vmConfig -Name $osDiskName -StorageAccountType $osDiskType -CreateOption fromImage

# Desabilitando o diagnóstico de boot
Set-AzVMBootDiagnostic -VM $vmConfig -Disable
# Criando a máquina virtual
New-AzVM -ResourceGroupName $ResourceGroup -Location $location -VM $vmConfig

