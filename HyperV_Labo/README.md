# LAB_WS — Labo Windows Server en PowerShell

Scripts PowerShell réalisés dans le cadre de ma formation en administration systèmes & réseaux chez Technocité.

Ce labo déploie une infrastructure Windows Server complète sous Hyper-V, avec Active Directory, serveur de fichiers et virtualisation imbriquée.

---

## Architecture

```
Réseau : 172.16.50.0/24 — Commutateur privé LABOPS (Hyper-V)

SRV-AD01    172.16.50.10   Contrôleur de domaine principal (orion.local)
SRV-AD02    172.16.50.11   Contrôleur de domaine secondaire
SRV-FILE01  172.16.50.20   Serveur de fichiers + DFS Namespace
SRV-HPV1    172.16.50.30   Serveur Hyper-V imbriqué
SRV-HPV2    172.16.50.31   Serveur Hyper-V imbriqué
```

---

## Contenu

| Dossier | Description |
|---|---|
| `SRV-AD01/` | Création VM, config réseau, installation AD DS + DNS, OUs, groupes, utilisateurs, backup IFM |
| `SRV-AD02/` | Création VM, promotion en DC secondaire via IFM |
| `SRV-FILE01/` | Création VM, partages SMB, permissions NTFS, DFS Namespace |
| `SRV-HPV/` | Création VMs HPV1 & HPV2, activation SLAT pour virtualisation imbriquée |

---

## Technologies utilisées

- Windows Server 2019
- Hyper-V (virtualisation imbriquée)
- Active Directory Domain Services
- DNS
- DFS Namespace
- SMB / NTFS
- PowerShell

---

*Formation : Administrateur système & réseau orienté virtualisation — Technocité 2026*
