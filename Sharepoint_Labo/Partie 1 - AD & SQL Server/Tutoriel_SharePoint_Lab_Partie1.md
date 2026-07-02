# Tutoriel — Mise en place d'un lab SharePoint Server (Partie 1 : AD + SQL Server)


## Table des matières

- [Objectif](#objectif)
- [Phase 1 — Création de l'arborescence et des VMs (sur l'hôte Hyper-V)](#phase-1--création-de-larborescence-et-des-vms-sur-lhôte-hyper-v)
  - [SRV_DC (installation propre depuis l'ISO)](#srv_dc-installation-propre-depuis-liso)
  - [SRV_SP et SRV_SQL (disques différenciés depuis un parent sysprepé)](#srv_sp-et-srv_sql-disques-différenciés-depuis-un-parent-sysprepé)
- [Phase 2 — Configuration réseau et promotion du DC (dans SRV-DC)](#phase-2--configuration-réseau-et-promotion-du-dc-dans-srv-dc)
  - [Promotion en contrôleur de domaine](#promotion-en-contrôleur-de-domaine)
  - [Création d'un compte technicien (Admin du domaine)](#création-dun-compte-technicien-admin-du-domaine)
- [Phase 3 — Clé racine KDS (prérequis pour les GMSA)](#phase-3--clé-racine-kds-prérequis-pour-les-gmsa)
- [Phase 4 — Création du compte de service géré (GMSA_SQL)](#phase-4--création-du-compte-de-service-géré-gmsa_sql)
  - [1. Créer le groupe de sécurité qui aura le droit d'utiliser le GMSA](#1-créer-le-groupe-de-sécurité-qui-aura-le-droit-dutiliser-le-gmsa)
  - [2. Ajouter le compte ordinateur du futur serveur SQL au groupe](#2-ajouter-le-compte-ordinateur-du-futur-serveur-sql-au-groupe)
  - [3. Créer le compte de service géré](#3-créer-le-compte-de-service-géré)
  - [4. Installer le GMSA sur SRV-SQL (depuis SRV-SQL)](#4-installer-le-gmsa-sur-srv-sql-depuis-srv-sql)
  - [🔧 Dépannage rencontré](#dépannage-rencontré)
- [Phase 5 — Configuration réseau et jonction au domaine (SRV-SP et SRV-SQL)](#phase-5--configuration-réseau-et-jonction-au-domaine-srv-sp-et-srv-sql)
  - [SRV-SP](#srv-sp)
  - [SRV-SQL](#srv-sql)
- [Phase 6 — Disques dédiés pour SQL Server (Data / Log / TempDB)](#phase-6--disques-dédiés-pour-sql-server-data--log--tempdb)
  - [Sur l'hôte Hyper-V — création et attachement des VHDX](#sur-lhôte-hyper-v--création-et-attachement-des-vhdx)
  - [Dans SRV-SQL — initialisation et formatage (Gestionnaire de disques ou PowerShell)](#dans-srv-sql--initialisation-et-formatage-gestionnaire-de-disques-ou-powershell)
- [Phase 7 — Installation de SQL Server 2022 (instance SHAREPOINT)](#phase-7--installation-de-sql-server-2022-instance-sharepoint)
- [✅ Où on en est](#où-on-en-est)
- [🔜 Prochaines étapes (suite de l'exercice)](#prochaines-étapes-suite-de-lexercice)

## Objectif

Mettre en place une infrastructure à 3 serveurs virtuels (Hyper-V) pour préparer une ferme SharePoint Server SE :
- **SRV-DC** : Contrôleur de domaine (AD DS + DNS)
- **SRV-SP** : futur serveur SharePoint
- **SRV-SQL** : serveur de base de données (SQL Server, instance nommée SHAREPOINT)

Domaine utilisé : `Sharepoint.lan`

---

## Phase 1 — Création de l'arborescence et des VMs (sur l'hôte Hyper-V)

```powershell
Set-Location C:\VM\
New-Item -ItemType Directory -Name SRV_SQLLab1
Set-Location .\SRV_SQLLab1\
New-Item -ItemType Directory -Name SRV_DC
New-Item -ItemType Directory -Name SRV_SP
New-Item -ItemType Directory -Name SRV_SQL
```

### SRV_DC (installation propre depuis l'ISO)

```powershell
Set-Location C:\VM\SRV_SQLLab1\SRV_DC
New-VHD -Path .\SRV_DC.vhdx -SizeBytes 100GB -Dynamic
New-VM -Name "SRV_DC" -Generation 2 -MemoryStartupBytes 4GB -VHDPath .\SRV_DC.vhdx -Path .\ -SwitchName "SHAREPOINT"
Set-VMMemory -VMName SRV_DC -DynamicMemoryEnabled $false
Set-VMProcessor -VMName SRV_DC -Count 2
Add-VMDvdDrive -VMName "SRV_DC" -Path "C:\ISO\en-us_windows_server_2025_updated_nov_2025_x64_dvd_2cfcca22.iso"
Start-VM -Name SRV_DC
vmconnect.exe localhost "SRV_DC"
```

### SRV_SP et SRV_SQL (disques différenciés depuis un parent sysprepé)

```powershell
Set-Location C:\VM\SRV_SQLLab1\SRV_SP
New-VHD -Path .\SRV_SP.vhdx -SizeBytes 127GB -Dynamic
New-VHD -Path .\SRV_SP-DISK1-DIFF.vhdx -ParentPath "C:\PARENT\TEST-SYSPREP2.vhdx" -Differencing
New-VM -Name "SRV_SP" -Generation 2 -MemoryStartupBytes 8GB -VHDPath .\SRV_SP-DISK1-DIFF.vhdx -Path .\ -SwitchName "SHAREPOINT"
Set-VMMemory -VMName SRV_SP -DynamicMemoryEnabled $false
Start-VM -Name SRV_SP
vmconnect.exe localhost "SRV_SP"
```

```powershell
Set-Location C:\VM\SRV_SQLLab1\SRV_SQL
New-VHD -Path .\SRV_SQL.vhdx -SizeBytes 127GB -Dynamic
New-VHD -Path .\SRV_SQL-DISK1-DIFF.vhdx -ParentPath "C:\PARENT\TEST-SYSPREP2.vhdx" -Differencing
New-VM -Name "SRV_SQL" -Generation 2 -MemoryStartupBytes 16GB -VHDPath .\SRV_SQL-DISK1-DIFF.vhdx -Path .\ -SwitchName "SHAREPOINT"
Set-VMMemory -VMName SRV_SQL -DynamicMemoryEnabled $false
Start-VM -Name SRV_SQL
vmconnect.exe localhost "SRV_SQL"
```

> 💡 Les 3 VMs sont en **Generation 2**, donc leurs disques (contrôleur SCSI) supportent l'ajout/retrait à chaud, sans besoin d'éteindre la VM.

---

## Phase 2 — Configuration réseau et promotion du DC (dans SRV-DC)

```powershell
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 172.16.0.8 -PrefixLength 24 -DefaultGateway 172.16.0.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 172.16.0.8
Rename-Computer -NewName "SRV-DC" -Force
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6
Set-TimeZone -Id "Romance Standard Time"
netsh.exe advfirewall set allprofiles state off
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Install-WindowsFeature -Name DNS -IncludeManagementTools
Restart-Computer
```

### Promotion en contrôleur de domaine

```powershell
Install-ADDSForest -DomainName "Sharepoint.lan" -DomainNetbiosName "Sharepoint" -InstallDns `
  -SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force) -Force
Restart-Computer
```

### Création d'un compte technicien (Admin du domaine)

```powershell
New-ADUser -Name "Technicien" -SamAccountName "Technicien" -UserPrincipalName "Technicien@Sharepoint.lan" `
  -AccountPassword (ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force) -Enabled $true
Add-ADGroupMember -Identity "Admins du Domaine" -Members "Technicien"
Restart-Computer
```

---

## Phase 3 — Clé racine KDS (prérequis pour les GMSA)

```powershell
Add-KdsRootKey -EffectiveTime ((Get-Date).AddHours(-10))
```

**⚠️ Piège rencontré** : erreur `0x80070032 - The request is not supported`.
Causes possibles : PowerShell non lancé en administrateur, compte non Domain Admin, ou niveau fonctionnel de forêt insuffisant. Une fois relancé correctement (admin + Domain Admin), la commande passe.

Le `-10h` sert à contourner artificiellement le délai normal de 10h de réplication du KDS entre contrôleurs de domaine — acceptable en lab avec un seul DC, à proscrire en production.

---

## Phase 4 — Création du compte de service géré (GMSA_SQL)

### 1. Créer le groupe de sécurité qui aura le droit d'utiliser le GMSA

```powershell
New-ADGroup -Name "GS_GMSA_SQL" -GroupScope Global -GroupCategory Security -Path "CN=Users,DC=Sharepoint,DC=lan"
```

### 2. Ajouter le compte ordinateur du futur serveur SQL au groupe

⚠️ Cette étape nécessite que la VM soit **déjà jointe au domaine** (compte ordinateur existant dans AD) :

```powershell
Add-ADGroupMember -Identity "GS_GMSA_SQL" -Members "SRV-SQL$"
```

### 3. Créer le compte de service géré

```powershell
New-ADServiceAccount GMSA_SQL -DNSHostName gmsa_sql.sharepoint.lan -PrincipalsAllowedToRetrieveManagedPassword GS_GMSA_SQL
```

### 4. Installer le GMSA sur SRV-SQL (depuis SRV-SQL)

```powershell
Install-WindowsFeature RSAT-AD-PowerShell
Install-ADServiceAccount -Identity GMSA_SQL
Test-ADServiceAccount -Identity GMSA_SQL   # doit renvoyer True
```

### 🔧 Dépannage rencontré

| Symptôme | Vérification | Solution |
|---|---|---|
| `Install-ADServiceAccount` : "unspecified error" | Membre du groupe présent ? | `Get-ADGroupMember -Identity "GS_GMSA_SQL"` |
| Idem | Horloge synchronisée ? | `w32tm /query /status` (écart < 5 min requis) |
| Idem | Chiffrement Kerberos supporté ? | `Get-ADComputer SRV-SQL -Properties msDS-SupportedEncryptionTypes` (valeur 28 = AES128+256, correct) |
| Idem | Jeton Kerberos périmé | **Redémarrer SRV-SQL** après l'ajout au groupe — résout la majorité des cas |
| `Test-ADServiceAccount` renvoie `False` | Canal sécurisé cassé ? | `Test-ComputerSecureChannel -Verbose` / réparation avec `-Repair` si besoin |

Dans notre cas, un redémarrage de SRV-SQL après l'ajout au groupe a résolu le blocage.

---

## Phase 5 — Configuration réseau et jonction au domaine (SRV-SP et SRV-SQL)

### SRV-SP

```powershell
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 172.16.0.9 -PrefixLength 24 -DefaultGateway 172.16.0.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 172.16.0.8
Rename-Computer -NewName "SRV-SP" -Force
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6
netsh.exe advfirewall set allprofiles state off
Set-TimeZone -Id "Romance Standard Time"
Restart-Computer

Add-Computer -DomainName "Sharepoint.lan" -Credential (Get-Credential)
Restart-Computer
```

Installation anticipée des prérequis IIS / .NET / WIF (préparation pour SharePoint, phase suivante) :

```powershell
Install-WindowsFeature Server-Media-Foundation, NET-Framework-45-Features, RPC-over-HTTP-proxy, `
  RSAT-Clustering, RSAT-Clustering-CmdInterface, RSAT-Clustering-Mgmt, RSAT-Clustering-PowerShell, `
  WAS-Process-Model, Web-Asp-Net45, Web-Basic-Auth, Web-Client-Auth, Web-Digest-Auth, Web-Dir-Browsing, `
  Web-Dyn-Compression, Web-Http-Errors, Web-Http-Logging, Web-Http-Redirect, Web-Http-Tracing, `
  Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Lgcy-Mgmt-Console, Web-Metabase, Web-Mgmt-Console, Web-Mgmt-Service, `
  Web-Net-Ext45, Web-Request-Monitor, Web-Server, Web-Stat-Compression, Web-Static-Content, Web-Windows-Auth, `
  Web-WMI, Windows-Identity-Foundation, RSAT-ADDS
```

### SRV-SQL

```powershell
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 172.16.0.10 -PrefixLength 24 -DefaultGateway 172.16.0.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 172.16.0.8
Rename-Computer -NewName "SRV-SQL" -Force
netsh.exe advfirewall set allprofiles state off
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6
Set-TimeZone -Id "Romance Standard Time"
Restart-Computer

Add-Computer -DomainName "Sharepoint.lan" -Credential (Get-Credential)
Restart-Computer
```

---

## Phase 6 — Disques dédiés pour SQL Server (Data / Log / TempDB)

### Sur l'hôte Hyper-V — création et attachement des VHDX

```powershell
New-VHD -Path "C:\VM\SRV_SQLLab1\SRV_SQL\SRV_SQL-DATA.vhdx" -SizeBytes 40GB -Dynamic
New-VHD -Path "C:\VM\SRV_SQLLab1\SRV_SQL\SRV_SQL-LOG.vhdx" -SizeBytes 20GB -Dynamic
New-VHD -Path "C:\VM\SRV_SQLLab1\SRV_SQL\SRV_SQL-TEMPDB.vhdx" -SizeBytes 20GB -Dynamic

Add-VMHardDiskDrive -VMName "SRV_SQL" -Path "C:\VM\SRV_SQLLab1\SRV_SQL\SRV_SQL-DATA.vhdx"
Add-VMHardDiskDrive -VMName "SRV_SQL" -Path "C:\VM\SRV_SQLLab1\SRV_SQL\SRV_SQL-LOG.vhdx"
Add-VMHardDiskDrive -VMName "SRV_SQL" -Path "C:\VM\SRV_SQLLab1\SRV_SQL\SRV_SQL-TEMPDB.vhdx"
```

Vérification de l'attachement :
```powershell
Get-VMHardDiskDrive -VMName "SRV_SQL" | Select-Object Path, ControllerType, ControllerNumber, ControllerLocation
```

> 💡 **Piège rencontré** : `Add-VMHardDiskDrive` a échoué la première fois car les fichiers `.vhdx` n'existaient pas encore réellement sur le disque à cet instant (`New-VHD` avait échoué silencieusement ou le fichier n'était pas encore visible). Vérifier avec `Test-Path` avant de retenter.

### Dans SRV-SQL — initialisation et formatage (Gestionnaire de disques ou PowerShell)

Via PowerShell :
```powershell
Initialize-Disk -Number 1 -PartitionStyle GPT
New-Partition -DiskNumber 1 -UseMaximumSize -DriveLetter D
Format-Volume -DriveLetter D -FileSystem NTFS -NewFileSystemLabel "SQLDATA" -Confirm:$false
```
*(répéter pour chaque disque : Log → lettre L, TempDB → lettre dédiée)*

Ou via `diskmgmt.msc` : mettre en ligne → initialiser en GPT → nouveau volume simple → lettre + NTFS.

Résultat de ce lab : **D:\ = Data**, **L:\ = Log**, disque TempDB également créé (attention à ne pas confondre avec un 4ᵉ disque "Backup" ajouté en supplément lors de l'installation SQL).

---

## Phase 7 — Installation de SQL Server 2022 (instance SHAREPOINT)

Depuis le **SQL Server Installation Center** :

1. **Installation** → *New SQL Server stand-alone installation*
2. **Product Key** / **License Terms** / **Microsoft Update** → suivant
3. **Azure Extension for SQL Server** → **décocher** (non nécessaire en lab local)
4. **Feature Selection** → cocher uniquement :
   - ☑ Database Engine Services
   - ☑ Full-Text and Semantic Extractions for Search
5. **Instance Configuration** → Named instance : **`SHAREPOINT`**
6. **Server Configuration** — onglet *Service Accounts* :
   - SQL Server Database Engine → compte `Sharepoint\GMSA_SQL$`, mot de passe **vide** (GMSA géré automatiquement), démarrage **Automatic**
7. **Server Configuration** — onglet *Collation* → *Customize* :
   - Collation designator : `Latin1_General`
   - ☐ Case-sensitive (décoché = **CI**)
   - ☑ Accent-sensitive (**AS**)
   - ☑ Kana-sensitive (**KS**)
   - ☑ Width-sensitive (**WS**)
   - → résultat : `Latin1_General_CI_AS_KS_WS`
8. **Database Engine Configuration** — onglet *Server Configuration* :
   - Authentication Mode : Windows authentication mode
   - Ajouter un administrateur SQL (*Add Current User*, ou le compte Technicien) — obligatoire, sinon erreur bloquante
9. **Database Engine Configuration** — onglet *Data Directories* :
   - Data root directory : `D:\`
   - User database log directory : `L:\`
   - TempDB : pointé vers le 3ᵉ disque dédié (onglet *TempDB*)
10. **Ready to Install** → **Install**

---

## ✅ Où on en est

- [x] 3 VMs créées (Gen 2, réseau SHAREPOINT)
- [x] Domaine `Sharepoint.lan` créé, DC opérationnel
- [x] SRV-SP et SRV-SQL joints au domaine
- [x] Clé KDS créée
- [x] GMSA_SQL créé, testé, fonctionnel
- [x] 3 disques dédiés créés sur SRV-SQL (Data / Log / TempDB)
- [x] Installation SQL Server 2022 (instance SHAREPOINT) lancée avec GMSA + collation + disques dédiés

## 🔜 Prochaines étapes (suite de l'exercice)

- Installer les **prérequis SharePoint SE** sur SRV-SP (`prerequisiteinstaller.exe`)
- Installer **SharePoint Server SE**
- Créer une **nouvelle ferme SharePoint**, en pointant vers `SRV-SQL\SHAREPOINT`
- Configurer le **site d'administration central** sur le port **6566**
- Définir l'authentification en **NTLM**
