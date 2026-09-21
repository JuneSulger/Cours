# Travail Dirigé Cisco — Connectivité de Base avec un Switch

**Date :** 08/09/23
**Intervenant :** Cédric Surquin
**Réalisé par :** June Sultan-Gerej
**Logiciel utilisé :** Cisco Packet Tracer

---

## Topologie

```
SW1 (Fa0/6) <---- Câble Console ----> PC-A
SW1 (Fa0/6) <---- Câble Ethernet ---> PC-A
```

| Appareils | Interfaces  | Adresses IP    | Passerelle par défaut |
|-----------|-------------|-----------------|------------------------|
| S1        | VLAN99      | 192.168.1.2/24  | 192.168.1.1            |
| PC-A      | FastEthernet| 192.168.1.10/24 | 192.168.1.1            |

---

## Partie 1 : Câblage du réseau et vérification de la config par défaut

### Étape 1 : Câblage

- Câble console entre SW1 et PC-A (simulé dans Packet Tracer via double-clic sur le switch → onglet **CLI**).

**Pourquoi utiliser une connexion console pour la configuration initiale du switch ?**
> Parce que le switch n'a aucune adresse IP configurée par défaut, donc aucune connexion réseau (Telnet/SSH) n'est possible. Seul un accès physique via le port console fonctionne.

**Pourquoi n'est-il pas possible de se connecter au switch par Telnet ou SSH ?**
> Même raison : pas d'IP configurée, et Telnet/SSH nécessitent une configuration préalable (mots de passe, IP) qui n'existe pas encore.

### Étape 2 : Vérification de la configuration par défaut

```
Switch> enable
Switch#
```

#### `show running-config`
- Interfaces **FastEthernet** : **24** (Fa0/1 à Fa0/24)
- Interfaces **GigabitEthernet** : **2** (Gig0/1, Gig0/2)
- Plage des lignes **VTY** : `line vty 0 4` (5 lignes, 0 à 4)

#### `show startup-config`
```
startup-config is not present
```
**Pourquoi ce message apparaît-il ?**
> Parce que la configuration en cours (running-config, en RAM) n'a jamais été sauvegardée dans la NVRAM (startup-config). Sur un switch neuf ou réinitialisé, ce fichier n'existe pas.

#### `show interface vlan1` (avant câblage Ethernet)
- Adresse IP attribuée au VLAN 1 ? **Non**
- Adresse MAC de l'interface SVI : `0006.2a60.11e5`
- L'interface fonctionne-t-elle ? **Non** (`administratively down, line protocol is down`)

#### `show interface vlan1` (après câblage Ethernet sur Fa0/6)
> Résultat identique : toujours `administratively down`. Le simple branchement d'un câble ne suffit pas à activer l'interface SVI (il faut `no shutdown` + au moins un port assigné au VLAN).

#### `show version`
- Version Cisco IOS : **15.0(2)SE4**
- Nom du fichier image système : `flash:c2960-lanbasek9-mz.150-2.SE4.bin`
- Adresse MAC de base du switch : `00:06:2A:60:11:E5`

#### `show interface f0/6`
- Interface activée ou désactivée ? **Activée** (`up, line protocol is up (connected)`)
- Quel évènement pourrait l'activer ? Le branchement d'un câble Ethernet valide avec un appareil actif à l'autre bout (par défaut, un port physique n'est pas en `shutdown`)
- Adresse MAC de l'interface : `0001.c9e7.8606`
- Vitesse / duplex : **Full-duplex, 100Mb/s**

#### `show vlan`
- Nom par défaut du VLAN 1 : **default**
- Ports dans ce VLAN : **tous** (Fa0/1 à Fa0/24, Gig0/1, Gig0/2)
- VLAN 1 actif ? **Oui**
- Type de VLAN par défaut : **enet** (Ethernet)

#### `show flash` / `dir flash:`
- Nom de l'image Cisco IOS : `2960-lanbasek9-mz.150-2.SE4.bin`

---

## Partie 2 : Configuration des paramètres de base

### Étape 1 : Paramètres de base du switch

```
Switch> enable
Switch# configure terminal
Switch(config)# hostname S1
S1(config)# service password-encryption
S1(config)# enable secret class
S1(config)# no ip domain-lookup
S1(config)# banner motd #
Unauthorized access is strictly prohibited.#
```

**Vérification en changeant de mode :**
```
S1(config)# exit
S1# exit
```
→ La bannière s'affiche bien au retour au prompt.

**Quelles touches de raccourci pour passer directement du mode configuration globale au mode privilégié ?**
> **Ctrl+Z**

```
S1> enable
Password: class
S1#
```

### Configuration de l'adresse IP de gestion (VLAN 99)

```
S1# configure terminal
S1(config)# vlan 99
S1(config-vlan)# exit
S1(config)# interface vlan99
S1(config-if)# ip address 192.168.1.2 255.255.255.0
S1(config-if)# no shutdown
S1(config-if)# exit
```

> Note : l'interface VLAN 99 reste "down" tant qu'aucun port physique ne lui est assigné.

### Attribution des ports au VLAN 99

```
S1(config)# interface range f0/1 - 24, g0/1 - 2
S1(config-if-range)# switchport access vlan 99
S1(config-if-range)# exit
```

**Vérification :**
```
S1# show vlan brief
```
- VLAN 1 (default) : actif, **aucun port**
- VLAN 99 (VLAN0099) : actif, **tous les ports** (Fa0/1-24, Gig0/1-2)

### Passerelle par défaut

```
S1(config)# ip default-gateway 192.168.1.1
```

### Sécurisation de l'accès console

```
S1(config)# line con 0
S1(config-line)# password cisco
S1(config-line)# login
S1(config-line)# logging synchronous
S1(config-line)# exit
```

### Accès Telnet (lignes VTY)

```
S1(config)# line vty 0 15
S1(config-line)# password cisco
S1(config-line)# login
S1(config-line)# end
```

**Pourquoi la commande `login` est-elle requise ?**
> Sans `login`, même avec un mot de passe configuré (`password cisco`), le switch n'exigera jamais ce mot de passe à la connexion — `login` active la vérification du mot de passe pour cette ligne.

### Étape 3 : Configuration IP de PC-A

| Paramètre        | Valeur          |
|-------------------|-----------------|
| Adresse IP         | 192.168.1.10    |
| Masque de sous-réseau | 255.255.255.0 |
| Passerelle par défaut | 192.168.1.1  |

---

## Partie 3 : Vérification et test de la connectivité réseau

### Étape 1 : Affichage de la configuration

```
S1# show run
```
Configuration vérifiée conforme : hostname, enable secret chiffré, service password-encryption, no ip domain-lookup, bannière MOTD, VLAN 99 avec IP, passerelle, ports assignés au VLAN 99, lignes con/vty sécurisées.

### `show interface vlan 99`

- Bande passante (BW) : **100000 Kbit** (100 Mbit/s)
- État du VLAN 99 : **up, line protocol is up**

### Étape 4 : Tests de connectivité (ping)

Depuis PC-A :
```
C:\> ping 192.168.1.10
```
→ 4/4 réussis (0% perte)

```
C:\> ping 192.168.1.2
```
→ 3/4 réussis, 1er paquet en `Request timed out` (normal : résolution ARP nécessaire avant le premier échange), les suivants réussissent.

### Étape 5 : Test Telnet

```
C:\> telnet 192.168.1.2
```
Mot de passe `cisco` demandé → accès au mode utilisateur.
```
S1> enable
Password: class
S1# exit
```

### Étape 6 : Sauvegarde de la configuration

```
S1# copy running-config startup-config
Destination filename [startup-config]? [Entrée]
Building configuration...
[OK]
```

---

## Partie 4 : Gestion de la table des adresses MAC

### Étape 1 : Adresse MAC de PC-A

```
C:\> ipconfig /all
```
Adresse physique relevée par le PC : `00D0.9720.E2EC`

### Étape 7 : Adresses MAC apprises par le switch

```
S1# show mac address-table
```
Résultat :
```
Vlan  Mac Address     Type      Ports
99    0050.0f81.2c5a  DYNAMIC   Fa0/6
```
- Adresses dynamiques : **1**
- Adresses MAC au total : **1**
- L'adresse dynamique correspond-elle à PC-A ? Oui dans l'esprit (unique adresse apprise sur le port relié à PC-A), bien qu'un léger écart ait été observé avec l'adresse relevée par `ipconfig` — comportement propre à la simulation Packet Tracer.

### Étape 8 : Options de `show mac address-table`

```
S1# show mac address-table ?
```
**4 options** : `dynamic`, `interfaces`, `static`, `<cr>`

```
S1# show mac address-table dynamic
```
→ 1 adresse dynamique (`0050.0f81.2c5a`, Fa0/6, VLAN 99)

### Étape 9 : Adresse MAC statique

**a. Effacer la table dynamique :**
```
S1# clear mac address-table dynamic
S1# show mac address-table
```
→ 0 adresse statique, 0 adresse dynamique

**e. Ré-génération de l'entrée (après ping) :**
```
S1# show mac address-table
```
→ 1 adresse dynamique réapparaît (le switch a réappris via le trafic généré par PC-A)

**f. Configuration de l'adresse MAC statique :**
```
S1(config)# mac address-table static 0050.0f81.2c5a vlan 99 interface fastethernet 0/6
```

**g. Vérification :**
```
S1# show mac address-table
```
→ Total : **1** adresse MAC, dont **1** statique

**h. Suppression de l'entrée statique :**
```
S1(config)# no mac address-table static 0050.0f81.2c5a vlan 99 interface fastethernet 0/6
```

**i. Vérification finale :**
```
S1# show mac address-table
```
→ **0** adresse statique

---

## Remarques générales

**1. Pourquoi devez-vous configurer les lignes vty du switch ?**
> Sans mot de passe configuré (et `login` activé) sur les lignes VTY, le switch refuse toute connexion à distance en Telnet ou SSH — c'est la sécurité minimale pour permettre la gestion à distance tout en empêchant un accès non autorisé.

**2. Pourquoi modifier le VLAN 1 par défaut à un autre numéro de VLAN ?**
> Pour des raisons de sécurité : le VLAN 1 est connu par défaut sur tous les switches Cisco, ce qui en fait une cible facile pour des attaques (VLAN hopping, etc.). Utiliser un VLAN de gestion différent (ici 99) rend le réseau moins prévisible et plus difficile à attaquer.

**3. Comment empêcher l'envoi des mots de passe en texte clair ?**
> En utilisant SSH plutôt que Telnet (SSH chiffre toute la communication), et en activant `service password-encryption` pour que les mots de passe ne soient pas visibles en clair dans le fichier de configuration.

**4. Pourquoi configurer une adresse MAC statique sur une interface de port ?**
> Pour restreindre quel appareil peut se connecter à un port donné — ça renforce la sécurité physique du réseau en empêchant qu'un appareil non autorisé (avec une autre adresse MAC) soit branché sur ce port et accède au réseau.

---

## Annexe A : Initialisation et redémarrage d'un switch

```
Switch> enable
Switch# show flash
```
→ Vérifie la présence d'un fichier `vlan.dat` dans la mémoire flash.

**Suppression du fichier vlan.dat (si présent) :**
```
Switch# delete vlan.dat
Delete filename [vlan.dat]? [Entrée]
Delete flash:/vlan.dat? [confirm] [Entrée]
```

**Suppression de la configuration de démarrage :**
```
Switch# erase startup-config
Erasing the nvram filesystem will remove all configuration files! Continue? [confirm]
[OK]
Erase of nvram: complete
```

**Redémarrage :**
```
Switch# reload
Proceed with reload? [confirm]
System configuration has been modified. Save? [yes/no]: no
```

**À l'issue du redémarrage :**
```
Would you like to enter the initial configuration dialog? [yes/no]: no
```

> Le switch revient ainsi à sa configuration d'usine, prêt pour un nouveau TP.

---

## Annexe théorique : Les bases de Cisco IOS

*Support de cours — Cédric Surquin*

### Objectifs
- Comprendre les commandes de base de Cisco IOS
- Comprendre les différents modes d'utilisation
- Savoir sauvegarder sa configuration
- Savoir remettre un appareil en configuration de sortie d'usine

### Cisco IOS : les bases

**Système d'exploitation intégré propriétaire**
- Stocké sous forme d'image binaire au format `.bin`
- Dans la mémoire flash de l'appareil
- Peut et **DEVRAIT** être mis à jour dès que possible !

**Sa configuration par défaut :**
- Est stockée dans une autre mémoire, la **NVRAM**
- Est sous forme de **fichier texte**
- Peut être modifiée, et ses modifications supprimées
- Peut être importée via un serveur **TFTP**

### Séquence de démarrage

1. **Mise sous tension** → lecture de la ROM et exécution du micro-logiciel de la carte mère
2. **BootStrap** (micro-logiciel) → teste le matériel
3. Recherche d'une image Cisco IOS dans la mémoire **Flash**
4. La Flash **décompresse** l'image IOS et la place en **RAM**
5. Cisco IOS (système d'exploitation) **lit le fichier de configuration** à appliquer au démarrage depuis la **NVRAM**
6. **Système prêt !**

### Les 4 niveaux de privilèges dans IOS

| Niveau | Prompt              | Description                              |
|--------|----------------------|-------------------------------------------|
| 1      | `Switch1>`           | User EXEC — le moins privilégié           |
| 2      | `Switch1#`            | Privileged EXEC Mode                      |
| 3      | `Switch1(config)#`    | Global Configuration                      |
| 4      | `Switch1(config-if)#` | Interface / Lines / Routage (sous-modes)  |

**Chaque niveau :**
- Donne accès à des commandes supplémentaires aux conséquences plus importantes
- Certaines commandes ne peuvent être utilisées qu'à un niveau spécifique

**Astuce :** pour connaître les commandes disponibles à un niveau, taper `?`, quel que soit le niveau actuel.

**Passer d'un niveau à l'autre :**
- Niveau 1 → 2 : `enable`
- Niveau 2 → 3 : `conf t`
- Niveau 3 → 4 : `interface` / `line` / `router` (selon le sous-mode voulu)

**Redescendre d'un niveau :** commande `exit`

### Commandes essentielles

| Action                                  | Commande                              |
|-------------------------------------------|-----------------------------------------|
| Voir la configuration actuelle             | `SW1# show running-config`             |
| Sauvegarder la configuration actuelle      | `SW1# copy running-config startup-config` |
| Redémarrer immédiatement l'appareil        | `SW1# reload`                          |

### Cisco IOS... au pluriel ?

| Variante  | Description                                                                                   |
|-----------|--------------------------------------------------------------------------------------------------|
| **IOS**     | Le Cisco IOS « Traditionnel », d'origine                                                       |
| **IOS-XE**  | Cisco IOS partiellement réécrit, tournant sur plateforme Linux. Chaque service/protocole tourne dans un processus séparé du noyau |
| **IOS-XR**  | Réécriture majeure de Cisco IOS, basé sur QNX. Adapté aux très gros environnements ; les changements de config ne s'appliquent plus en temps réel |

### Cisco IOS : les éditions (licences)

| Édition                  | Description |
|----------------------------|-------------|
| **LAN Base**                | Système basique, fonctionnalités de switching et technologies de base pour réseaux locaux. Utilisé principalement dans les switchs Catalyst (ex : Cisco Catalyst 2960) |
| **IP Base**                 | Toutes les fonctionnalités de LAN Base + routage IP de base. Utilisé dès les routeurs Cisco 2900 Series |
| **Advanced IP Services**    | Toutes les fonctionnalités d'IP Base + routage/gestion avancés. Utilisé dès les routeurs Cisco 3700 Series |
| **Enterprise Services**     | Adapté aux grandes entreprises : intégration sécurité/authentification (Cisco ISE), virtualisation réseau via VRF, scalabilité supérieure |
| **Security**                | VPN IPsec, VPN SSL, gestion des clés et certificats |
| **Service Provider**        | Ciblé télécoms : MPLS, VPN MPLS, QoS avancée, routage BGP, réseaux optiques passifs |

### La gestion des licences

- On peut passer d'une édition à une édition plus avancée
- Via l'achat d'une licence supplémentaire
- Ou la mise à niveau du contrat de maintenance

**SMARTnet** : nom du contrat de support & maintenance de Cisco, incluant :
- Mises à jour logicielles
- Correctifs de sécurité
- Nouvelles versions majeures du système d'exploitation (selon le type de contrat)

> Pour des besoins spécifiques, consulter Cisco directement ou un revendeur agréé reste la meilleure source d'informations sur les licences nécessaires et les coûts associés.

### Cycle de vie des systèmes Cisco

| Phase                     | Durée                                             | Contenu |
|------------------------------|-----------------------------------------------------|---------|
| **Mainstream Support**       | 5 à 7 ans                                            | Correctifs de sécurité + correctifs de bogues |
| **Extended Support**         | 2 à 3 ans supplémentaires après la fin du mainstream | Correctifs de sécurité critiques + bogues majeurs seulement |
| **End of Sale (EOS)**        | Point où Cisco cesse de vendre le logiciel, mais continue le support pendant la phase étendue | — |
| **End of Life (EOL)**        | Plus aucune mise à jour, l'équipement DOIT être remplacé | — |

### À noter — Limites de Packet Tracer

- Les exercices de cette formation sont réalisés dans **Cisco Packet Tracer**
- Packet Tracer a ses limites :
  - Certaines commandes `show` complexes et les commandes `debug` n'y fonctionnent **PAS**
  - Les éditions IOS proposées y sont plutôt basiques
  - Il lui arrive de **planter** → sauvegarder régulièrement son travail

---

*Fin du compte-rendu.*
