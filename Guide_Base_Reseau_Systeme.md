# Réseau & Systèmes — Les bases et le vocabulaire du métier

Ce document part de zéro : les concepts réseau (IP, DHCP, DNS...) et système (Active Directory, comptes, virtualisation...) qui reviennent en permanence en administration système/réseau, avec une définition claire et un exemple concret pour chacun.

---

### 1.1 Qu'est-ce qu'un réseau

Un **réseau informatique** est un ensemble d'appareils (ordinateurs, serveurs, imprimantes, téléphones...) reliés entre eux pour échanger des données. Deux grandes échelles à connaître :

| Terme | Définition |
|---|---|
| **LAN** (*Local Area Network*) | Réseau local, limité à un espace physique restreint (un bâtiment, un site) |
| **WAN** (*Wide Area Network*) | Réseau étendu, qui relie des sites distants entre eux (souvent via Internet) |
| **Internet** | Le réseau mondial de réseaux, interconnectant des milliards d'appareils |
| **Intranet** | Réseau privé interne à une organisation, basé sur les mêmes technologies qu'Internet mais non accessible depuis l'extérieur |


### 1.2 Le modèle OSI

Le **modèle OSI** (*Open System Interconnection*) décrit en **7 couches** comment les données circulent d'une application à l'autre à travers un réseau. C'est un modèle **théorique** sur lequel se base la conception moderne de tout réseau, normalisé ISO depuis 1984 — indispensable pour bien situer où se passe un problème lors d'un dépannage.

| Couche | Nom | Rôle | Technologies/protocoles | Équipement typique | Nom de la donnée |
|---|---|---|---|---|---|
| 7 | Application | Interaction entre applications et données | HTTP, DNS, SMTP, SSH | — | Données |
| 6 | Présentation | Représentation et chiffrement des données | SSL/TLS, formats de fichiers | — | Données |
| 5 | Session | Démarre, vérifie, met à jour et ferme les connexions (via TCP) | — | — | Données |
| 4 | Transport | Connexions point à point et fiabilité | TCP, UDP, SSL, TLS | Pare-feu | Segments |
| 3 | Réseau | Trouver la route jusqu'à la machine de destination | IP, ARP, ICMP, OSPF, IPSec | Routeur | Paquets |
| 2 | Liaison de données | Adressage physique, échange entre machines du réseau local | Ethernet, MAC, PPP, HDLC | Switch | Trame |
| 1 | Physique | Signal et média | Binaire, RJ45, RS-232, 802.11 | Câble, carte réseau | Bits |

💡 En pratique, on se concentre surtout sur les **5 premiers niveaux** en réseau — les couches 6 et 7 sont plutôt l'apanage des développeurs.

#### Encapsulation : le principe des poupées russes

Chaque couche encapsule les données de la couche du dessus dans son propre « emballage » (une entête, parfois une queue). Une trame Ethernet contient un paquet IP, qui contient un segment TCP/UDP, qui contient les données utiles (niveaux 5 à 7) :

```
[ Entête Ethernet [ Entête IP [ Entête TCP/UDP [ Données applicatives ] ] ] ]
```

**Pourquoi cet empilement ?** Historiquement, les réseaux locaux (Ethernet) se sont répandus **avant** les réseaux à grande échelle comme Internet (IP). Plutôt que de tout réinventer et forcer tous les réseaux locaux à changer, on a choisi d'encapsuler IP dans Ethernet, puis TCP dans IP.

Chaque niveau utilise un **appareil spécialisé** qui ne traite que la portion de binaire qui le concerne : un switch ne regarde que l'entête Ethernet (niveau 2), un routeur regarde l'entête IP (niveau 3), un pare-feu peut aller jusqu'à l'entête TCP/UDP (niveau 4, notion de port).

#### Approche de dépannage : bottom-top

Pour diagnostiquer (et résoudre) une panne réseau, l'approche recommandée est de partir du bas — les niveaux les moins sophistiqués — vers le haut. **60 % des pannes touchent les 2 premiers niveaux** (physique et liaison de données) : autant commencer par vérifier le câble et le lien avant de chercher plus loin.

### 1.3 Le modèle TCP/IP

Le **modèle TCP/IP** est une approche plus simple qu'OSI dans son implémentation, à la préférence des constructeurs. Il condense les 7 couches OSI en 4 :

| Couche TCP/IP | Équivalent OSI |
|---|---|
| 4 — Application | Application + Présentation + Session (couches 5 à 7) |
| 3 — Transport | Transport (couche 4) |
| 2 — Internet | Réseau (couche 3) |
| 1 — Hôte (accès réseau) | Liaison de données + Physique (couches 1 et 2) |

💡 Particularité : la première couche (Hôte) est **libre d'être implémentée** par les constructeurs comme ils le souhaitent — contrairement à OSI, plus strict.

### 1.4 Le protocole Ethernet (couche 2)

L'**Ethernet** est le protocole de couche 2 qui s'est imposé comme standard mondial (norme IEEE 802.3), après avoir été en concurrence avec d'autres technologies dans les années 80-90 (IEEE 802.4/ARCnet, IEEE 802.5/Token Ring). Avant ça, dans les années 70, chaque constructeur (IBM, NCR, Xerox, DEC, HP...) avait son propre protocole propriétaire.

💡 **802.11** = la version **sans fil** du protocole Ethernet.

#### Un protocole « non fiable » par nature

Au niveau 2 du modèle OSI, Ethernet est considéré comme **« non fiable »** : aucune garantie contre la corruption de données, le désordre, la perte/destruction de trames ou leur duplication. C'est aux couches supérieures (notamment TCP) de compenser si besoin.

#### Débits Ethernet

| Norme | Débit | Équivalent |
|---|---|---|
| FastEthernet | 100 Mbits/sec | 12,5 Mo/sec |
| GigabitEthernet | 1 Gbits/sec | 125 Mo/sec |
| Multigig | 10 Gbits/sec | 1250 Mo/sec |
| 802.3ba (2010) | 40 et 100 Gbits/sec | — |
| 802.3bs (2017) | 200 et 400 Gbits/sec | — |

En entreprise, le plus courant reste le **Gigabit Ethernet** et le **Multigig 10 Gbits**.

#### L'adresse MAC

L'**adresse MAC** (*Media Access Control*) permet une communication au sein du **réseau local uniquement**. Codée en hexadécimal sur **6 octets (48 bits)**, soit 2⁴⁸ possibilités — environ 281 000 milliards d'adresses.

```
72:16:f3:43:94:ec
```

- Les **3 premiers octets** identifient le **constructeur** de la carte.
- Les **3 derniers octets** identifient la **carte Ethernet** elle-même.

Elle est codée « en dur » dans la carte, théoriquement non modifiable — mais comme elle est transmise en clair dans chaque trame émise, il suffit de « mentir » dans les trames pour usurper une adresse MAC. Des outils simples permettent de le faire (point de vigilance sécurité).

💡 D'autres systèmes utilisent des synonymes pour « MAC Address » : **Hardware Address** (adresse matérielle) ou **Lladdr** (*link layer address*, adresse de lien local).

**La voir sur un équipement Cisco :** `show interfaces`. Note : un switch 24 ports a en réalité 24 adresses MAC différentes (une par port), plus une adresse MAC « globale » pour le switch lui-même.

#### Structure d'une trame Ethernet

| Champ | Préambule | SFD | Dest Addr | Source Addr | Type | Paquet IP (données) | FCS | Vide inter-trame |
|---|---|---|---|---|---|---|---|---|
| Taille | 8 octets | — | 6 octets | 6 octets | 2 octets | 46 à 1500 octets | 4 octets | 9,6 µs |

Le champ **Type** indique quel protocole de couche 3 est encapsulé :

| Valeur | Protocole |
|---|---|
| 0x0800 | IPv4 |
| 0x86DD | IPv6 |
| 0x0806 | ARP |
| 0x8100 | VLAN |

💡 La couche 2 comporte aussi une **sous-couche LLC** (*Logical Link Control*) : partie « supérieure » de la couche 2, elle sert à fiabiliser les protocoles de couche 2 et fait l'interfaçage entre le protocole de couche 2 et celui de couche 3.

#### Les collisions

Une **collision**, c'est la rencontre de deux messages émis en sens opposé sur le même médium — les deux appareils ont estimé que personne ne parlait, et l'information est détruite dans ce cas.

Historiquement, Ethernet gérait ça avec **CSMA/CD** (*Carrier Sense Multiple Access with Collision Detection*), utile sur un médium partagé (coaxial, hub). Depuis la généralisation du **full-duplex** et des commutateurs (switches), les collisions ont quasiment disparu — ce mécanisme de détection n'est même plus implémenté par les constructeurs depuis le passage au Gigabit Ethernet.

#### Auto-négociation

Quand deux appareils Ethernet se connectent, ils utilisent de courtes impulsions électriques (**FLP**, *Fast Link Pulse*) sur la paire 1-2 pour déterminer automatiquement :
- la vitesse commune,
- le mode de duplex,
- et négocier des capacités optionnelles :

| Capacité | Rôle |
|---|---|
| **Auto-MDI/MDIX** | Détection de la polarité du câble pour s'adapter au type droit ou croisé utilisé |
| **PoE** | Détection de l'appareil avant ou pendant l'auto-négociation, et le réveille (alimentation par le câble) |
| **EEE** (*Energy Efficient Ethernet*) | Capacité d'économiser de l'énergie |

### 1.5 L'adresse IP

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


#### Épuisement des adresses IPv4

Le protocole **IPv4** est défini depuis 1981 (couche 3 du modèle OSI) et fait communiquer des machines de réseaux différents entre elles via des adresses codées sur 32 bits — un maximum théorique de 4 294 967 296 adresses.

Dès **1994**, une première alerte est lancée sur l'épuisement des adresses. En janvier 1996, la classe A était déjà épuisée à 100 %, la classe B à 61,95 %, la classe C à 36,44 %. Des techniques comme la traduction d'adresses (NAT) ont été mises en place pour contourner cette limite.

💡 La répartition mondiale des adresses IPv4 est très inégale : environ **40 %** des adresses sont allouées aux États-Unis (pour ~300 millions d'habitants), contre seulement **3 %** pour la Chine (pour ~1,4 milliard d'habitants) — un héritage de l'histoire d'Internet.

#### Les classes d'adresses IPv4

L'adressage IPv4 était historiquement divisé en classes « A », « B », « C » (les classes « D » et « E » sont réservées) :

| Classe | Début | Fin | Masque décimal | Masque CIDR |
|---|---|---|---|---|
| A | 0.0.0.0 | 127.255.255.255 | 255.0.0.0 | /8 |
| B | 128.0.0.0 | 191.255.255.255 | 255.255.0.0 | /16 |
| C | 192.0.0.0 | 223.255.255.255 | 255.255.255.0 | /24 |
| D | 224.0.0.0 | 239.255.255.255 | réservée (multicast) | — |
| E | 240.0.0.0 | 255.255.255.255 | réservée | — |

💡 Ce système de classes était utilisé autrefois mais n'a plus vraiment de sens aujourd'hui : on peut attribuer n'importe quel masque à n'importe quelle IP (adressage « classless », d'où CIDR). Ça reste toutefois une culture de base à avoir en tant que technicien/admin réseau.

Les 3 plages d'adresses privées (déjà vues ci-dessus) correspondent chacune à une portion de ces classes historiques : `10.0.0.0`–`10.255.255.255` dans la classe A, `172.16.0.0`–`172.31.255.255` dans la classe B, `192.168.0.0`–`192.168.255.255` dans la classe C.

#### Les adresses APIPA

Une adresse **APIPA** (*Automatic Private IP Addressing*) est une adresse que la machine **s'octroie elle-même** quand le serveur DHCP n'a pas pu être trouvé — côté client, tout reste fonctionnel, mais ce sont des adresses souvent inutilisables pour communiquer avec le reste du réseau. Elles se trouvent entre `169.254.0.0` et `169.254.255.255`.

💡 Voir une IP en `169.254.x.x` sur une machine est un signe quasi certain d'un problème de DHCP.

#### Structure de l'entête du paquet IP

| Champ | Rôle |
|---|---|
| Version | Version du protocole (4 ou 6) |
| IHL | Longueur de l'entête |
| Type de Service (QoS) | Priorité / qualité de service |
| Longueur du paquet | Taille totale, limitée par la taille de la trame qui le contient |
| Identificateur | Numéro du paquet |
| Flags | Indique si le paquet peut être fragmenté ou non |
| Fragment Offset | Indique où se place un fragment dans un paquet reconstitué |
| TTL | Nombre de routeurs (sauts) que le paquet peut encore franchir |
| Protocole | Protocole de couche supérieure encapsulé (TCP, UDP...) |
| Header Checksum | Contrôle l'intégrité de l'entête uniquement |
| Adresse IP source | — |
| Adresse IP destination | — |
| Options / Rembourrage | Champs optionnels |

Le paquet IP (entête + charge utile) est ensuite encapsulé dans une trame Ethernet — dont la taille totale (entête Ethernet + paquet IP + FCS) est limitée à **1518 octets**.

### 1.6 Le masque de sous-réseau (subnet mask)

Le **masque de sous-réseau** définit quelle partie d'une adresse IP désigne le **réseau**, et quelle partie désigne l'**hôte** (l'appareil précis) au sein de ce réseau. Il est lui aussi codé sur 32 bits.

**Exemple standard (/24) :**
```
IP    : 192.168.1.10
Masque: 255.255.255.0    →   11111111.11111111.11111111.00000000
```
Ici, `255.255.255` (les 3 premiers blocs, 24 bits positifs) désigne le réseau (`192.168.1.0`), et le dernier bloc (8 bits, la partie « host ») désigne l'appareil précis : 2⁸ = 256 possibilités.

#### Le masque comme une « réglette »

Le masque n'est pas obligé de s'arrêter sur une frontière d'octet — c'est une réglette qu'on peut déplacer bit par bit pour ajuster la taille du réseau. Exemple avec un masque non-standard, plus grand :
```
IP    : 192.168.1.10
Masque: 255.255.255.192   →   11111111.11111111.11111111.11 000000
```
Ici, le masque fait **26 bits de long** (`/26`) — il n'est pas « standard », il est plus grand que `/24`, donc la partie « host » ne fait plus que 6 bits : 2⁶ = 64 possibilités, un réseau bien plus petit.

#### Notation CIDR
Plutôt que d'écrire le masque en entier, on utilise souvent la notation **CIDR** (*Classless Inter-Domain Routing*) : le nombre de bits qui composent la partie réseau, après un `/`. On compte simplement le nombre de bits positifs du masque.
```
192.168.1.10/24
```
`/24` = 24 bits pour le réseau = équivalent de `255.255.255.0`.

| Notation CIDR | Masque équivalent | Nombre d'adresses utilisables |
|---|---|---|
| /8 | 255.0.0.0 | ~16 millions |
| /16 | 255.255.0.0 | ~65 000 |
| /24 | 255.255.255.0 | 254 |
| /25 | 255.255.255.128 | 126 |
| /26 | 255.255.255.192 | 62 |
| /28 | 255.255.255.240 | 14 |
| /30 | 255.255.255.252 | 2 (souvent utilisé pour une liaison point à point) |

💡 On « perd » toujours 3 adresses par sous-réseau, pas seulement 2 : l'**adresse réseau** (désigne le réseau lui-même), l'**adresse de passerelle** (pour sortir du réseau) et l'**adresse de diffusion/broadcast** (pour parler à toutes les machines en même temps) ne sont jamais attribuables telles quelles à un appareil. La passerelle n'est pas une obligation technique stricte, mais c'est la convention quasi systématique.

#### Calcul binaire d'une adresse IP

Pour convertir un octet entre binaire et décimal à la main, le plus simple est de s'appuyer sur les puissances de 2 :

| 2⁷ | 2⁶ | 2⁵ | 2⁴ | 2³ | 2² | 2¹ | 2⁰ |
|---|---|---|---|---|---|---|---|
| 128 | 64 | 32 | 16 | 8 | 4 | 2 | 1 |

On additionne les valeurs des positions où le bit est à 1. Exemple : `11110000` → 128+64+32+16 = **240**.

### 1.7 Les interfaces réseau

Une **interface réseau** désigne tout ce qui permet de communiquer sur le réseau, quel que soit le protocole (Ethernet, IP, Token Ring...). Elle peut être :
- un **port physique** ;
- un **agrégat** de plusieurs ports physiques réunis en un port **virtuel** ;
- une **sous-interface**.

Une même interface peut avoir **plusieurs adresses IP** (tant qu'elles sont différentes) et/ou contenir des **sous-interfaces** — une interface physique découpée en plusieurs interfaces virtuelles. C'est ce qui permet par exemple de faire du routage entre 2 réseaux alors qu'on n'a qu'une seule carte réseau avec un seul port physique.

**Exemple sur Cisco IOS** — une même interface avec 3 IP différentes :
```
int Gi 0/0
desc IN
ip address 192.168.1.1 255.255.255.0
ip address 192.168.2.1 255.255.255.0 secondary
ip address 192.168.3.1 255.255.255.0 secondary
```
Et avec 3 sous-interfaces :
```
int Gi 0/0
interface Gi 0/0.1
interface Gi 0/0.2
interface Gi 0/0.3
```

**Exemple sur Linux** — une même interface `eth0` avec 2 IP différentes (`ip addr`) :
```
eth0 : <BROADCAST,MULTICAST,UP,LOWER_UP>
inet 192.168.1.57/24 brd 192.168.1.255
inet 192.168.1.177/24 brd 192.168.1.255
```
Et via `/etc/network/interfaces`, une sous-interface `eth0:1` :
```
auto eth0 eth0:1
iface eth0 inet static
    address 192.168.1.50
    network 192.168.1.0

iface eth0:1 inet static
    address 192.168.0.50
    network 192.168.0.0
```

**Ajouter une IP manuellement (Cisco IOS) :**
```
# enable
# conf t
# interface NOM_INTERFACE
# ip address IP MASQUE
```
**Vérifier la configuration IP :**
```
# enable
# show ip interface brief
```

### 1.8 La passerelle (gateway)

La **passerelle par défaut** (*default gateway*) est l'adresse IP de l'appareil (généralement un routeur) par lequel transite tout le trafic qui doit **sortir** du réseau local pour aller ailleurs (un autre réseau, Internet).

**Analogie :** c'est la porte de sortie de ton quartier — si tu veux aller dans un autre quartier (un autre réseau), tu dois obligatoirement passer par cette porte.

```
Exemple typique :
Réseau      : 192.168.1.0/24
Passerelle  : 192.168.1.1  ← le routeur
Ton PC      : 192.168.1.10
```

### 1.9 Le DNS (Domain Name System)

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

### 1.10 Le DHCP (Dynamic Host Configuration Protocol)

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

### 1.11 Ports et protocoles

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

### 1.12 Switch, routeur, pare-feu

| Équipement | Rôle |
|---|---|
| **Switch** (commutateur) | Relie plusieurs appareils d'un **même** réseau local, achemine le trafic selon les adresses MAC |
| **Routeur** (router) | Relie des réseaux **différents** entre eux, achemine le trafic selon les adresses IP |
| **Pare-feu** (firewall) | Filtre le trafic entrant/sortant selon des règles de sécurité (autoriser/bloquer par port, IP, protocole) |
| **Point d'accès Wi-Fi** (access point) | Permet la connexion sans fil au réseau |
| **Hub** (concentrateur) | Ancêtre du switch — répète le signal à tous les ports sans intelligence de routage (obsolète aujourd'hui) |

### 1.13 NAT (Network Address Translation)

Le **NAT** permet à plusieurs appareils partageant des IP **privées** de sortir sur Internet via une **seule** IP **publique** partagée. C'est ce qui permet à tout ton réseau domestique (plusieurs appareils en `192.168.x.x`) d'accéder à Internet alors que ton fournisseur d'accès ne t'a donné qu'une seule IP publique.

### 1.14 VLAN (Virtual LAN)

Un **VLAN** segmente logiquement un réseau physique unique en plusieurs réseaux **virtuellement séparés**, sans avoir besoin de câblage ou d'équipement physique différent. Utile pour isoler par exemple le trafic du service comptabilité de celui du service technique, même s'ils sont branchés sur le même switch physique.


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
| **Adresse MAC** | Identifiant physique unique d'une carte réseau, codé sur 48 bits |
| **APIPA** | Adresse que s'octroie une machine quand aucun serveur DHCP n'est trouvé (169.254.x.x) |
| **Authentification** | Vérification de l'identité d'un utilisateur/appareil |
| **Autorisation** | Détermination de ce qu'un compte authentifié a le droit de faire |
| **Auto-négociation** | Mécanisme Ethernet déterminant automatiquement vitesse, duplex et options entre 2 appareils |
| **CIDR** | Notation compacte du masque de sous-réseau (ex. /24) |
| **Classe d'adresse IP (A/B/C/D/E)** | Ancien découpage historique de l'espace d'adressage IPv4 |
| **Cluster** | Groupe de serveurs travaillant ensemble pour la disponibilité/performance |
| **Collision (Ethernet)** | Rencontre destructrice de 2 trames émises en même temps sur le même médium |
| **Contrôleur de domaine (DC)** | Serveur hébergeant la base Active Directory |
| **CSMA/CD** | Ancien mécanisme Ethernet de détection de collisions (obsolète depuis le full-duplex) |
| **DHCP** | Protocole d'attribution automatique de configuration IP |
| **DNS** | Système de traduction noms de domaine ↔ adresses IP |
| **Domaine (AD)** | Limite de sécurité/administration regroupant des objets AD |
| **Encapsulation** | Principe d'imbrication des protocoles réseau, couche par couche (« poupées russes ») |
| **Ethernet** | Protocole de couche 2 (norme IEEE 802.3), standard des réseaux locaux filaires |
| **FCS** | Champ de contrôle d'erreur en fin de trame Ethernet |
| **Firewall (pare-feu)** | Équipement/logiciel filtrant le trafic réseau selon des règles |
| **Forêt (AD)** | Regroupement de domaines partageant schéma et configuration |
| **GPO** | Règles de configuration appliquées automatiquement dans un domaine |
| **Gateway (passerelle)** | Point de sortie du réseau local vers d'autres réseaux |
| **gMSA** | Compte de service AD à mot de passe géré automatiquement |
| **Groupe (AD)** | Ensemble de comptes pour attribuer des droits collectivement |
| **Hôte (host)** | Un appareil identifié individuellement sur un réseau |
| **Hyperviseur** | Logiciel créant/gérant des machines virtuelles |
| **Interface réseau** | Port physique, virtuel (agrégat) ou sous-interface permettant de communiquer sur le réseau |
| **IPv4 / IPv6** | Versions du protocole d'adressage IP (32 bits / 128 bits) |
| **Kerberos** | Protocole d'authentification par ticket, standard dans un domaine AD |
| **LAN** | Réseau local |
| **LDAP** | Protocole d'interrogation d'un annuaire comme Active Directory |
| **LLC (Logical Link Control)** | Sous-couche « supérieure » de la couche 2 OSI, fiabilise et interface les protocoles |
| **Masque de sous-réseau** | Définit la partie réseau vs partie hôte d'une adresse IP |
| **Modèle OSI** | Modèle théorique en 7 couches décrivant la circulation des données sur un réseau |
| **Modèle TCP/IP** | Modèle pratique en 4 couches, préféré des constructeurs |
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
| **Sous-interface** | Interface physique découpée en plusieurs interfaces virtuelles |
| **Switch** | Équipement reliant des appareils d'un même réseau local |
| **TCP / UDP** | Protocoles de transport (fiable / rapide sans garantie) |
| **Trame Ethernet** | Unité de données de la couche 2 (préambule, adresses MAC, type, charge utile, FCS) |
| **VHD / VHDX** | Format de disque dur virtuel (Hyper-V) |
| **Virtualisation** | Exécution de plusieurs OS indépendants sur un même matériel physique |
| **VLAN** | Segmentation logique d'un réseau physique |
| **VM (Machine virtuelle)** | Ordinateur simulé par un hyperviseur |
| **WAN** | Réseau étendu reliant des sites distants |

---

## Pour relier tout ça à la pratique

Ce vocabulaire n'est pas théorique — c'est exactement ce que tu manipules dans tes labs : un serveur DHCP (Kea) qui distribue des IP sur un sous-réseau `/24`, une forêt Active Directory (`lab.local`) avec ses OU et ses gMSA, un cluster de basculement pour SQL Server, une VM Hyper-V branchée sur un commutateur virtuel. Chaque terme de ce glossaire correspond à une commande ou un écran que tu as déjà manipulé.
