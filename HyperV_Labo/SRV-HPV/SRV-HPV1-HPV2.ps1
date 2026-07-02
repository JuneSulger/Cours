#-----------------------------------
# SRV-HPV1 & SRV-HPV2 — Serveurs Hyper-V imbriqués
# Domaine : orion.local
# Note : SLAT activé pour la virtualisation imbriquée
#-----------------------------------


# ══════════════════════════════════════════════════════
# SRV-HPV1
# ══════════════════════════════════════════════════════

# ── Création de la VM (depuis l'hôte Hyper-V) ─────────

cd C:\VM\LABOPS2
md SRV-HPV1
cd .\SRV-HPV1\

New-VHD -Path .\SRV-HPV1-DISK1.vhdx -SizeBytes 127GB -Dynamic
New-VHD -Path .\SRV-HPV1-DISK1-DIFF.vhdx -ParentPath "C:\PARENT\TEST-SYSPREP2.vhdx" -Differencing

New-VM -Name "SRV-HPV1" -Generation 2 -MemoryStartupBytes 8GB -VHDPath .\SRV-HPV1-DISK1-DIFF.vhdx -Path .\ -SwitchName "LABOPS"
Set-VMMemory    -VMName SRV-HPV1 -DynamicMemoryEnabled $false
Set-VMProcessor -VMName SRV-HPV1 -Count 2

Start-VM -Name SRV-HPV1
vmconnect.exe localhost "SRV-HPV1"

# ── Configuration réseau (dans la VM) ─────────────────

New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 172.16.50.30 -PrefixLength 24 -DefaultGateway 172.16.50.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 172.16.50.10
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6

Rename-Computer -NewName SRV-HPV1 -Force -Restart
Add-Computer -DomainName "orion.local" -Restart


# ══════════════════════════════════════════════════════
# SRV-HPV2
# ══════════════════════════════════════════════════════

# ── Création de la VM (depuis l'hôte Hyper-V) ─────────

cd C:\VM\LABOPS2
md SRV-HPV2
cd .\SRV-HPV2\

New-VHD -Path .\SRV-HPV2-DISK1.vhdx -SizeBytes 127GB -Dynamic
New-VHD -Path .\SRV-HPV2-DISK1-DIFF.vhdx -ParentPath "C:\PARENT\TEST-SYSPREP2.vhdx" -Differencing

New-VM -Name "SRV-HPV2" -Generation 2 -MemoryStartupBytes 8GB -VHDPath .\SRV-HPV2-DISK1-DIFF.vhdx -Path .\ -SwitchName "LABOPS"
Set-VMMemory    -VMName SRV-HPV2 -DynamicMemoryEnabled $false
Set-VMProcessor -VMName SRV-HPV2 -Count 2

Start-VM -Name SRV-HPV2
vmconnect.exe localhost "SRV-HPV2"

# ── Configuration réseau (dans la VM) ─────────────────

New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 172.16.50.31 -PrefixLength 24 -DefaultGateway 172.16.50.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 172.16.50.10
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6

Rename-Computer -NewName SRV-HPV2 -Force -Restart
Add-Computer -DomainName "orion.local" -Restart


# ══════════════════════════════════════════════════════
# Activation SLAT — virtualisation imbriquée (depuis l'hôte)
# ══════════════════════════════════════════════════════

Set-VMProcessor -VMName "SRV-HPV1" -ExposeVirtualizationExtensions $true
Set-VMProcessor -VMName "SRV-HPV2" -ExposeVirtualizationExtensions $true

# Activation du rôle Hyper-V dans les VMs
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
