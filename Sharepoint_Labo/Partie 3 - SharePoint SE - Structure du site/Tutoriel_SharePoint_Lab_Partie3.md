# Tutoriel — Mise en place d'un lab SharePoint Server (Partie 3 : Structure de sites, permissions et applications)


## Table des matières

- [Phase 11 — Préparation Active Directory : utilisateurs et groupes](#phase-11--préparation-active-directory--utilisateurs-et-groupes)
  - [Création des 3 groupes de sécurité](#création-des-3-groupes-de-sécurité)
  - [Création des utilisateurs](#création-des-utilisateurs)
  - [Répartition dans les groupes](#répartition-dans-les-groupes)
  - [Vérification](#vérification)
- [Phase 12 — Accès à l'administration SharePoint et assistant de configuration](#phase-12--accès-à-ladministration-sharepoint-et-assistant-de-configuration)
  - [Connexion](#connexion)
  - [Résolution DNS optionnelle pour utiliser "sharepoint" comme nom d'hôte](#résolution-dns-optionnelle-pour-utiliser-sharepoint-comme-nom-dhôte)
  - [Assistant de configuration de la ferme](#assistant-de-configuration-de-la-ferme)
- [Phase 13 — Arborescence des sites](#phase-13--arborescence-des-sites)
  - [Méthode générale de création d'un sous-site](#méthode-générale-de-création-dun-sous-site)
  - [Sous-site IT (sous Accueil)](#sous-site-it-sous-accueil)
  - [Sous-site Project (sous Accueil)](#sous-site-project-sous-accueil)
  - [Sous-site Wiki (sous Accueil)](#sous-site-wiki-sous-accueil)
  - [Sous-site Administration (sous Accueil)](#sous-site-administration-sous-accueil)
  - [Sous-sites IT/Client et IT/Internal (créés depuis le site IT, pas Accueil)](#sous-sites-itclient-et-itinternal-créés-depuis-le-site-it-pas-accueil)
- [Phase 14 — Applications par site](#phase-14--applications-par-site)
  - [Accueil](#accueil)
  - [IT](#it)
  - [IT/Client](#itclient)
  - [IT/Internal](#itinternal)
  - [Project](#project)
  - [Wiki](#wiki)
  - [Administration](#administration)
- [Phase 15 — Gestion des permissions au niveau liste/bibliothèque (rupture d'héritage)](#phase-15--gestion-des-permissions-au-niveau-listebibliothèque-rupture-dhéritage)
  - [Procédure](#procédure)
- [🔧 Pièges rencontrés et corrections](#pièges-rencontrés-et-corrections)
  - [Template "Project Site" oublié à la création](#template-project-site-oublié-à-la-création)
  - [Template "Wiki" introuvable dans les modèles de site](#template-wiki-introuvable-dans-les-modèles-de-site)
- [✅ Récapitulatif de l'exercice](#récapitulatif-de-lexercice)

*Suite directe de la Partie 2. À ce stade : ferme SharePoint SE opérationnelle, site d'administration centrale accessible sur le port 8286.*

---

## Phase 11 — Préparation Active Directory : utilisateurs et groupes

### Création des 3 groupes de sécurité

```powershell
New-ADGroup -Name "IT" -GroupScope Global -GroupCategory Security -Path "CN=Users,DC=Sharepoint,DC=lan"
New-ADGroup -Name "Administration" -GroupScope Global -GroupCategory Security -Path "CN=Users,DC=Sharepoint,DC=lan"
New-ADGroup -Name "Dev" -GroupScope Global -GroupCategory Security -Path "CN=Users,DC=Sharepoint,DC=lan"
```

### Création des utilisateurs

```powershell
$pwd = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force

# Équipe IT
New-ADUser -Name "Julien Martin" -SamAccountName "jmartin" -UserPrincipalName "jmartin@Sharepoint.lan" -GivenName "Julien" -Surname "Martin" -AccountPassword $pwd -Enabled $true
New-ADUser -Name "Sophie Durand" -SamAccountName "sdurand" -UserPrincipalName "sdurand@Sharepoint.lan" -GivenName "Sophie" -Surname "Durand" -AccountPassword $pwd -Enabled $true

# Équipe Administration
New-ADUser -Name "Marie Lefevre" -SamAccountName "mlefevre" -UserPrincipalName "mlefevre@Sharepoint.lan" -GivenName "Marie" -Surname "Lefevre" -AccountPassword $pwd -Enabled $true
New-ADUser -Name "Paul Bernard" -SamAccountName "pbernard" -UserPrincipalName "pbernard@Sharepoint.lan" -GivenName "Paul" -Surname "Bernard" -AccountPassword $pwd -Enabled $true

# Équipe Dev
New-ADUser -Name "Nicolas Petit" -SamAccountName "npetit" -UserPrincipalName "npetit@Sharepoint.lan" -GivenName "Nicolas" -Surname "Petit" -AccountPassword $pwd -Enabled $true
New-ADUser -Name "Camille Roux" -SamAccountName "croux" -UserPrincipalName "croux@Sharepoint.lan" -GivenName "Camille" -Surname "Roux" -AccountPassword $pwd -Enabled $true
```

### Répartition dans les groupes

```powershell
Add-ADGroupMember -Identity "IT" -Members "jmartin", "sdurand"
Add-ADGroupMember -Identity "Administration" -Members "mlefevre", "pbernard"
Add-ADGroupMember -Identity "Dev" -Members "npetit", "croux"
```

### Vérification

```powershell
Get-ADGroupMember -Identity "IT"
Get-ADGroupMember -Identity "Administration"
Get-ADGroupMember -Identity "Dev"
```

---

## Phase 12 — Accès à l'administration SharePoint et assistant de configuration

### Connexion

```
http://SRV-DC:8286
```
*(le port réel utilisé dans ce lab est **8286**, à ne pas confondre avec le 6566 initialement indiqué dans les consignes d'origine)*

### Résolution DNS optionnelle pour utiliser "sharepoint" comme nom d'hôte

```powershell
Add-DnsServerResourceRecordCName -Name "sharepoint" -HostNameAlias "SRV-DC.Sharepoint.lan" -ZoneName "Sharepoint.lan"
```

### Assistant de configuration de la ferme

Sur l'écran d'accueil de l'administration centrale : **"Start the Wizard"**

1. Décoche le téléchargement de mises à jour si pas d'accès internet
2. **Services to start** : cocher au minimum Managed Metadata Service, User Profile Service, Search Service Application
3. **Create Site Collection** — création du site racine **"Accueil"** :
   - Title : `Accueil`
   - Template : **Team Site** (onglet Collaboration)
   - URL : racine (`/`)

---

## Phase 13 — Arborescence des sites

```
Accueil (hérité — accessible à tous)
├── IT (permissions uniques — groupe IT)
│   ├── Client (permissions uniques — groupe IT, + bibliothèque Facture pour Administration)
│   └── Internal (permissions uniques — groupe IT)
├── Project (permissions uniques — groupe Dev)
├── Wiki (permissions héritées — accessible à tous)
└── Administration (permissions uniques — groupe Administration, + calendrier Meeting pour IT)
```

### Méthode générale de création d'un sous-site

Depuis le site parent : **⚙️ Paramètres** → **Site contents** → **New** → **Subsite**

*(si l'option n'apparaît pas dans le menu, utiliser directement l'URL `/_layouts/15/newsbweb.aspx` adaptée à ton site parent)*

### Sous-site IT (sous Accueil)

| Champ | Valeur |
|---|---|
| Title / URL | `IT` |
| Template | Team Site |
| Permissions | **Use unique permissions** |

Sur l'écran "Set Up Groups for this Site" :
- **Members of this Site** → ajouter `Sharepoint\IT`
- **Owners of this Site** → `Sharepoint\Technicien`

### Sous-site Project (sous Accueil)

| Champ | Valeur |
|---|---|
| Title / URL | `Project` |
| Template | **Project Site** (onglet Collaboration) |
| Permissions | **Use unique permissions** |

- **Members of this Site** → `Sharepoint\Dev`
- **Owners of this Site** → `Sharepoint\Technicien`

### Sous-site Wiki (sous Accueil)

| Champ | Valeur |
|---|---|
| Title / URL | `Wiki` |
| Template | Team Site *(voir note ci-dessous)* |
| Permissions | **Use the same permissions as parent site** *(hérité — accessible à tous)* |

### Sous-site Administration (sous Accueil)

| Champ | Valeur |
|---|---|
| Title / URL | `Administration` |
| Template | Team Site |
| Permissions | **Use unique permissions** |

- **Members of this Site** → `Sharepoint\Administration`
- **Owners of this Site** → `Sharepoint\Technicien`

### Sous-sites IT/Client et IT/Internal (créés depuis le site IT, pas Accueil)

| Site | Template | Permissions | Members |
|---|---|---|---|
| Client | Team Site | Unique | `Sharepoint\IT` |
| Internal | Team Site | Unique | `Sharepoint\IT` |

---

## Phase 14 — Applications par site

### Accueil
- **Custom List** nommée `liste du personnel`, colonnes : Nom, Prénom, Mail, Téléphone, Département *(type Choice conseillé : IT / Administration / Dev)*, Adresse
- **Document Library** pour la gestion de documents
- **Change the look** → uploader le logo de l'entreprise et modifier le nom du site dans l'en-tête

### IT
- **Document Library**
- **Tasks** (liste de tâches) pour la gestion de projet interne à l'IT
- **Change the look** → personnaliser couleurs/logo différemment d'Accueil

### IT/Client
- **Document Library** classique
- **Document Library** nommée `Facture`, avec **permissions rompues** (voir Phase 15) pour donner l'accès au groupe **Administration**

### IT/Internal
- Aucune application spécifique demandée — site simplement restreint à l'IT

### Project
- Liste **Tasks** native (via le template Project Site) : créer 1-2 « projets » avec plusieurs tâches, dates d'échéance (Due Date), assignation (Assigned To), % Complete
- Vue calendrier optionnelle basée sur la colonne Due Date

### Wiki
- Pages de wiki créées via la bibliothèque wiki ajoutée (voir Phase 15 — note sur le template manquant)

### Administration
- **Custom List** libre (documents administratifs, suivi, etc.)
- **Document Library**
- **Calendar** nommé `Meeting`, avec **permissions rompues** pour donner l'accès au groupe **IT**

---

## Phase 15 — Gestion des permissions au niveau liste/bibliothèque (rupture d'héritage)

Utilisé pour "Facture" (IT/Client → visible par Administration) et "Meeting" (Administration → visible par IT).

### Procédure

1. Ouvrir la liste/bibliothèque concernée
2. **⚙️ Paramètres de la liste** (ou **List/Library Settings** dans le ruban)
3. Section **Permissions and Management** → **Permissions for this list/library**
4. **Stop Inheriting Permissions** → confirmer
5. **Grant Permissions** → ajouter le groupe AD concerné (`Sharepoint\Administration` ou `Sharepoint\IT`) avec le niveau souhaité (Read ou Contribute)
6. Optionnel : retirer les groupes hérités si l'accès doit être strictement exclusif au nouveau groupe ajouté

> Cette approche (rupture d'héritage au niveau d'un objet spécifique plutôt qu'au niveau du site entier) est la bonne pratique pour gérer des exceptions ponctuelles sans complexifier toute l'architecture de permissions.

---

## 🔧 Pièges rencontrés et corrections

### Template "Project Site" oublié à la création

**Symptôme** : le sous-site Project a été créé par erreur avec le template "Team Site" au lieu de "Project Site".

**Deux solutions possibles :**

**Option A — Ajouter manuellement les fonctionnalités projet (recommandé, plus rapide)**
Un Team Site peut reproduire un site de projet en ajoutant :
- **⚙️ Paramètres** → **Add an app** → **Tasks** (liste de tâches, pour deadlines et suivi)
- **⚙️ Paramètres** → **Add an app** → **Calendar** (optionnel, vue calendrier des échéances)

Avantage : pas besoin de reconfigurer les permissions déjà en place.

**Option B — Supprimer et recréer le site**
1. **⚙️ Paramètres** → **Site information** → **Delete site**
2. Confirmer la suppression
3. Recréer le sous-site en sélectionnant bien **Project Site** dans l'onglet Collaboration

Avantage : bénéficie des colonnes et fonctionnalités natives du vrai template (Predecessors, % Complete pré-configuré, etc.). Inconvénient : à refaire depuis zéro, y compris les permissions de groupe.

### Template "Wiki" introuvable dans les modèles de site

**Symptôme** : ni "Wiki Page Library" ni "Enterprise Wiki" n'apparaissent dans les onglets Collaboration/Enterprise du sélecteur de modèle de sous-site.

**Cause probable** : fonctionnalité "SharePoint Server Publishing Infrastructure" non activée au niveau de la collection de sites sur cette édition/config.

**Solution appliquée** : créer un sous-site classique avec le template **Team Site** (permissions héritées), puis ajouter manuellement la bibliothèque wiki :
- **⚙️ Paramètres** → **Add an app** → chercher **"Wiki Page Library"** → **Add**

Résultat identique pour l'utilisateur final (pages wiki collaboratives et modifiables), simplement via une app ajoutée plutôt qu'un template de site dédié.

---

## ✅ Récapitulatif de l'exercice

- [x] 3 groupes AD (IT, Administration, Dev) + 6 utilisateurs répartis
- [x] Connexion à l'administration SharePoint, assistant de configuration exécuté
- [x] Site "Accueil" créé (accessible à tous)
- [x] 4 sous-sites créés (IT, Project, Wiki, Administration) avec permissions adaptées
- [x] 2 sous-sites IT créés (Client, Internal)
- [x] Applications ajoutées sur chaque site selon les consignes (listes, bibliothèques, calendrier)
- [x] Permissions croisées configurées via rupture d'héritage (Facture → Administration, Meeting → IT)
- [x] Personnalisation visuelle (logo, couleurs) sur Accueil et IT

Le lab SharePoint est maintenant fonctionnel avec une architecture de sites réaliste, des permissions différenciées par groupe métier, et plusieurs types de contenus (listes, documents, tâches, wiki, calendrier).
