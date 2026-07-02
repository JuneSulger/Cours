#-----------------------------------
# SRV-FILE01 — Serveur de fichiers + DFS
# Domaine : orion.local
#-----------------------------------


# ── Création de la VM (depuis l'hôte Hyper-V) ──────────────────────────────

cd C:\VM\LABOPS2
md SRV-FILE01
cd .\SRV-FILE01\

New-VHD -Path .\SRV-FILE01-DISK1.vhdx -SizeBytes 127GB -Dynamic
New-VHD -Path .\SRV-FILE01-DISK1-DIFF.vhdx -ParentPath "C:\PARENT\TEST-SYSPREP2.vhdx" -Differencing

New-VM -Name "SRV-FILE01" -Generation 2 -MemoryStartupBytes 8GB -VHDPath .\SRV-FILE01-DISK1-DIFF.vhdx -Path .\ -SwitchName "LABOPS"
Set-VMMemory    -VMName SRV-FILE01 -DynamicMemoryEnabled $false
Set-VMProcessor -VMName SRV-FILE01 -Count 2

Start-VM -Name SRV-FILE01
Get-VM
vmconnect.exe localhost SRV-FILE01


# ── Configuration réseau (dans la VM) ──────────────────────────────────────

New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 172.16.50.20 -PrefixLength 24 -DefaultGateway 172.16.50.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 172.16.50.10,172.16.50.11
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6

Rename-Computer -NewName SRV-FILE01 -Force -Restart

# Jonction au domaine
Add-Computer -DomainName "orion.local" -Restart
# Alternative si la commande échoue :
# netdom join SRV-FILE01 /domain:orion.local /userd:ORION\Administrator /Passwordd:*


# ── Partages et arborescence de dossiers ───────────────────────────────────

New-Item -Path "D:\DEPARTMENTS\Accounting"   -ItemType Directory
New-Item -Path "D:\DEPARTMENTS\Development"  -ItemType Directory
New-Item -Path "D:\DEPARTMENTS\Management"   -ItemType Directory
New-Item -Path "D:\DEPARTMENTS\Public"       -ItemType Directory
Get-ChildItem -Path D:\DEPARTMENTS\

New-SmbShare -Name "DEPARTMENTS" -Path "D:\DEPARTMENTS" -ChangeAccess "ORION\Domain Users"


# ── Permissions NTFS ───────────────────────────────────────────────────────

icacls "D:\DEPARTMENTS\Management\" /grant "ORION\MGMT-GRP:(OI)(CI)M"
icacls.exe "D:\DEPARTMENTS\Management\"

# Désactivation de l'héritage et suppression des droits par défaut
icacls.exe "D:\DEPARTMENTS\Management\Accounting"   /inheritance:d
icacls.exe "D:\DEPARTMENTS\Management\Accounting"   /remove "BUILTIN Users"
icacls.exe "D:\DEPARTMENTS\Management\Management"   /inheritance:d
icacls.exe "D:\DEPARTMENTS\Management\Management"   /remove "BUILTIN Users"
icacls.exe "D:\DEPARTMENTS\Management\Development"  /inheritance:d
icacls.exe "D:\DEPARTMENTS\Management\Development"  /remove "BUILTIN Users"
icacls.exe "D:\DEPARTMENTS\Management\Public"       /inheritance:d
icacls.exe "D:\DEPARTMENTS\Management\Public"       /remove "BUILTIN Users"

# Pour retirer des droits :
# icacls "D:\DEPARTMENTS\Management\" /remove "NT AUTHORITY\Authentificated Users"


# ── Namespace DFS ──────────────────────────────────────────────────────────

Install-WindowsFeature FS-DFS-Namespace -IncludeManagementTools

New-Item -Path "D:\DFSRoot\share$" -ItemType Directory
New-SmbShare -Name "Share$" -Path "D:\DFSRoot\Share$\" -FullAccess "ORION\Domain Admins" -ChangeAccess "ORION\Domain Users"

New-DfsnRoot   -Path "\\orion.local\shares"             -TargetPath "\\SRV-FILE01\Share$"              -Type DomainV2
New-DfsnFolder -Path "\\orion.local\shares\Public"      -TargetPath "\\SRV-FILE01\DEPARTMENTS\PUBLIC"
New-DfsnFolder -Path "\\orion.local\shares\Accounting"  -TargetPath "\\SRV-FILE01\DEPARTMENTS\Accounting"
New-DfsnFolder -Path "\\orion.local\shares\Development" -TargetPath "\\SRV-FILE01\DEPARTMENTS\Development"
New-DfsnFolder -Path "\\orion.local\shares\Management"  -TargetPath "\\SRV-FILE01\DEPARTMENTS\Management"
