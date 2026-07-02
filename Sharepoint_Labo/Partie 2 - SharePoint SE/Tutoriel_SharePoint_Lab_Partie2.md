# Tutoriel — Mise en place d'un lab SharePoint Server (Partie 2 : SharePoint SE)


## Table des matières

- [Phase 8 — Prérequis SharePoint SE (via le splash de l'ISO)](#phase-8--prérequis-sharepoint-se-via-le-splash-de-liso)
  - [Montage de l'ISO (depuis l'hôte Hyper-V)](#montage-de-liso-depuis-lhôte-hyper-v)
  - [Lancement des prérequis](#lancement-des-prérequis)
  - [⚠️ Piège rencontré — features manquantes](#piège-rencontré--features-manquantes)
- [Phase 9 — Installation de SharePoint Server SE](#phase-9--installation-de-sharepoint-server-se)
  - [Récupération de la clé produit (Enterprise Trial)](#récupération-de-la-clé-produit-enterprise-trial)
  - [Lancement de l'installation (depuis le splash de l'ISO)](#lancement-de-linstallation-depuis-le-splash-de-liso)
  - [⚠️ Piège rencontré #1 — Échec silencieux ("encountered an error during setup")](#piège-rencontré-1--échec-silencieux-encountered-an-error-during-setup)
  - [⚠️ Piège rencontré #2 — Échec sur la VM SRV-SP spécifiquement](#piège-rencontré-2--échec-sur-la-vm-srv-sp-spécifiquement)
  - [Fin de l'installation](#fin-de-linstallation)
- [Phase 10 — Création de la ferme SharePoint (Configuration Wizard)](#phase-10--création-de-la-ferme-sharepoint-configuration-wizard)
  - [1. Écran de bienvenue](#1-écran-de-bienvenue)
  - [2. Connect to a server farm](#2-connect-to-a-server-farm)
  - [3. Specify Configuration Database Settings](#3-specify-configuration-database-settings)
  - [4. Specify Farm Security Settings](#4-specify-farm-security-settings)
  - [5. Configure SharePoint Central Administration Web Application](#5-configure-sharepoint-central-administration-web-application)
  - [6. Completing the Configuration Wizard](#6-completing-the-configuration-wizard)
- [✅ Récapitulatif de l'exercice complet](#récapitulatif-de-lexercice-complet)
- [📋 Pièges rencontrés — résumé pour référence future](#pièges-rencontrés--résumé-pour-référence-future)

*Suite directe de la Partie 1 (AD DS + GMSA + SQL Server). À ce stade : domaine `Sharepoint.lan` opérationnel, SRV-SQL avec instance `SHAREPOINT` installée, GMSA_SQL fonctionnel.*

---

## Phase 8 — Prérequis SharePoint SE (via le splash de l'ISO)

Plutôt que d'installer les rôles Windows un par un en PowerShell (`Install-WindowsFeature`), on utilise le **splash screen** de l'ISO SharePoint SE, qui gère tout automatiquement.

### Montage de l'ISO (depuis l'hôte Hyper-V)

```powershell
Add-VMDvdDrive -VMName "SRV_SP" -Path "C:\ISO\<iso_sharepoint_se>.iso"
```

### Lancement des prérequis

Dans la VM, ouvrir le lecteur DVD → si le splash ne se lance pas automatiquement, double-cliquer sur `splash.hta` ou `default.hta`, puis :

**"Install software prerequisites"**

L'assistant installe automatiquement :
- Rôles Windows (IIS, WAS, etc.)
- .NET Framework / WIF
- Visual C++ Redistributables
- Composants tiers additionnels

Redémarrages possibles en cours de route — relancer le splash après chaque redémarrage si demandé.

### ⚠️ Piège rencontré — features manquantes

Une vérification via :
```powershell
Get-WindowsFeature Web-Server, Windows-Identity-Foundation, RSAT-ADDS, Web-Asp-Net45, NET-Framework-45-Features |
  Select-Object Name, InstallState | Format-Table -AutoSize
```
a révélé que les rôles Windows (IIS, WIF, RSAT-ADDS...) n'étaient **pas encore installés** malgré une tentative précédente — la commande `Install-WindowsFeature` avait échoué avec `CommandNotFoundException` (module ServerManager non chargé, probablement dû à une session PowerShell 7 au lieu de Windows PowerShell 5.1).

**Solution retenue** : utiliser le splash de l'ISO SharePoint plutôt que PowerShell — il gère l'installation des rôles nécessaires de façon fiable sans dépendre du module ServerManager en ligne de commande.

---

## Phase 9 — Installation de SharePoint Server SE

### Récupération de la clé produit (Enterprise Trial)

Recherche **"Download SharePoint SE"** sur le site Microsoft → section *install instructions* → récupérer la clé produit **Enterprise Trial**.

### Lancement de l'installation (depuis le splash de l'ISO)

**"Install SharePoint Server"**

1. **Enter Your Product Key** : coller la clé Enterprise Trial → **Next**
2. **License Terms** : accepter → **Continue**
3. **Choose the installation you want** : sélectionner **"Complete"** (pas "Standalone" — nécessaire pour créer une ferme)
4. **File Location** : laisser les chemins par défaut
5. **Install Now**

### ⚠️ Piège rencontré #1 — Échec silencieux ("encountered an error during setup")

Premier échec avec un message générique sans détail. Investigation via les logs :
```powershell
$log = Get-ChildItem "$env:TEMP\SharePoint Server Setup*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Select-String -Path $log.FullName -Pattern "Error", "Failed" | Select-Object -Last 20
```

Le log a révélé l'échec précis :
```
CustomAction ArpWrite returned actual error code 1603
Action ended: ArpWrite. Return value 3.
```

**Cause identifiée** : la custom action `ArpWrite` (écriture de l'entrée Ajout/Suppression de programmes) échouait à écrire dans :
```
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Office16.OSERVER
```
Le compte utilisé pour lancer le setup n'avait pas les droits suffisants sur cette clé de registre — **le setup n'avait pas été lancé avec un compte Administrateur du domaine**, ou pas en élévation complète.

**Solution** : relancer `setup.exe` en étant connecté avec un compte **Administrateur du domaine**, en session élevée. Confirmé par le changement de chemin utilisateur dans les logs suivants (`ADMINI~1.SHA` au lieu de `TECHNI~1`).

### ⚠️ Piège rencontré #2 — Échec sur la VM SRV-SP spécifiquement

Après correction du problème de droits, l'installation échouait encore sur **SRV-SP**, mais fonctionnait sur **SRV-DC**. La cause exacte liée à cette VM n'a pas été investiguée plus loin (possible corruption locale, résidu d'une install précédente, ou particularité de l'image système de cette VM).

**Décision (validée par le formateur)** : terminer le lab en installant SharePoint SE directement sur **SRV-DC**, à titre exceptionnel pour la finalité pédagogique de l'exercice.

> ⚠️ **Rappel important** : installer SharePoint sur un contrôleur de domaine n'est **pas une pratique recommandée en production**. Raisons :
> - Un DC compromis via une faille SharePoint expose tout l'annuaire AD.
> - Les comptes de service SharePoint (pools d'applications IIS, comptes de ferme) ont un comportement différent sur un DC à cause des stratégies de sécurité propres aux contrôleurs de domaine.
> - Microsoft déconseille formellement de mélanger rôle DC et rôle applicatif (SQL, SharePoint, IIS) sur la même machine.
>
> Ce choix reste pertinent uniquement dans un contexte de lab isolé et pédagogique.

### Fin de l'installation

Une fois l'installation réussie (retour de code `1641 = ERROR_SUCCESS_REBOOT_INITIATED`, qui est un **succès**, pas une erreur), le setup demande un redémarrage :
```
Message: 'In order to complete setup, a system reboot is necessary. Would you like to reboot now?'
```
→ Accepter le redémarrage. L'**Assistant de configuration des produits SharePoint** (SharePoint Products Configuration Wizard) se relance automatiquement après redémarrage.

Vérification post-installation :
```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Office16.OSERVER" -ErrorAction SilentlyContinue
```
Doit renvoyer les informations du produit (`DisplayName = Microsoft SharePoint Server Subscription Edition`).

---

## Phase 10 — Création de la ferme SharePoint (Configuration Wizard)

### 1. Écran de bienvenue
**Next** → accepter l'avertissement d'arrêt de services (IIS, etc.) → **Yes**

### 2. Connect to a server farm
Sélectionner **"Create a new server farm"** → **Next**

### 3. Specify Configuration Database Settings
| Champ | Valeur |
|---|---|
| Database server | `SRV-SQL\SHAREPOINT` |
| Database name | valeur par défaut (`SharePoint_Config`) |
| Username | compte de domaine dédié à l'accès base de la ferme (`Sharepoint\NomDuCompte`) |
| Password | mot de passe de ce compte |

> Ce compte est distinct du GMSA_SQL — c'est un compte de domaine classique utilisé par SharePoint pour accéder à sa base de configuration.

### 4. Specify Farm Security Settings
- **Passphrase** : phrase de passe robuste, à noter précieusement (nécessaire pour ajouter d'autres serveurs à la ferme ultérieurement)

### 5. Configure SharePoint Central Administration Web Application
| Paramètre | Valeur |
|---|---|
| Port number | **8286** *(spécifié manuellement, cocher "Specify port number")* |
| Authentication provider | **NTLM** |

### 6. Completing the Configuration Wizard
Vérifier le résumé (port 8286, NTLM, base `SRV-SQL\SHAREPOINT`) → **Next** pour lancer la création de la ferme.

L'assistant exécute alors plusieurs étapes automatiques : création de la base de configuration, du site d'administration centrale, enregistrement des services, etc.

---

## ✅ Récapitulatif de l'exercice complet

- [x] 3 VMs Hyper-V (Gen 2), réseau `SHAREPOINT`
- [x] Domaine `Sharepoint.lan`, DC opérationnel
- [x] SQL Server 2022 (instance `SHAREPOINT`) avec GMSA_SQL, collation `Latin1_General_CI_AS_KS_WS`, disques dédiés Data/Log/TempDB
- [x] Prérequis SharePoint SE installés (via splash ISO)
- [x] SharePoint Server SE installé (sur SRV-DC, exception validée pour ce lab)
- [x] Nouvelle ferme SharePoint créée, connectée à `SRV-SQL\SHAREPOINT`
- [x] Site d'administration centrale configuré sur le port **8286**
- [x] Authentification **NTLM**

## 📋 Pièges rencontrés — résumé pour référence future

| Symptôme | Cause | Solution |
|---|---|---|
| `Add-KdsRootKey` : erreur 0x80070032 | Console non élevée / compte non Domain Admin | Relancer en admin + Domain Admin |
| `Install-ADServiceAccount` : "unspecified error" | Jeton Kerberos périmé après ajout au groupe | Redémarrer le serveur |
| `Add-VMHardDiskDrive` échoue | Fichier `.vhdx` pas encore créé au moment de l'attacher | Vérifier avec `Test-Path` avant de retenter |
| Setup SharePoint : erreur générique | `ArpWrite` échoue (droits registre insuffisants) | Relancer avec compte Administrateur du domaine |
| Setup SharePoint échoue sur une VM spécifique | Cause non identifiée, propre à cette VM | Basculer sur une autre machine (ici le DC, en exception) |

---

Le lab est maintenant complet : infrastructure AD + SQL Server + ferme SharePoint SE opérationnelle avec administration centrale accessible sur le port 8286 en authentification NTLM.
