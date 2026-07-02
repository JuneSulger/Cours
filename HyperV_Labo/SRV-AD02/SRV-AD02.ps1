#-----------------------------------
# SRV-AD02 — Contrôleur de domaine secondaire
# Domaine : orion.local
# Prérequis : IFM copié depuis SRV-AD01 (robocopy)
#-----------------------------------


# ── Création de la VM (depuis l'hôte Hyper-V) ──────────────────────────────

cd C:\VM\LABOPS2
md SRV-AD02
cd .\SRV-AD02\

New-VHD -Path .\SRV-AD02-DISK1.vhdx -SizeBytes 127GB -Dynamic
New-VHD -Path .\SRV-AD02-DISK1-DIFF.vhdx -ParentPath "C:\PARENT\TEST-SYSPREP2.vhdx" -Differencing

New-VM -Name "SRV-AD02" -Generation 2 -MemoryStartupBytes 8GB -VHDPath .\SRV-AD02-DISK1-DIFF.vhdx -Path .\ -SwitchName "LABOPS"
Set-VMMemory    -VMName SRV-AD02 -DynamicMemoryEnabled $false
Set-VMProcessor -VMName SRV-AD02 -Count 2

Start-VM -Name SRV-AD02
vmconnect.exe localhost "SRV-AD02"


# ── Configuration réseau (dans la VM) ──────────────────────────────────────

New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 172.16.50.11 -PrefixLength 24 -DefaultGateway 172.16.50.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 172.16.50.11
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6

Rename-Computer -NewName "SRV-AD02" -Restart


# ── Jonction au domaine et promotion en DC ─────────────────────────────────

Add-Computer -DomainName "orion.local" -Restart
Install-WindowsFeature AD-Domain-Services,DNS -IncludeManagementTools
Install-ADDSDomainController -DomainName "orion.local" -InstallationMediaPath "C:\IFM" -InstallDns
