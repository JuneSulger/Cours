# Réseau & Systèmes — Les bases et le vocabulaire du métier

Ce document part de zéro : les concepts réseau (IP, DHCP, DNS...) et système (Active Directory, comptes, virtualisation...) qui reviennent en permanence en administration système/réseau, avec une définition claire et un exemple concret pour chacun.

---

## Partie 1 — Réseau

### 1.1 Qu'est-ce qu'un réseau

Un **réseau informatique** est un ensemble d'appareils (ordinateurs, serveurs, imprimantes, téléphones...) reliés entre eux pour échanger des données. Deux grandes échelles à connaître :

| Terme | Définition |
|---|---|
| **LAN** (*Local Area Network*) | Réseau local, limité à un espace physique restreint (un bâtiment, un site) |
| **WAN** (*Wide Area Network*) | Réseau étendu, qui relie des sites distants entre eux (souvent via Internet) |
| **Internet** | Le réseau mondial de réseaux, interconnectant des milliards d'appareils |
| **Intranet** | Réseau privé interne à une organisation, basé sur les mêmes technologies qu'Internet mais non accessible depuis l'extérieur |

### 1.2 L'adresse IP

Une **adresse IP** (*Internet Protocol*) est l'identifiant numérique unique d'un appareil sur un réseau — l'équivalent d'une adresse postale : elle permet de savoir **où envoyer** les données.

**Format IPv4** (le plus courant) : 4 nombres de 0 à 255, séparés par des points.
```
192.168.1.10
```
Chaque nombre représente 8 bits (un *octet*) — une adresse IPv4 complète fait donc 32 bits.

**IPv6**, la version plus récente (créée car IPv4 arrive à épuisement des adresses disponibles à l'échelle mondiale) :
```
2001:0db8:85a3:0000:0000:8a2e:0370:7334
```
128 bits, notation hexadécimale, séparée par `:`.

#### IP publique vs IP privée

| Type | Portée | Exemple de plage |
|---|---|---|
| **IP publique** | Unique sur tout Internet, attribuée par un FAI/registre | Toute adresse hors des plages privées |
| **IP privée** | Valable uniquement à l'intérieur d'un réseau local, réutilisable ailleurs | `10.0.0.0` – `10.255.255.255`, `172.16.0.0` – `172.31.255.255`, `192.168.0.0` – `192.168.255.255` |

Ces trois plages privées sont réservées par une norme (RFC 1918) — c'est pour ça que ton réseau local à la maison et celui d'une entreprise à l'autre bout du monde peuvent tous les deux utiliser `192.168.1.1` sans jamais entrer en conflit : ces adresses ne sont jamais routées sur Internet telles quelles.

#### IP statique vs IP dynamique

| Type | Définition |
|---|---|
| **IP statique** | Adresse configurée manuellement, fixe dans le temps — utilisée pour les serveurs (on doit toujours savoir où les trouver) |
| **IP dynamique** | Adresse attribuée automatiquement (généralement par DHCP), qui peut changer à chaque connexion — utilisée pour les postes clients |

### 1.3 Le masque de sous-réseau (subnet mask)

Le **masque de sous-réseau** définit quelle partie d'une adresse IP désigne le **réseau**, et quelle partie désigne l'**hôte** (l'appareil précis) au sein de ce réseau.

**Exemple :**
```
IP    : 192.168.1.10
Masque: 255.255.255.0
```
Ici, `255.255.255` (les 3 premiers blocs) désigne le réseau (`192.168.1.0`), et le dernier `.10` désigne l'appareil précis dans ce réseau.

#### Notation CIDR
Plutôt que d'écrire le masque en entier, on utilise souvent la notation **CIDR** (*Classless Inter-Domain Routing*) : le nombre de bits qui composent la partie réseau, après un `/`.
```
192.168.1.10/24
```
`/24` = 24 bits pour le réseau = équivalent de `255.255.255.0`.

| Notation CIDR | Masque équivalent | Nombre d'adresses utilisables |
|---|---|---|
| /24 | 255.255.255.0 | 254 |
| /25 | 255.255.255.128 | 126 |
| /28 | 255.255.255.240 | 14 |
| /30 | 255.255.255.252 | 2 (souvent utilisé pour une liaison point à point) |

💡 On "perd" toujours 2 adresses par sous-réseau : la première (**adresse réseau**, désigne le réseau lui-même) et la dernière (**adresse de broadcast**, envoie à tous les appareils du réseau en une fois) ne sont jamais attribuables à un appareil.

### 1.4 La passerelle (gateway)

La **passerelle par défaut** (*default gateway*) est l'adresse IP de l'appareil (généralement un routeur) par lequel transite tout le trafic qui doit **sortir** du réseau local pour aller ailleurs (un autre réseau, Internet).

**Analogie :** c'est la porte de sortie de ton quartier — si tu veux aller dans un autre quartier (un autre réseau), tu dois obligatoirement passer par cette porte.

```
Exemple typique :
Réseau      : 192.168.1.0/24
Passerelle  : 192.168.1.1  ← le routeur
Ton PC      : 192.168.1.10
```

### 1.5 Le DNS (Domain Name System)

Le **DNS** traduit des **noms de domaine** (faciles à retenir pour un humain) en **adresses IP** (nécessaires pour que les machines communiquent). C'est littéralement l'annuaire téléphonique d'Internet.

```
google.com  →  DNS  →  142.250.affiche...
```

| Terme lié au DNS | Définition |
|---|---|
| **Serveur DNS** | Machine qui répond aux requêtes de résolution de noms |
| **Enregistrement A** | Associe un nom de domaine à une adresse IPv4 |
| **Enregistrement AAAA** | Associe un nom de domaine à une adresse IPv6 |
| **Enregistrement CNAME** | Alias — fait pointer un nom vers un autre nom de domaine |
| **Enregistrement MX** | Indique quel serveur gère les emails du domaine |
| **Zone DNS** | Portion de l'espace de noms gérée par un serveur DNS donné (ex. la zone `lab.local`) |
| **Résolution DNS** | Le processus complet de traduction nom → IP |
| **Cache DNS** | Mémorisation temporaire des résultats déjà résolus, pour éviter de refaire la même requête sans cesse |

💡 Dans un domaine Active Directory, le DNS n'est pas juste "pratique" — il est **indispensable** : les contrôleurs de domaine s'enregistrent eux-mêmes dans le DNS pour que les machines du domaine puissent les localiser automatiquement.

### 1.6 Le DHCP (Dynamic Host Configuration Protocol)

Le **DHCP** attribue **automatiquement** une configuration réseau complète (IP, masque, passerelle, DNS) à un appareil qui se connecte au réseau — sans ça, il faudrait configurer chaque appareil manuellement un par un.

**Le processus DHCP (souvent résumé par l'acronyme DORA) :**

| Étape | Nom | Description |
|---|---|---|
| 1 | **Discover** | Le client diffuse une requête "Y a-t-il un serveur DHCP ici ?" à tout le réseau local |
| 2 | **Offer** | Le serveur DHCP répond en proposant une configuration (IP, bail...) |
| 3 | **Request** | Le client confirme qu'il accepte cette offre |
| 4 | **Acknowledge** | Le serveur valide définitivement l'attribution |

| Terme lié au DHCP | Définition |
|---|---|
| **Étendue** (*scope*) | La plage d'adresses IP qu'un serveur DHCP est autorisé à distribuer |
| **Bail** (*lease*) | La durée pendant laquelle une IP est attribuée à un appareil, avant renouvellement ou réattribution |
| **Réservation** | Fait qu'un appareil précis (identifié par son adresse MAC) reçoive toujours la même IP via DHCP |
| **Exclusion** | Adresses volontairement retirées de l'étendue (ex. déjà utilisées en statique par des serveurs) |

### 1.7 Adresse MAC

L'**adresse MAC** (*Media Access Control*) est un identifiant physique unique, gravé sur la carte réseau d'un appareil (contrairement à l'IP, qui peut changer). Format : 6 paires de caractères hexadécimaux.
```
00:1A:2B:3C:4D:5E
```
Elle sert au niveau local (réseau physique/switch) pour identifier précisément un appareil, indépendamment de son adresse IP actuelle.

### 1.8 Ports et protocoles

Un **port** est un numéro qui identifie, au sein d'une même machine, **quel service ou quelle application** doit recevoir les données reçues. Une IP identifie la machine, un port identifie le service précis sur cette machine.

| Port | Protocole/service | Usage |
|---|---|---|
| 20/21 | FTP | Transfert de fichiers |
| 22 | SSH | Connexion distante sécurisée |
| 25 | SMTP | Envoi d'emails |
| 53 | DNS | Résolution de noms |
| 67/68 | DHCP | Attribution automatique d'IP |
| 80 | HTTP | Web (non chiffré) |
| 88 | Kerberos | Authentification (Active Directory) |
| 443 | HTTPS | Web (chiffré) |
| 445 | SMB | Partage de fichiers Windows |
| 389 | LDAP | Annuaire (Active Directory) |
| 1433 | SQL Server | Base de données Microsoft SQL Server |
| 3389 | RDP | Bureau à distance Windows |

#### TCP vs UDP

| | TCP | UDP |
|---|---|---|
| Fiabilité | Connexion établie, accusé de réception, ordre garanti | Aucune garantie, plus rapide |
| Usage typique | Web, email, transfert de fichiers (où perdre une donnée est inacceptable) | Streaming vidéo, jeux en ligne, DNS (où la vitesse prime sur la fiabilité absolue) |

### 1.9 Switch, routeur, pare-feu

| Équipement | Rôle |
|---|---|
| **Switch** (commutateur) | Relie plusieurs appareils d'un **même** réseau local, achemine le trafic selon les adresses MAC |
| **Routeur** (router) | Relie des réseaux **différents** entre eux, achemine le trafic selon les adresses IP |
| **Pare-feu** (firewall) | Filtre le trafic entrant/sortant selon des règles de sécurité (autoriser/bloquer par port, IP, protocole) |
| **Point d'accès Wi-Fi** (access point) | Permet la connexion sans fil au réseau |
| **Hub** (concentrateur) | Ancêtre du switch — répète le signal à tous les ports sans intelligence de routage (obsolète aujourd'hui) |

### 1.10 NAT (Network Address Translation)

Le **NAT** permet à plusieurs appareils partageant des IP **privées** de sortir sur Internet via une **seule** IP **publique** partagée. C'est ce qui permet à tout ton réseau domestique (plusieurs appareils en `192.168.x.x`) d'accéder à Internet alors que ton fournisseur d'accès ne t'a donné qu'une seule IP publique.

### 1.11 VLAN (Virtual LAN)

Un **VLAN** segmente logiquement un réseau physique unique en plusieurs réseaux **virtuellement séparés**, sans avoir besoin de câblage ou d'équipement physique différent. Utile pour isoler par exemple le trafic du service comptabilité de celui du service technique, même s'ils sont branchés sur le même switch physique.

### 1.12 Modèle OSI (repère théorique)

Le **modèle OSI** décrit en 7 couches comment les données circulent d'une application à l'autre à travers un réseau. Utile surtout pour situer où se passe un problème lors d'un dépannage :

| Couche | Nom | Exemple |
|---|---|---|
| 7 | Application | HTTP, DNS, SMTP |
| 6 | Présentation | Chiffrement, formats de données |
| 5 | Session | Ouverture/fermeture de sessions |
| 4 | Transport | TCP, UDP |
| 3 | Réseau | IP, routage |
| 2 | Liaison de données | Switch, adresses MAC |
| 1 | Physique | Câbles, signaux électriques/optiques |

---

## Partie 2 — Systèmes

### 2.1 Système d'exploitation (OS)

Un **système d'exploitation** (OS) est le logiciel qui gère les ressources matérielles d'un ordinateur (CPU, RAM, disque, réseau) et fournit une interface pour que les autres logiciels puissent fonctionner. Exemples : Windows Server, Windows 11, Linux (Debian, Ubuntu, RHEL...).

| Terme | Définition |
|---|---|
| **Kernel** (noyau) | Le cœur de l'OS, qui communique directement avec le matériel |
| **Service** (Windows) / **Daemon** (Linux) | Programme qui tourne en arrière-plan, sans interface graphique, souvent au démarrage de la machine (ex. le service DHCP, le service DNS) |
| **Processus** | Une instance d'un programme en cours d'exécution |

### 2.2 Client / Serveur

| Rôle | Définition |
|---|---|
| **Serveur** | Machine qui **fournit** un service à d'autres machines (fichiers, authentification, base de données, web...) |
| **Client** | Machine qui **consomme** un service fourni par un serveur |

Un même service peut avoir plusieurs clients simultanés — c'est le principe même de la plupart des services réseau (un serveur DNS répond à des centaines de requêtes clients).

### 2.3 Comptes, groupes et permissions

| Terme | Définition |
|---|---|
| **Compte utilisateur** | Identité permettant de s'authentifier sur un système |
| **Compte ordinateur** | Identité représentant une machine elle-même dans un domaine (se termine par `$`, ex. `SQL01$`) |
| **Groupe** | Ensemble de comptes, pour attribuer des droits collectivement plutôt qu'un par un |
| **Authentification** | Vérifier qu'on est bien qui on prétend être (ex. mot de passe, certificat, biométrie) |
| **Autorisation** | Une fois authentifié, déterminer ce qu'on a le droit de faire |
| **Droits / permissions** | Les actions précises autorisées sur une ressource (lire, écrire, exécuter, supprimer) |
| **Principe du moindre privilège** | Ne donner à chaque compte que les droits strictement nécessaires à sa tâche — pas plus |

### 2.4 Active Directory (AD)

**Active Directory** est le service d'annuaire de Microsoft : il centralise et gère les identités (utilisateurs, ordinateurs, groupes) et les ressources d'un réseau d'entreprise, dans une base de données hiérarchique unique.

**Pourquoi c'est central en entreprise :** sans AD, chaque serveur/poste aurait sa propre liste d'utilisateurs et de mots de passe séparée — ingérable dès qu'on dépasse quelques machines. Avec AD, un utilisateur se connecte **une fois** avec un compte de domaine, et ce compte fonctionne sur toutes les machines jointes à ce domaine.

#### Structure hiérarchique d'Active Directory

```
Forêt (Forest)
    │
    └── Domaine (Domain)
            │
            ├── Unité d'Organisation (OU)
            │       ├── Utilisateurs
            │       ├── Ordinateurs
            │       └── Groupes
            │
            └── Contrôleur de Domaine (DC)
```

| Terme | Définition |
|---|---|
| **Forêt** (*Forest*) | Le plus haut niveau — regroupe un ou plusieurs domaines qui partagent un schéma et une configuration communs |
| **Arbre** (*Tree*) | Un regroupement de domaines dans une forêt partageant un espace de noms contigu (ex. `lab.local` et `europe.lab.local`) |
| **Domaine** (*Domain*) | Une limite de sécurité et d'administration — contient les objets (utilisateurs, ordinateurs, groupes) et applique des politiques communes (ex. `lab.local`) |
| **Contrôleur de domaine** (*Domain Controller, DC*) | Serveur qui héberge la base Active Directory et répond aux demandes d'authentification |
| **Unité d'Organisation** (*Organizational Unit, OU*) | Conteneur pour organiser les objets AD (ranger, appliquer des GPO, déléguer des droits d'administration) |
| **Objet AD** | Tout élément géré par Active Directory : un utilisateur, un ordinateur, un groupe, une imprimante partagée... |
| **Schéma AD** | La définition de tous les types d'objets et d'attributs possibles dans l'annuaire |
| **Réplication AD** | Processus par lequel plusieurs contrôleurs de domaine synchronisent leurs bases entre eux, pour rester cohérents |
| **Rôles FSMO** | Cinq rôles spécifiques attribués à un ou plusieurs DC pour gérer des opérations qui ne supportent pas la réplication multi-maître (ex. attribution des identifiants uniques, schéma) |

#### GPO (Group Policy Object)

Une **GPO** est un ensemble de règles de configuration appliquées automatiquement aux utilisateurs et/ou ordinateurs d'un domaine, d'un site ou d'une OU — par exemple imposer un fond d'écran, restreindre l'accès au Panneau de configuration, déployer un lecteur réseau automatiquement, forcer une politique de mot de passe complexe.

#### Authentification dans Active Directory

| Protocole | Usage |
|---|---|
| **Kerberos** | Protocole d'authentification par défaut dans un domaine AD moderne — basé sur des "tickets" temporaires plutôt que de transmettre le mot de passe à chaque requête |
| **NTLM** | Ancien protocole d'authentification Windows, encore utilisé en fallback dans certains cas (moins sécurisé que Kerberos) |
| **LDAP** (*Lightweight Directory Access Protocol*) | Protocole standard utilisé pour interroger/modifier un annuaire comme Active Directory |

💡 **gMSA (Group Managed Service Account)** — compte de service spécial dont le mot de passe est généré et renouvelé automatiquement par Active Directory, jamais connu d'un humain, pouvant être partagé par plusieurs serveurs (ex. utilisé pour faire tourner un service comme SQL Server de façon sécurisée).

### 2.5 Virtualisation

La **virtualisation** permet de faire tourner plusieurs systèmes d'exploitation indépendants (des **machines virtuelles**) sur un seul serveur physique, en partageant ses ressources matérielles.

| Terme | Définition |
|---|---|
| **Hyperviseur** | Le logiciel qui crée et gère les machines virtuelles (ex. Hyper-V, VMware ESXi) |
| **Hyperviseur type 1** (*bare metal*) | Installé directement sur le matériel physique, sans OS hôte intermédiaire (ex. Hyper-V sur Windows Server, ESXi) |
| **Hyperviseur type 2** | Installé comme une application au-dessus d'un OS existant (ex. VirtualBox, VMware Workstation) |
| **Machine virtuelle (VM)** | Un ordinateur "simulé" par l'hyperviseur, avec son propre OS, ses propres ressources allouées |
| **Snapshot / Checkpoint** | Image figée de l'état d'une VM à un instant T, permettant d'y revenir plus tard |
| **VHD / VHDX** | Format de fichier représentant le disque dur virtuel d'une VM (Hyper-V) |
| **Commutateur virtuel** (*virtual switch*) | Équivalent virtuel d'un switch physique, pour connecter les VM entre elles et/ou au réseau physique |

### 2.6 Stockage

| Terme | Définition |
|---|---|
| **Partition** | Division logique d'un disque physique en plusieurs volumes distincts |
| **Volume** | Une portion de stockage formatée et utilisable, avec une lettre de lecteur (Windows) ou un point de montage (Linux) |
| **Système de fichiers** | La structure logique qui organise les données sur un disque (ex. NTFS, ext4, FAT32) |
| **RAID** | Technique combinant plusieurs disques physiques pour améliorer la performance et/ou la tolérance aux pannes (ex. RAID 1 = duplication, RAID 5 = répartition avec parité) |
| **IOPS** | Nombre d'opérations d'entrée/sortie par seconde qu'un disque peut traiter — indicateur de performance |

### 2.7 Sauvegarde et haute disponibilité

| Terme | Définition |
|---|---|
| **Sauvegarde** (*backup*) | Copie des données à un instant donné, pour pouvoir les restaurer en cas de perte |
| **Sauvegarde complète** (*full backup*) | Copie de l'intégralité des données |
| **Sauvegarde différentielle** | Copie des changements depuis la dernière sauvegarde complète |
| **Sauvegarde incrémentielle** | Copie des changements depuis la dernière sauvegarde (complète ou incrémentielle) |
| **RTO** (*Recovery Time Objective*) | Délai maximal acceptable pour restaurer un service après un incident |
| **RPO** (*Recovery Point Objective*) | Quantité maximale de données qu'on accepte de perdre (mesurée en temps depuis la dernière sauvegarde valide) |
| **Haute disponibilité** (*High Availability, HA*) | Conception visant à maintenir un service accessible malgré la panne d'un composant |
| **Cluster de basculement** (*Failover Cluster*) | Groupe de serveurs qui se surveillent mutuellement — si l'un tombe, un autre prend automatiquement le relais |
| **Quorum** | Mécanisme déterminant si un cluster dispose d'assez de "votes" pour continuer à fonctionner sans risque d'incohérence |

---

## Partie 3 — Glossaire alphabétique complet

| Terme | Définition |
|---|---|
| **Active Directory (AD)** | Service d'annuaire Microsoft centralisant identités et ressources d'un réseau |
| **Adresse IP** | Identifiant numérique unique d'un appareil sur un réseau |
| **Adresse MAC** | Identifiant physique unique d'une carte réseau |
| **Authentification** | Vérification de l'identité d'un utilisateur/appareil |
| **Autorisation** | Détermination de ce qu'un compte authentifié a le droit de faire |
| **CIDR** | Notation compacte du masque de sous-réseau (ex. /24) |
| **Cluster** | Groupe de serveurs travaillant ensemble pour la disponibilité/performance |
| **Contrôleur de domaine (DC)** | Serveur hébergeant la base Active Directory |
| **DHCP** | Protocole d'attribution automatique de configuration IP |
| **DNS** | Système de traduction noms de domaine ↔ adresses IP |
| **Domaine (AD)** | Limite de sécurité/administration regroupant des objets AD |
| **Firewall (pare-feu)** | Équipement/logiciel filtrant le trafic réseau selon des règles |
| **Forêt (AD)** | Regroupement de domaines partageant schéma et configuration |
| **GPO** | Règles de configuration appliquées automatiquement dans un domaine |
| **Gateway (passerelle)** | Point de sortie du réseau local vers d'autres réseaux |
| **gMSA** | Compte de service AD à mot de passe géré automatiquement |
| **Groupe (AD)** | Ensemble de comptes pour attribuer des droits collectivement |
| **Hôte (host)** | Un appareil identifié individuellement sur un réseau |
| **Hyperviseur** | Logiciel créant/gérant des machines virtuelles |
| **IPv4 / IPv6** | Versions du protocole d'adressage IP (32 bits / 128 bits) |
| **Kerberos** | Protocole d'authentification par ticket, standard dans un domaine AD |
| **LAN** | Réseau local |
| **LDAP** | Protocole d'interrogation d'un annuaire comme Active Directory |
| **Masque de sous-réseau** | Définit la partie réseau vs partie hôte d'une adresse IP |
| **NAT** | Traduction d'adresses privées vers une IP publique partagée |
| **NTLM** | Ancien protocole d'authentification Windows |
| **OU (Unité d'Organisation)** | Conteneur organisant les objets Active Directory |
| **Passerelle** | Voir Gateway |
| **Permissions** | Droits précis accordés sur une ressource |
| **Port** | Numéro identifiant un service précis sur une machine |
| **Protocole** | Ensemble de règles standardisées pour la communication réseau |
| **RAID** | Combinaison de disques physiques pour performance/résilience |
| **RDP** | Protocole de bureau à distance Windows |
| **Réplication (AD)** | Synchronisation des données entre contrôleurs de domaine |
| **RPO** | Quantité de données maximale acceptable à perdre lors d'un incident |
| **RTO** | Délai maximal acceptable pour restaurer un service |
| **RAID / Volume / Partition** | Voir section stockage |
| **Serveur** | Machine fournissant un service à d'autres machines |
| **Service (Windows) / Daemon (Linux)** | Programme tournant en arrière-plan |
| **SMB** | Protocole de partage de fichiers Windows |
| **Snapshot / Checkpoint** | État figé d'une VM à un instant donné |
| **Switch** | Équipement reliant des appareils d'un même réseau local |
| **TCP / UDP** | Protocoles de transport (fiable / rapide sans garantie) |
| **VHD / VHDX** | Format de disque dur virtuel (Hyper-V) |
| **Virtualisation** | Exécution de plusieurs OS indépendants sur un même matériel physique |
| **VLAN** | Segmentation logique d'un réseau physique |
| **VM (Machine virtuelle)** | Ordinateur simulé par un hyperviseur |
| **WAN** | Réseau étendu reliant des sites distants |

---

## Pour relier tout ça à la pratique

Ce vocabulaire n'est pas théorique — c'est exactement ce que tu manipules dans tes labs : un serveur DHCP (Kea) qui distribue des IP sur un sous-réseau `/24`, une forêt Active Directory (`lab.local`) avec ses OU et ses gMSA, un cluster de basculement pour SQL Server, une VM Hyper-V branchée sur un commutateur virtuel. Chaque terme de ce glossaire correspond à une commande ou un écran que tu as déjà manipulé.
