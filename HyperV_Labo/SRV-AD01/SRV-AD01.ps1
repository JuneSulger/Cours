#-----------------------------------
# SRV-AD01 — Contrôleur de domaine principal
# Domaine : orion.local
#-----------------------------------


# ── Création de la VM (depuis l'hôte Hyper-V) ──────────────────────────────

New-VMSwitch -Name "LABOPS" -SwitchType Private        # Création du commutateur

cd C:\VM\LABOPS2
md SRV-AD01
cd .\SRV-AD01\

New-VHD -Path .\SRV-AD01-DISK1.vhdx -SizeBytes 127GB -Dynamic
New-VHD -Path .\SRV-AD01-DISK1-DIFF.vhdx -ParentPath "C:\PARENT\TEST-SYSPREP2.vhdx" -Differencing

New-VM -Name "SRV-AD01" -Generation 2 -MemoryStartupBytes 8GB -VHDPath .\SRV-AD01-DISK1-DIFF.vhdx -Path .\ -SwitchName "LABOPS"
Set-VMMemory   -VMName SRV-AD01 -DynamicMemoryEnabled $false
Set-VMProcessor -VMName SRV-AD01 -Count 2

Start-VM -Name SRV-AD01
vmconnect.exe localhost "SRV-AD01"


# ── Configuration réseau (dans la VM) ──────────────────────────────────────

New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 172.16.50.10 -PrefixLength 24 -DefaultGateway 172.16.50.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 172.16.50.10
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6

Rename-Computer -NewName "SRV-AD01" -Restart


# ── Installation AD DS + DNS ────────────────────────────────────────────────

Install-WindowsFeature AD-Domain-Services,DNS -IncludeManagementTools
Install-ADDSForest -DomainName "orion.local" -DomainNetbiosName "ORION" -InstallDns


# ── Structure Active Directory ──────────────────────────────────────────────

# Unités organisationnelles
New-ADOrganizationalUnit -Name "ORION-DPT"   -Path "DC=orion,DC=local"
New-ADOrganizationalUnit -Name "Management"  -Path "OU=ORION-DPT,DC=orion,DC=local"
New-ADOrganizationalUnit -Name "Developement"-Path "OU=ORION-DPT,DC=orion,DC=local"
New-ADOrganizationalUnit -Name "Accounting"  -Path "OU=ORION-DPT,DC=orion,DC=local"

# Groupes de sécurité
New-ADGroup -Name "MGMT-GRP" -GroupScope Global -GroupCategory Security -Path "OU=Management,OU=ORION-DPT,DC=orion,DC=local"
New-ADGroup -Name "DEV-GRP"  -GroupScope Global -GroupCategory Security -Path "OU=Developement,OU=ORION-DPT,DC=orion,DC=local"
New-ADGroup -Name "ACC-GRP"  -GroupScope Global -GroupCategory Security -Path "OU=Accounting,OU=ORION-DPT,DC=orion,DC=local"

# Utilisateurs
New-ADUser -Name "Sebastien Sotiaux"  -SamAccountName "sso" -UserPrincipalName "sso@orion.local" -Path "OU=Developement,OU=ORION-DPT,DC=orion,DC=local" -AccountPassword (Read-Host -AsSecureString "Mot de passe") -Enabled $true
Add-ADGroupMember -Identity "DEV-GRP"  -Members "sso"
Get-ADGroupMember -Identity "DEV-GRP"

New-ADUser -Name "Benjamin Delaunoy"  -SamAccountName "bde" -UserPrincipalName "bde@orion.local" -Path "OU=Accounting,OU=ORION-DPT,DC=orion,DC=local" -AccountPassword (Read-Host -AsSecureString "Mot de passe") -Enabled $true
Add-ADGroupMember -Identity "ACC-GRP"  -Members "bde"
Get-ADGroupMember -Identity "ACC-GRP"

New-ADUser -Name "Mathis Thomas"      -SamAccountName "mth" -UserPrincipalName "mth@orion.local" -Path "OU=Management,OU=ORION-DPT,DC=orion,DC=local" -AccountPassword (Read-Host -AsSecureString "Mot de passe") -Enabled $true
Add-ADGroupMember -Identity "MGMT-GRP" -Members "mth"
Get-ADGroupMember -Identity "MGMT-GRP"


# ── Backup IFM (pour promotion de SRV-AD02) ────────────────────────────────

cd C:\
md IFM
cd .\IFM\
ntdsutil "activate instance ntds" ifm "create sysvol full c:\IFM" quit quit

robocopy C:\IFM \\SRV-AD02\C$\IFM /E


# ── Carte réseau WAN (ajout depuis l'hôte) ────────────────────────────────

Add-VMNetworkAdapter -VMName "SRV-AD01" -SwitchName "WAN"
