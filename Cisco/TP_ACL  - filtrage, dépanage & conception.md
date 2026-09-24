# Cisco – ACL étendues : filtrage, dépannage et conception

> Formation Système & Réseau – Technocité
> Environnement : **Cisco Packet Tracer**
> Suite de la fiche `TD_ACL_Securisation_VTY.md` (ACL standard sur les lignes vty)

---

## Sommaire

- [Rappels : ACL étendues](#rappels--acl-étendues)
- [TP 12.3 – Filtrer le trafic avec des ACL](#tp-123--filtrer-le-trafic-avec-des-acl)
  - [Tâche 1 – Configurer une ACL étendue](#tâche-1--configurer-une-acl-étendue)
  - [Tâche 2 – Dépanner une ACL](#tâche-2--dépanner-une-acl)
- [TP 12.4 – Dépannage de connectivité IP](#tp-124--dépannage-de-connectivité-ip)
  - [Tâche 1 – Route par défaut](#tâche-1--dépanner-une-route-par-défaut)
  - [Tâche 2 – ACL](#tâche-2--dépanner-une-acl-1)
  - [Tâche 3 – Passerelle par défaut et résolution de noms](#tâche-3--passerelle-par-défaut-et-résolution-de-noms)
  - [Enquête supplémentaire – Telnet de bout en bout](#enquête-supplémentaire--le-telnet-de-bout-en-bout)
- [TP 12.5 – Établir des ACL étendues (sans fichier fourni)](#tp-125--établir-des-acl-étendues-sans-fichier-fourni)
- [Leçons transversales](#leçons-transversales)
- [Aide-mémoire](#aide-mémoire)

---

## Rappels : ACL étendues

### Standard vs étendue

| | ACL standard | ACL étendue |
|---|---|---|
| Critères | Adresse **source** uniquement | Source, **destination**, **protocole**, **ports** |
| Numéros | 1-99, 1300-1999 | 100-199, 2000-2699 |
| Mode de config nommée | `(config-std-nacl)#` | `(config-ext-nacl)#` |
| Placement | Au plus près de la **destination** | Au plus près de la **source** |

### Structure d'une règle étendue

```
action  protocole  SOURCE  DESTINATION  [opérateur port]
permit  tcp        host 10.1.1.101  host 172.16.1.100  eq telnet
```

- **action** : `permit` ou `deny`
- **protocole** : `ip` (tout), `tcp`, `udp`, `icmp`, ou un numéro de protocole
- **source / destination** : `host A.B.C.D`, `A.B.C.D wildcard`, ou `any`
- **port** : placé **après la destination**, c'est le port du **service visé** (le port du client est aléatoire, on ne le filtre pas)

### Ports et mots-clés utiles

| Service | Port | Mot-clé IOS |
|---|---|---|
| FTP | TCP 21 | `ftp` |
| SSH | TCP 22 | `22` |
| Telnet | TCP 23 | `telnet` |
| HTTP | TCP 80 | `www` (et non `http`) |

IOS affiche toujours le nom quand il existe : `eq 23` apparaît `eq telnet`, `eq 80` apparaît `eq www`.

**Types ICMP** : `echo` (requête de ping), `echo-reply` (réponse de ping).

### Trois principes toujours valables

1. Lecture **séquentielle**, de haut en bas.
2. **Première correspondance** : l'action est appliquée, la suite n'est pas lue.
3. **`deny` implicite** en fin de liste, invisible et sans compteur.

### Appliquer sur une interface

```
interface GigabitEthernet0/0
 ip access-group NOM in|out
```
- `in` : paquets qui **entrent** dans le routeur par cette interface
- `out` : paquets qui **sortent** du routeur par cette interface
- Le sens se raisonne **du point de vue du routeur**, en suivant le trajet du paquet à filtrer.
- Une ACL **en sortie** ne filtre pas le trafic **généré par le routeur lui-même**.
- Une ACL **en entrée** filtre aussi les paquets **destinés au routeur** (ping vers sa passerelle, Telnet vers lui...).

---

## TP 12.3 – Filtrer le trafic avec des ACL

### Objectif

Configurer une ACL étendue nommée qui bloque le Telnet de PC2 vers le serveur, puis dépanner une ACL mal configurée.

### Topologie

```
PC1 (10.1.1.100) ── Fa0/1 ┐
                          SW1 (10.1.1.11) ── Fa0/13 ── Gi0/0 [Branch] Gi0/1 ── Internet ── Gi0/1 [HQ] Loopback0
PC2 (10.1.1.101) ── Fa0/3 ┘                            10.1.1.1   209.165.201.1           209.165.201.2   172.16.1.100
```

| Appareil | Interface | Adresse |
|---|---|---|
| Branch (2901) | Gi0/0 | 10.1.1.1/24 |
| Branch | Gi0/1 | 209.165.201.1/27 |
| HQ (2901) | Gi0/1 | 209.165.201.2/27 |
| HQ | Loopback0 | 172.16.1.100/24 |
| SW1 | VLAN 1 | 10.1.1.11/24 |
| PC1 | NIC | 10.1.1.100/24 |
| PC2 | NIC | 10.1.1.101/24 |

**Points à savoir sur l'énoncé :**
- Le « serveur » est l'interface **Loopback0 du routeur HQ**. Un Telnet réussi vers 172.16.1.100 aboutit donc sur l'invite de **HQ**.
- L'étiquette « VLAN 1 : 10.1.1.1 » près de Branch est une erreur : 10.1.1.1 est l'adresse de **Gi0/0**.
- La « visualisation des objectifs » montre un switch SW2 qui n'existe pas dans la topologie réelle.
- Sur un 2901, les interfaces s'appellent `Gi0/0` et `Gi0/1` (deux chiffres, contrairement au 4331 et ses `Gi0/0/0`).

### Accès aux équipements

Les routeurs du fichier fourni demandent un **`Username:`** : ils utilisent des comptes locaux (`login local`) et non un simple mot de passe de ligne. Si les identifiants ne sont pas fournis :
1. Les demander au formateur (solution normale).
2. Essayer les combinaisons classiques de labo, sans s'acharner.
3. Exporter la running-config via l'onglet **Config → Global → Settings** de Packet Tracer et chercher la ligne `username` (lisible si le mot de passe est en `password 0` ou `password 7`, pas en `secret`).
4. En dernier recours, la procédure de récupération de mot de passe.

### État des lieux initial

```
Branch> show ip interface brief
Branch> show ip interface g0/0
Branch# show access-lists
```

**Observations :**
- Gi0/0 up/up en 10.1.1.1 ; Gi0/1 up/up en 209.165.201.1, méthode **DHCP** (adresse obtenue automatiquement, conforme à l'énoncé, sans impact sur l'ACL).
- `Outgoing access list is not set` / `Inbound access list is not set` : aucune ACL appliquée sur Gi0/0 → fichier dans l'état de départ de la tâche 1.
- `show access-lists` ne fonctionne **pas en mode utilisateur** (`Branch>`) : il faut passer en mode privilégié avec `enable`. Ce n'est pas une limite de Packet Tracer.

---

### Tâche 1 – Configurer une ACL étendue

#### Étape 1 – Accéder à Branch

Onglet **CLI** de Branch, authentification, puis `enable` pour obtenir `Branch#`.

#### Étape 2 – Créer l'ACL `Telnet`

```
configure terminal
ip access-list extended Telnet
 deny tcp host 10.1.1.101 host 172.16.1.100 eq telnet
 permit ip any any
 exit
```

| Élément | Rôle |
|---|---|
| `ip access-list extended Telnet` | Crée l'ACL étendue nommée `Telnet` (nom sensible à la casse), invite `(config-ext-nacl)#` |
| `deny` | Refuser |
| `tcp` | Telnet fonctionne sur TCP |
| `host 10.1.1.101` | Source : uniquement PC2 |
| `host 172.16.1.100` | Destination : uniquement le serveur |
| `eq telnet` | Port de destination 23 (`eq 23` est équivalent) |
| `permit ip any any` | Autorise **tout le reste** du trafic IP |

**Pourquoi `permit ip any any` est indispensable :** sans lui, le `deny` implicite bloquerait tout ce qui ne correspond pas à la première règle : le Telnet de PC1, les pings, etc. L'énoncé exige que « tout autre trafic IP » passe.

**Pourquoi cet ordre :** la règle précise (`deny`) doit passer **avant** la règle générale (`permit ip any any`). Dans l'autre sens, le `permit` intercepterait tout, et le `deny` ne serait jamais lu.

La règle est précise : PC2 garde tout son accès réseau (ping compris), seul son Telnet vers ce serveur est bloqué. Une ACL standard, qui ne voit que la source, n'aurait pu que bloquer PC2 entièrement.

#### Étape 3 – Vérifier le contenu

```
Branch# show access-lists Telnet
Extended IP access list Telnet
deny tcp host 10.1.1.101 host 172.16.1.100 eq telnet
permit ip any any
```

- **Extended** : bon type d'ACL.
- Ordre correct.
- Cette version de Packet Tracer n'affiche pas les numéros de séquence (10, 20), mais ils existent en interne.
- Aucun compteur : l'ACL n'est encore appliquée nulle part.

#### Étape 4 – Appliquer sur Gi0/0 en entrée

```
configure terminal
interface GigabitEthernet0/0
 ip access-group Telnet in
end
```

**Pourquoi `in` :**
```
PC2 ──> SW1 ──> [Gi0/0  Branch  Gi0/1] ──> Internet ──> HQ
                  ▲                ▲
            le paquet ENTRE    le paquet SORT
```
Le Telnet de PC2 **arrive** sur Branch par Gi0/0 : c'est du trafic **entrant** sur cette interface.

Avec `out` sur Gi0/0, l'ACL ne verrait que les paquets qui **repartent** vers le LAN (les réponses du serveur, source 172.16.1.100 → destination 10.1.1.101). Ils ne correspondraient jamais à la règle `deny`, et le Telnet de PC2 passerait.

**Bonus du `in` :** le paquet est filtré avant que le routeur ne calcule sa route (placement « au plus près de la source »).

#### Étape 5 – Vérifier l'application

```
Branch# show ip interface GigabitEthernet0/0
...
Outgoing access list is not set
Inbound access list is Telnet
```
C'est la commande de référence pour savoir **où** et **dans quel sens** une ACL est appliquée. `show access-lists` ne montre que son contenu.

#### Étape 6 – Sauvegarder

```
Branch# copy running-config startup-config
```
Entrée à la question du nom de fichier, puis `[OK]`. Penser aussi à enregistrer le `.pkt` (Ctrl+S) : les deux sauvegardes sont indépendantes.

#### Étape 7 – Telnet depuis PC1 (doit réussir)

```
C:\> telnet 172.16.1.100
```
→ authentification, puis invite **HQ**. ✅

Évaluation par l'ACL :
- Règle 1 : source 10.1.1.100 ≠ 10.1.1.101 → pas de correspondance.
- Règle 2 : `permit ip any any` → autorisé.

#### Étape 8 – Compteurs après le test de PC1

```
deny tcp host 10.1.1.101 host 172.16.1.100 eq telnet
permit ip any any (37 match(es))
```
**37 correspondances** (10 dans l'énoncé) pour une seule connexion.

**Pourquoi autant ?** Une ACL d'**interface** examine **chaque paquet** qui entre : l'établissement TCP, chaque frappe de clavier (identifiant, mot de passe, commandes), la fermeture... Au TD précédent, l'ACL sur les **lignes vty** n'était consultée qu'à l'établissement de la session (2 correspondances). Plus la session dure, plus le compteur monte.

#### Étape 9 – Telnet depuis PC2 (doit échouer)

```
C:\> telnet 172.16.1.100
Trying 172.16.1.100 ...
(attente, puis délai dépassé)
```
Et en complément :
```
C:\> ping 172.16.1.100   → ✅ passe
```
Seul le TCP port 23 est visé : PC2 garde le reste de son accès.

**Pourquoi un délai dépassé et pas un refus immédiat comme au TD vty ?**
- **TD vty** : la connexion visait le **routeur lui-même**. Il consultait son ACL vty et répondait activement « refusé » → `Connection refused` immédiat.
- **Ici** : la connexion vise le **serveur**, Branch n'est qu'un routeur de passage. Il supprime le paquet à l'entrée de Gi0/0 : HQ ne reçoit jamais la demande et ne répond donc jamais. Un routeur peut envoyer un message ICMP d'erreur à l'émetteur, mais le client Telnet attend une réponse TCP : faute de la recevoir, il **retransmet** sa demande plusieurs fois, puis abandonne.

#### Étape 10 – Compteurs après le test de PC2

```
deny tcp host 10.1.1.101 host 172.16.1.100 eq telnet (12 match(es))
permit ip any any (41 match(es))
```
- **`deny` : 12** → les demandes de connexion de PC2 et leurs **retransmissions** TCP.
- **`permit` : 37 + 4 = 41** → les 4 requêtes ICMP du ping de PC2. Les réponses ne comptent pas : elles entrent par Gi0/1 et sortent par Gi0/0, sens sans ACL.

> ⚠️ **Piège rencontré :** une première lecture des compteurs n'affichait aucun changement (deny vide, permit bloqué à 37). La commande avait été lancée **avant** que les tests ne soient comptabilisés. Relancer la commande a donné les bons chiffres. Avant de conclure à une anomalie, **relancer la vérification**.

---

### Tâche 2 – Dépanner une ACL

Pour travailler sur le même fichier, on a d'abord sauvegardé une copie (`File → Save As`, ex. `12_3_2_tache1_OK.pkt`), puis injecté une configuration volontairement erronée, pour simuler l'ACL « d'un collègue ».

#### Injection de la config cassée

```
configure terminal
interface GigabitEthernet0/0
 no ip access-group Telnet in
 exit
no ip access-list extended Telnet
ip access-list extended Telnet
 deny tcp host 172.16.1.100 host 10.1.1.101 eq telnet
 permit ip any any
 exit
interface GigabitEthernet0/0
 ip access-group Telnet out
end
clear access-list counters Telnet
```
Pas de sauvegarde à ce stade : c'est la config **corrigée** qui sera sauvegardée à l'étape 7.

#### Étape 1 – Constater le problème

```
C:\> telnet 192.16.1.100
% Connection timed out; remote host not responding
```
→ **faute de frappe** (192 au lieu de 172). Adresse inexistante, donc délai dépassé.

> 💡 **Réflexe de dépannage :** avant de soupçonner une ACL, relire l'adresse tapée. Un timeout peut venir d'un filtrage, mais aussi d'une adresse erronée ou d'un problème de routage.

```
C:\> telnet 172.16.1.100
```
→ invite **HQ#** : le Telnet de PC2 **fonctionne** malgré l'ACL censée le bloquer. Problème reproduit.

#### Étapes 2 et 3 – Inspecter l'application

```
Branch# show ip interface GigabitEthernet0/0
Outgoing access list is Telnet
Inbound access list is not set
```

**Diagnostic :** l'ACL est en **sortie** sur Gi0/0. Le Telnet de PC2 **entre** par Gi0/0 et **sort** par Gi0/1 : il ne sort jamais par Gi0/0, donc l'ACL ne le voit pas. → **Erreur n°1 : mauvais sens d'application.**

#### Étape 4 – Corriger le sens

```
configure terminal
interface GigabitEthernet0/0
 no ip access-group Telnet out
 ip access-group Telnet in
end
```
- **`no ip access-group Telnet out` est indispensable** : taper seulement le `in` n'annule pas le `out`. Une interface peut porter une ACL dans chaque sens : on aurait la même ACL appliquée deux fois, une config confuse et source de blocages futurs.

Vérification : `Outgoing access list is not set` / `Inbound access list is Telnet`.

#### Étape 5 – Inspecter le contenu

**Test préalable :** Telnet depuis PC2 → **passe encore**. La correction du sens ne suffit pas : il y a une seconde erreur, dans les règles.

```
Branch# show access-lists Telnet
Extended IP access list Telnet
deny tcp host 172.16.1.100 host 10.1.1.101 eq telnet
permit ip any any (33 match(es))
```

| Élément | Dans la règle | Paquet de PC2 à bloquer |
|---|---|---|
| Protocole | `tcp` | TCP ✅ |
| Source | `host 172.16.1.100` (serveur) | **10.1.1.101** (PC2) ❌ |
| Destination | `host 10.1.1.101` (PC2) | **172.16.1.100** (serveur) ❌ |
| Port destination | `eq telnet` | 23 ✅ |

→ **Erreur n°2 : source et destination inversées.** La règle décrit un Telnet du serveur vers PC2. Le `deny` n'a aucune correspondance, alors que le `permit` compte la session de PC2 (33).

Même les réponses du serveur n'y correspondraient pas : leur source est bien 172.16.1.100, mais c'est leur port **source** qui vaut 23, alors que `eq telnet` à cet endroit vérifie le port de **destination**.

> 💡 **Méthode :** pour vérifier une règle, se placer à l'interface où l'ACL est appliquée, dans le sens où elle est appliquée, et se demander : « à quoi ressemble **ce paquet-là** à cet endroit ? ».

#### Étape 6 – Corriger la règle

```
configure terminal
ip access-list extended Telnet
 no deny tcp host 172.16.1.100 host 10.1.1.101 eq telnet
 5 deny tcp host 10.1.1.101 host 172.16.1.100 eq telnet
end
```
- **`no deny ...`** : supprime uniquement la règle fautive. L'ACL reste appliquée pendant la modification. (Avantage des ACL nommées : dans une ACL numérotée en syntaxe classique, `no access-list 100 ...` supprime toute l'ACL.)
- **`5 deny ...`** : recrée la règle dans le bon sens, avec le numéro **5**, inférieur au 20 du `permit`. Sans numéro, elle serait ajoutée **à la fin**, après le `permit ip any any`, et ne serait jamais atteinte.

Vérification :
```
deny tcp host 10.1.1.101 host 172.16.1.100 eq telnet (24 match(es))
permit ip any any (33 match(es))
```

**Pourquoi déjà 24 correspondances ?** Soit une nouvelle tentative de PC2 (avec retransmissions), soit la session Telnet sur HQ était restée ouverte : dès que la règle corrigée est en place, les paquets de la session existante sont bloqués à leur tour, et la session se fige. Une ACL de ce type n'a **aucune mémoire** des connexions déjà établies : elle examine chaque paquet indépendamment.

#### Étape 7 – Sauvegarder

```
Branch# copy running-config startup-config
```

#### Étape 8 – Test final

| Test | Résultat |
|---|---|
| Telnet PC2 → 172.16.1.100 | ❌ bloqué ✅ |
| Ping PC2 → 172.16.1.100 | ✅ |
| Telnet PC1 → 172.16.1.100 | ✅ |

| Erreur | Commande révélatrice | Correction |
|---|---|---|
| Mauvais sens (`out`) | `show ip interface Gi0/0` | `no ip access-group Telnet out` + `ip access-group Telnet in` |
| Source/destination inversées | `show access-lists Telnet` + deny à zéro | `no deny ...` + `5 deny ...` dans le bon sens |

---

> ### 📌 En résumé – TP 12.3
>
> **Ce qu'on a fait**
> - Créé une ACL **étendue** nommée qui bloque **un seul service** (Telnet), **d'une seule machine** (PC2) **vers une seule destination** (le serveur), en laissant passer tout le reste.
> - Appliqué cette ACL **en entrée** sur l'interface LAN du routeur, et vérifié son effet par des tests et des compteurs.
> - Dépanné une ACL volontairement cassée, qui cumulait **deux erreurs** : mauvais sens d'application et source/destination inversées.
>
> **À quoi ça sert**
> - Une ACL étendue permet un filtrage **chirurgical** : on interdit précisément un usage (ex. l'administration à distance d'un serveur depuis un poste non autorisé) sans couper le reste du réseau.
> - Le dépannage d'ACL est une compétence du quotidien : on hérite souvent de configurations écrites par d'autres, avec des erreurs qui ne se voient pas au premier coup d'œil.
>
> **Pourquoi c'est important**
> - Une ACL **mal placée** ou **mal écrite** ne produit aucune erreur : elle « fonctionne », mais ne filtre rien. Seuls les tests et les **compteurs** révèlent le problème.
> - Deux réflexes à garder : vérifier **où et dans quel sens** l'ACL est appliquée (`show ip interface`), puis lire chaque règle **du point de vue du paquet** tel que le routeur le voit à cet endroit.
> - Tester chaque correction **séparément** : c'est ce qui a révélé l'existence de la seconde erreur.

---

## TP 12.4 – Dépannage de connectivité IP

### Scénario

L'utilisateur du VLAN 10 (PC1) ne peut pas joindre le serveur 172.16.1.100 en Telnet ni en HTTP. L'énoncé prévoit **trois pannes** dans des domaines différents :

| Tâche | Panne | Où |
|---|---|---|
| 1 | Route par défaut manquante | Branch |
| 2 | ACL qui bloque Telnet et HTTP | Branch, Gi0/1 en sortie |
| 3 | Mauvaise passerelle par défaut | PC1 |

On remonte depuis le réseau (tests depuis SW1) vers l'utilisateur (PC1).

### Topologie

```
                    ┌── S0/0/0 (éteinte) ── WAN ── S0/0/0 ──┐
                 [Branch]                                  [HQ] ── Loopback0 = "serveur" 172.16.1.100
                    └── Gi0/1 ──── Internet ──── Gi0/1 ─────┘
                    Gi0/0      209.165.201.1   209.165.201.2
                  (trunk : sous-interfaces VLAN 1, 10, 20)
                      │
                  Fa0/13
PC1 (VLAN 10) ─ Fa0/1 [SW1] Fa0/3-4 ══ EtherChannel trunk ══ Fa0/3-4 [SW2] Fa0/1 ─ PC2 (VLAN 20)
```

| Appareil | Interface | Adresse |
|---|---|---|
| Branch | Gi0/0.1 (VLAN 1) | 10.1.1.1/24 |
| Branch | Gi0/0.10 (VLAN 10) | 10.1.10.1/24 |
| Branch | Gi0/0.20 (VLAN 20) | 10.1.20.1/24 |
| Branch | Gi0/1 | 209.165.201.1/27 |
| Branch | S0/0/0 (éteinte) | 192.168.1.1/24 |
| Branch | Loopback10 | 10.100.100.100/32 |
| HQ | Gi0/1 | 209.165.201.2/27 |
| HQ | S0/0/0 | 192.168.1.2/24 |
| HQ | Loopback0 | 172.16.1.100/24 |
| SW1 | VLAN 1 | 10.1.1.11/24 |
| SW2 | VLAN 1 | 10.1.1.12/24 |
| PC1 | NIC (VLAN 10) | **10.1.10.100/24**, passerelle 10.1.10.1 |
| PC2 | NIC (VLAN 20) | **10.1.20.100/24**, passerelle 10.1.20.1 |

> ⚠️ **Incohérence de l'énoncé :** le tableau donne PC1 en 10.1.1.100 et PC2 en 10.1.1.101, mais le schéma indique 10.1.10.100 et 10.1.20.100. **Le schéma a raison** : PC1 est dans le VLAN 10 (10.1.10.0/24), PC2 dans le VLAN 20 (10.1.20.0/24). La tâche 3 le confirme (passerelle 10.1.10.1).

### Notions nouvelles

**Router-on-a-stick.** Branch n'a qu'un câble vers le LAN (Gi0/0), mais sert trois VLANs grâce à des **sous-interfaces** (Gi0/0.1, .10, .20), une par VLAN, chacune avec son adresse. Le lien Gi0/0 ↔ SW1 est un **trunk** qui transporte les trois VLANs. Chaque sous-interface est la passerelle de son VLAN.

**OSPF et le lien série éteint.** Les réseaux annoncés par OSPF passent par le lien série 192.168.1.0/24, **éteint** pendant tout le TP. Le seul lien actif (Gi0/1, via Internet) n'est pas utilisé par OSPF côté Branch. Résultat : Branch n'apprend aucune route vers le serveur.

**Route par défaut.** Route `0.0.0.0/0`, utilisée quand aucune route plus précise ne correspond. Elle apparaît dans `show ip route` comme **Gateway of last resort**.

**Codes de `ping` et `traceroute` (Cisco) :**

| Commande | Code | Signification |
|---|---|---|
| ping | `!` | Réponse reçue |
| ping | `.` | Pas de réponse dans le délai |
| ping | `U` | Un routeur signale la destination injoignable |
| traceroute | `*` | Pas de réponse de ce saut |
| traceroute | `A` | Refusé administrativement (typiquement une ACL) |
| traceroute | `H` / `N` | Hôte / réseau injoignable |

`U`, `H` et `A` sont précieux : un routeur a **répondu activement** pour dire pourquoi il bloque, ce qui permet de le localiser.

---

### Tâche 1 – Dépanner une route par défaut

#### Étape 1 – Ping depuis SW1

```
SW1# ping 172.16.1.100
.....
Success rate is 0 percent (0/5)
```
Que des `.` (l'énoncé annonçait des `U`). Un `.` signifie seulement « pas de réponse » : le problème peut être à l'aller, au retour, ou dû à un filtrage. Il faut localiser.

#### Étape 2 – Localiser la panne

**Réflexe de méthode :** tester d'abord le premier saut.
```
SW1# ping 10.1.1.1
!!!!!
```
→ le lien SW1 ↔ Branch fonctionne.

```
SW1# traceroute 172.16.1.100
1 10.1.1.1 0 msec 0 msec 0 msec
2 10.1.1.1 !H * !H
3 * *
```
- **Saut 1** : Branch répond normalement.
- **Saut 2** : **encore Branch**, avec `!H` (host unreachable). Il ne transmet pas la sonde : « je ne sais pas joindre cette destination ».
- Le `*` entre les `!H` s'explique probablement par la **limitation de débit** des messages ICMP d'erreur (environ un toutes les 500 ms sur Cisco). C'est peut-être aussi pour ça que le ping affichait des `.` au lieu de `U`.

→ **La panne est sur Branch.** Deux causes possibles : interface de sortie hors service, ou route manquante.

Pour interrompre un traceroute qui s'éternise : **Ctrl+Shift+6**.

#### Étape 3 – Vérifier l'interface Gi0/1

```
Branch# show interfaces GigabitEthernet0/1
GigabitEthernet0/1 is up, line protocol is up (connected)
Internet address is 209.165.201.1/27
...
0 input errors, 0 CRC ...
0 packets output, 0 bytes
```
- up/up, bonne adresse, aucune erreur physique → l'interface fonctionne.
- **`0 packets output`** : Branch n'a **jamais rien envoyé** par Gi0/1, alors qu'il reçoit des paquets de HQ. Ce n'est pas l'interface qui refuse de transmettre : c'est le routeur qui ne choisit jamais de l'utiliser, faute de route.

#### Étape 4 – Examiner la table de routage

```
Branch# show ip route
Gateway of last resort is not set
C 10.1.1.0/24 ... GigabitEthernet0/0.1
C 10.1.10.0/24 ... GigabitEthernet0/0.10
C 10.1.20.0/24 ... GigabitEthernet0/0.20
C 209.165.201.0/27 ... GigabitEthernet0/1
(+ routes L)
```

| Code | Origine |
|---|---|
| `C` | Réseau directement connecté |
| `L` | Adresse locale de l'interface (/32) |
| `S` | Route statique |
| `S*` | Route statique par défaut |
| `O` | Route OSPF |

- **Pas de route par défaut**, aucune route `O`, **aucune route vers 172.16.1.0/24**.
- Branch reçoit un paquet pour 172.16.1.100, ne trouve aucune route, n'a pas de route par défaut → il le supprime et renvoie le `!H`.
- La Loopback10 (10.100.100.100/32) n'apparaît pas : probablement non configurée dans le fichier, sans rôle dans le TP.

#### Étape 5 – Ajouter la route par défaut

```
configure terminal
ip route 0.0.0.0 0.0.0.0 209.165.201.2
end
```

| Élément | Valeur | Rôle |
|---|---|---|
| Réseau | `0.0.0.0` | Toutes les destinations... |
| Masque | `0.0.0.0` | ...aucun bit ne doit correspondre |
| Prochain saut | `209.165.201.2` | HQ |

« Tout paquet sans route plus précise, envoie-le à HQ. » Le routeur choisit toujours la route **la plus précise** : les réseaux connectés restent prioritaires. Le prochain saut doit être dans un réseau directement connecté (209.165.201.2 est bien dans 209.165.201.0/27).

Vérification :
```
Gateway of last resort is 209.165.201.2 to network 0.0.0.0
S* 0.0.0.0/0 [1/0] via 209.165.201.2
```
`[1/0]` = distance administrative 1 (route statique) / métrique 0.

#### Validation – attention à l'équipement de test

```
Branch# ping 172.16.1.100
.!!!!
```
Ce test **ne suffit pas** : depuis Branch, le ping part avec la source **209.165.201.1**, un réseau directement connecté à HQ. HQ n'a besoin d'aucune route pour répondre. Seul l'**aller** est validé.

```
SW1# ping 172.16.1.100
!!!!!
```
Depuis SW1, la source est **10.1.1.11** : HQ doit savoir renvoyer vers le LAN de Branch. Ce test valide **l'aller et le retour** (HQ dispose d'une route par défaut vers Branch).

> 💡 **Piège rencontré :** le ping a d'abord été relancé deux fois dans la fenêtre de Branch. Dans Packet Tracer, chaque équipement a sa propre fenêtre CLI : **l'invite (`Branch#`, `SW1#`...) est le repère à vérifier avant chaque commande.**

Sauvegarde : `copy running-config startup-config` sur Branch.

---

### Tâche 2 – Dépanner une ACL

#### Étapes 1 et 2 – Tester les services depuis SW1

```
SW1# ping 172.16.1.100         → !!!!! ✅
SW1# telnet 172.16.1.100       → % Connection timed out ❌
SW1# telnet 172.16.100 80      → % Invalid input detected
```
- Le **timeout Telnet** alors que le ping passe est un vrai indice : les paquets TCP disparaissent en route.
- L'`Invalid input` vient d'une **faute de frappe** : adresse à trois octets (172.16.100). La commande correcte est `telnet 172.16.1.100 80`.
- **Pourquoi `telnet` sur le port 80 ?** Un switch n'a pas de navigateur. `telnet` peut ouvrir une connexion TCP vers **n'importe quel port** : c'est une astuce classique pour tester si un service TCP est joignable.

```
SW1# traceroute 172.16.1.100
1 10.1.1.1 ...
2 10.1.1.1 ...
...
30 10.1.1.1 ...
```
Sur un vrai routeur, on aurait un `!A` au saut 2. Packet Tracer ne l'affiche pas, mais toutes les sondes reçoivent une réponse de Branch, aucune ne va plus loin : Branch bloque.

**Pourquoi le traceroute échoue alors que le ping passe :** le `traceroute` Cisco envoie de l'**UDP** (ports à partir de 33434), pas de l'ICMP. Le `tracert` de Windows, lui, utilise de l'ICMP.

| Test | Protocole | Résultat |
|---|---|---|
| ping | ICMP | ✅ |
| traceroute | UDP | ❌ arrêté à Branch |
| telnet | TCP 23 | ❌ timeout |

→ La route fonctionne, mais seul l'ICMP passe : **filtrage par protocole sur Branch**, donc une ACL étendue.

> ⚠️ `show ip access-lists Outbound-ACL` lancé **sur SW1** n'affiche rien : l'ACL est sur Branch.

#### Étape 3 – Chercher l'ACL

```
Branch# show ip interface GigabitEthernet0/1
Outgoing access list is Outbound-ACL
Inbound access list is not set
```

**Ici, le sens n'est pas une erreur :**
```
SW1 ──> [Gi0/0.x  Branch  Gi0/1] ──> HQ
          ENTRÉE           SORTIE ← ACL
```
Tout le trafic du LAN vers l'extérieur **sort** par Gi0/1, quel que soit son VLAN. Une ACL en sortie filtre en un point unique tout ce qui quitte le site : placement classique pour une **politique de sortie**. Il ne suit pas la règle « au plus près de la source », mais couvre les trois VLANs avec une seule ACL.

**Nuance importante :** une ACL en `out` ne filtre pas le trafic **généré par le routeur lui-même**. Un test lancé depuis Branch n'aurait jamais révélé le blocage : il faut tester depuis le LAN.

#### Étape 4 – Examiner le contenu

```
Branch# show ip access-lists Outbound-ACL
Extended IP access list Outbound-ACL
permit icmp any any (5 match(es))
permit tcp any any eq ftp
```

| Règle | Autorise | Tests |
|---|---|---|
| `permit icmp any any` | Tout l'ICMP | 5 correspondances = ping de SW1 ✅ |
| `permit tcp any any eq ftp` | TCP 21 uniquement | Non utilisé |
| `deny` implicite | **Tout le reste** | Telnet, HTTP, traceroute UDP ❌ |

**Diagnostic :** l'ACL n'est pas « cassée », elle est **incomplète**. Telnet et HTTP tombent sur le `deny` implicite, qui n'a pas de compteur : les tentatives n'apparaissent nulle part.

**Deux remarques :**
- **Traceroute** : l'énoncé veut que PC1 puisse faire du traceroute. Le `tracert` Windows (ICMP) passera grâce à la première règle. Le `traceroute` Cisco (UDP) restera bloqué : l'énoncé ne demande pas d'ajouter l'UDP.
- **Portée `any any`** : l'énoncé dit que PC1 ne doit être autorisé **qu'**à ces services vers le serveur. Une ACL stricte utiliserait 10.1.10.0/24 et 172.16.1.100 au lieu de `any any`. Le TP simplifie ; en production, la question se poserait.

#### Étape 5 – Autoriser Telnet et HTTP

```
configure terminal
ip access-list extended Outbound-ACL
 permit tcp any any eq telnet
 permit tcp any any eq www
end
copy running-config startup-config
```
- `www` est le mot-clé IOS du port 80 (`eq 80` est équivalent).
- L'ACL reste appliquée pendant la modification : l'ICMP et le FTP ne sont jamais coupés.

**Pourquoi pas de numéro de séquence cette fois ?** L'ACL ne se termine par aucune règle générale explicite. Les nouvelles règles, ajoutées en fin de liste, se placent avant le `deny` implicite, qui reste toujours dernier.

> 💡 **La question à se poser à chaque ajout :** qu'y a-t-il **après** l'endroit où j'insère ? Si c'est une règle plus générale qui intercepterait mon trafic, il faut un numéro de séquence. Sinon, l'ajout en fin de liste suffit.

Vérification :
```
permit icmp any any (5 match(es))
permit tcp any any eq ftp
permit tcp any any eq telnet (14 match(es))
permit tcp any any eq www
```

#### Étape 6 – Retester

Le compteur Telnet montre que les paquets **traversent désormais l'ACL**. L'énoncé considère la tâche résolue. (La suite a montré qu'un compteur qui augmente ne prouve pas que la connexion aboutit : voir l'enquête supplémentaire.)

---

### Tâche 3 – Passerelle par défaut et résolution de noms

#### Étape 1 – Ping depuis PC1

```
C:\> ping 172.16.1.100   → 4/4 ✅
```
Résultat inattendu : l'énoncé annonçait un échec.

#### Étape 3 (anticipée) – Configuration de PC1

```
C:\> ipconfig
FastEthernet0 Connection:
IPv4 Address....: 10.1.10.100
Subnet Mask.....: 255.255.255.0
Default Gateway.: 10.1.10.1
```
→ PC1 est **correctement configuré** : la panne annoncée (passerelle en 10.1.10.10) n'est pas présente dans ce fichier. La section **Bluetooth Connection** en 0.0.0.0 est une interface que Packet Tracer ajoute aux PC, sans rôle ici.

**Ce qu'on aurait vu avec la panne :** avec une passerelle en 10.1.10.10, adresse inexistante, PC1 envoie tout le trafic hors de son réseau vers une passerelle qui ne répond pas → `Request timed out`, alors que le reste du réseau fonctionne. Correction dans **Desktop → IP Configuration**. Quand **un seul poste** n'arrive pas à sortir de son réseau alors que les autres y parviennent, la passerelle est le premier suspect.

#### Résolution de noms

```
C:\> ping Server
Ping request could not find host Server.
```
Pas de serveur DNS dans ce réseau. Sur un vrai PC, on ajouterait une ligne dans le fichier `hosts` (Windows : `C:\Windows\System32\drivers\etc\hosts`) :
```
172.16.1.100    Server
```
L'énoncé demande d'ignorer ce point dans Packet Tracer.

---

### Enquête supplémentaire – Le Telnet de bout en bout

Test final de la plainte de l'utilisateur :
```
C:\> telnet 172.16.1.100     (depuis PC1)
% Connection timed out; remote host not responding
```
Le Telnet échoue encore alors que le ping passe. Enquête menée par élimination.

#### 1. Les compteurs de Branch

```
10 permit icmp any any (9 match(es))
20 permit tcp any any eq ftp
30 permit tcp any any eq telnet (28 match(es))
40 permit tcp any any eq www
```
- **Une seule ACL** sur Branch : pas de filtrage caché sur Gi0/0.10.
- **ICMP : 5 → 9** = les 4 pings de PC1.
- **Telnet : 14 → 28** : les paquets de PC1 ont été **autorisés** et sont **sortis** par Gi0/1. Le blocage est **après** Branch.
- **14 correspondances pour SW1, 14 pour PC1** : le même schéma pour deux tentatives = demande initiale + **retransmissions** sans réponse. Le Telnet de SW1 n'avait donc probablement jamais abouti non plus.

> 💡 **Un compteur prouve que les paquets ont traversé l'ACL, pas qu'ils ont reçu une réponse.**

#### 2. HQ : ACL et interfaces

```
HQ# show ip interface GigabitEthernet0/1
Outgoing access list is not set
Inbound access list is not set
HQ# show ip access-lists
(rien)
```
→ Aucune ACL sur HQ.

#### 3. HQ : la configuration

```
username ccna privilege 15 password 0 cisco
...
ip route 0.0.0.0 0.0.0.0 209.165.201.1
...
line vty 0 4
 logging synchronous
 no login
```
- **`no login`** : aucune authentification sur les lignes vty. **Faille de sécurité** : quiconque atteint HQ en Telnet obtient une invite sans mot de passe.
- **`password 0 cisco`** + `no service password-encryption` : mot de passe **en clair** dans la config. Seconde faiblesse (il faudrait `secret`).
- **Route par défaut** vers Branch : explique que le ping fasse l'aller-retour.

#### 4. Test d'isolation : Telnet depuis Branch

```
Branch# telnet 172.16.1.100   → invite HQ ✅
```
Le trafic généré par Branch ne passe pas par l'ACL de sortie. **HQ accepte donc le Telnet** : ses lignes vty ne le bloquent pas dans ce cas.

#### 5. Test d'isolation : retrait temporaire de l'ACL

```
Branch(config)# interface GigabitEthernet0/1
Branch(config-if)# no ip access-group Outbound-ACL out
```
Telnet depuis PC1 → **échoue encore**. **L'ACL est innocente.** Remise en place immédiate :
```
Branch(config-if)# ip access-group Outbound-ACL out
```
> En production, retirer une ACL ouvre **tout** le trafic : à faire en fenêtre de maintenance, avec l'accord de l'équipe, et en limitant la durée.

#### 6. Correction des vty de HQ

```
HQ(config)# line vty 0 4
HQ(config-line)# login local
HQ(config-line)# transport input telnet
```
- `login local` : authentification avec les comptes locaux (ferme la faille `no login`).
- `transport input telnet` : autorise explicitement Telnet au lieu de dépendre d'une valeur par défaut variable.

Telnet depuis PC1 → **échoue encore**.

#### Bilan de l'enquête

| Test | Source | Traverse Outbound-ACL | Résultat |
|---|---|---|---|
| Telnet depuis Branch | 209.165.201.1 | Non | ✅ |
| Telnet depuis SW1 | 10.1.1.11 | Oui | ❌ |
| Telnet depuis PC1 | 10.1.10.100 | Oui | ❌ |
| Telnet depuis PC1, ACL retirée | 10.1.10.100 | Non | ❌ |
| Ping depuis PC1 | 10.1.10.100 | Oui | ✅ |

**Éliminé :** l'ACL de Branch, toute ACL sur HQ, le routage (le ping fait l'aller-retour), la configuration des vty de HQ.
**Non résolu :** le Telnet échoue depuis tout réseau distant de HQ, alors qu'il fonctionne depuis un réseau directement connecté. Comportement propre au fichier ou au simulateur.

**Pistes restantes :**
- **Mode Simulation** de Packet Tracer (onglets Realtime / Simulation en bas à droite de la fenêtre principale, ou **Shift+S**) : filtrer sur TCP et Telnet, avancer paquet par paquet, et ouvrir l'enveloppe là où le paquet s'arrête (onglet **OSI Model**) pour lire la raison exacte.
- Telnet de PC1 vers **209.165.201.2** (interface physique de HQ) au lieu de la Loopback0, pour savoir si le problème est lié à la loopback.
- **Escalade** : signaler au formateur, avec la liste de ce qui a été éliminé.

---

> ### 📌 En résumé – TP 12.4
>
> **Ce qu'on a fait**
> - Remonté une plainte utilisateur (« je n'ai pas accès au serveur en Telnet/HTTP ») en testant **couche par couche** et **saut par saut**, depuis le réseau vers le poste.
> - Trouvé et corrigé une **route par défaut manquante** (le lien OSPF étant hors service), puis complété une **ACL de sortie** qui n'autorisait que l'ICMP et le FTP.
> - Constaté que la panne de passerelle prévue n'existait pas dans le fichier, et abordé la résolution de noms (fichier `hosts`).
> - Mené une **enquête par élimination** sur un Telnet qui échouait encore, en isolant chaque composant (ACL, HQ, vty, routage).
>
> **À quoi ça sert**
> - Dans la réalité, un utilisateur ne dit jamais « il manque une route par défaut » : il dit « ça ne marche pas ». Savoir enchaîner `ping`, `traceroute`, `show interfaces`, `show ip route`, `show ip interface` et `show access-lists` permet de passer du symptôme à la cause.
> - Les codes (`!H`, `U`, `A`, `.`) et les compteurs d'ACL disent **où** le trafic s'arrête et **pourquoi**.
>
> **Pourquoi c'est important**
> - Un problème de connectivité n'est pas forcément une ACL : ici, il y avait aussi un problème de **routage**, et potentiellement de **configuration du poste**.
> - **Le point de test compte** : un ping depuis le routeur ne teste pas la même chose qu'un ping depuis le LAN (adresse source différente, ACL de sortie non traversée).
> - **Tester en isolant** (retirer une ACL, changer de source) est plus fiable que deviner. Et savoir **documenter ce qu'on a éliminé**, puis **escalader**, fait partie du métier : c'est ce qu'on attend d'un technicien support.

---

## TP 12.5 – Établir des ACL étendues (sans fichier fourni)

### Énoncé

Construire la topologie, configurer un protocole de routage pour que chaque machine puisse contacter n'importe quelle autre, puis configurer les ACL :
1. **Telnet** autorisé vers **tous les routeurs** depuis 192.168.100.0/24 et 192.168.200.0/24.
2. **ICMP echo et echo-reply** autorisés entre 192.168.100.0/24 et 192.168.200.0/24.
3. Le reste implicitement interdit.

### Plan de réalisation

1. Construire la topologie
2. Configurer les adresses IP
3. Configurer OSPF
4. Vérifier le routage de bout en bout
5. Préparer les routeurs au Telnet (et établir une référence)
6. Concevoir, appliquer et tester les ACL

---

### Étape 1 – Construire la topologie

#### Choix du matériel

L'énoncé ne précise pas les ports. R2 et R3 ont chacun **trois** liens (deux routeurs + un client) : il faut des routeurs à trois ports Gigabit → **2911** (G0/0, G0/1, G0/2).

> ⚠️ **Erreur rencontrée :** R2 et R3 avaient d'abord été posés en **2901**, qui n'a que **deux** ports Gigabit, déjà pris par les liens entre routeurs. Les câbles vers les clients n'avaient aucune étiquette de port côté routeur. Correction : supprimer les 2901, poser des 2911, recâbler.
>
> 💡 **Options → Preferences → Always Show Port Labels** affiche en permanence les ports sur le schéma.

#### Plan d'adressage

| Appareil | Interface | Adresse | Vers |
|---|---|---|---|
| R1 | G0/0 | 192.168.0.2/30 | R2 |
| R1 | G0/1 | 192.168.0.5/30 | R3 |
| R2 | G0/0 | 192.168.0.1/30 | R1 |
| R2 | G0/1 | 192.168.0.9/30 | R3 |
| R2 | G0/2 | 192.168.100.254/24 | Client 1 |
| R3 | G0/0 | 192.168.0.6/30 | R1 |
| R3 | G0/1 | 192.168.0.10/30 | R2 |
| R3 | G0/2 | 192.168.200.254/24 | Client 2 |
| Client 1 | NIC | 192.168.100.1/24, passerelle .254 | |
| Client 2 | NIC | 192.168.200.1/24, passerelle .254 | |

**Pourquoi des /30 entre routeurs ?** Un /30 = 4 adresses : réseau, deux utilisables, broadcast. Un lien point à point n'a besoin que de deux adresses. Exemple 192.168.0.0/30 : .0 réseau, .1 R2, .2 R1, .3 broadcast. Masque décimal : **255.255.255.252** (252 = `11111100`).

Le « 19 » près de Client 2 sur le schéma de l'énoncé est un reste de mise en page.

#### Câblage

Tous les liens en **câble croisé** (*Copper Cross-Over*) :

| Lien | Câble |
|---|---|
| R1 G0/0 ↔ R2 G0/0 | Croisé |
| R1 G0/1 ↔ R3 G0/0 | Croisé |
| R2 G0/1 ↔ R3 G0/1 | Croisé |
| R2 G0/2 ↔ Client 1 Fa0 | Croisé |
| R3 G0/2 ↔ Client 2 Fa0 | Croisé |

**La règle :**
- Équipements de **types différents** (PC ↔ switch, routeur ↔ switch) → câble **droit**.
- Équipements de **même type** (switch ↔ switch, routeur ↔ routeur, **routeur ↔ PC**) → câble **croisé**.

Un PC et un routeur émettent sur les mêmes broches : sans croisement, leurs émissions se retrouveraient face à face. Le switch inverse ses broches en interne. Sur du vrai matériel récent, l'auto-MDIX rend souvent le choix indifférent ; Packet Tracer est plus strict.

---

### Étape 2 – Adresses IP

**R1**
```
enable
configure terminal
hostname R1
! Évite qu'une faute de frappe soit prise pour un nom DNS
no ip domain-lookup
!
! Lien vers R2 : 192.168.0.0/30, R1 prend la .2
interface GigabitEthernet0/0
 ip address 192.168.0.2 255.255.255.252
 no shutdown
 exit
!
! Lien vers R3 : 192.168.0.4/30, R1 prend la .5
interface GigabitEthernet0/1
 ip address 192.168.0.5 255.255.255.252
 no shutdown
 exit
end
```

**R2**
```
enable
configure terminal
hostname R2
no ip domain-lookup
interface GigabitEthernet0/0
 ip address 192.168.0.1 255.255.255.252
 no shutdown
 exit
interface GigabitEthernet0/1
 ip address 192.168.0.9 255.255.255.252
 no shutdown
 exit
! Passerelle du LAN de Client 1
interface GigabitEthernet0/2
 ip address 192.168.100.254 255.255.255.0
 no shutdown
 exit
end
```

**R3**
```
enable
configure terminal
hostname R3
no ip domain-lookup
interface GigabitEthernet0/0
 ip address 192.168.0.6 255.255.255.252
 no shutdown
 exit
interface GigabitEthernet0/1
 ip address 192.168.0.10 255.255.255.252
 no shutdown
 exit
! Passerelle du LAN de Client 2
interface GigabitEthernet0/2
 ip address 192.168.200.254 255.255.255.0
 no shutdown
 exit
end
```

Après chaque bloc, **à la main** : `copy running-config startup-config`.

**Clients** (Desktop → IP Configuration, Static) :
- Client 1 : 192.168.100.1 / 255.255.255.0 / passerelle 192.168.100.254
- Client 2 : 192.168.200.1 / 255.255.255.0 / passerelle 192.168.200.254

#### Vérification et pièges rencontrés

```
R1# show ip interface brief
GigabitEthernet0/0 192.168.0.2 YES manual up down
GigabitEthernet0/1 192.168.0.5 YES manual up up
```
**up/down** : l'interface de R1 est activée (`Status` up), mais le lien ne fonctionne pas de bout en bout (`Protocol` down). Le problème est **en face**.

```
R2# show ip interface brief
GigabitEthernet0/0 unassigned YES unset administratively down down
```
→ Le premier bloc d'interface de R2 avait été **perdu au collage**. Même chose ensuite sur R3, pour le **dernier** bloc (Gi0/2).

**Correction :** retaper l'interface manquante (`ip address` + `no shutdown`). Des messages `%LINK-5-CHANGED ... changed state to up` confirment l'activation.

> 💡 **Lors d'un collage, des lignes peuvent se perdre au début comme à la fin du bloc.** Toujours vérifier avec `show ip interface brief` après chaque configuration.

Les interfaces non utilisées (Vlan1, ports libres) en `administratively down` sont normales.

---

### Étape 3 – OSPF

**R1**
```
configure terminal
! Processus OSPF n°1 (numéro local, peut différer entre voisins)
router ospf 1
! Identifiant unique du routeur, choisi pour être lisible
 router-id 1.1.1.1
! Active OSPF sur les interfaces de ces réseaux, dans l'aire 0
 network 192.168.0.0 0.0.0.3 area 0
 network 192.168.0.4 0.0.0.3 area 0
end
```

**R2**
```
configure terminal
router ospf 1
 router-id 2.2.2.2
 network 192.168.0.0 0.0.0.3 area 0
 network 192.168.0.8 0.0.0.3 area 0
 network 192.168.100.0 0.0.0.255 area 0
! Pas de routeur côté Client 1 : pas de messages OSPF sur ce port
 passive-interface GigabitEthernet0/2
end
```

**R3**
```
configure terminal
router ospf 1
 router-id 3.3.3.3
 network 192.168.0.4 0.0.0.3 area 0
 network 192.168.0.8 0.0.0.3 area 0
 network 192.168.200.0 0.0.0.255 area 0
 passive-interface GigabitEthernet0/2
end
```

**À comprendre :**
- **`network` utilise un wildcard**, exactement comme les ACL : `192.168.0.0 0.0.0.3` = adresses .0 à .3. Chaque interface dont l'adresse tombe dans cette plage participe à OSPF.
- **`area 0`** : l'aire principale (backbone). Les voisins doivent être d'accord sur l'aire d'un lien.
- **`passive-interface`** : le réseau est **annoncé**, mais aucun message OSPF n'est **envoyé** sur ce port. Plus propre (pas de trafic inutile vers le PC) et plus sûr (personne ne peut se faire passer pour un routeur OSPF depuis le LAN).

#### Vérification des voisinages

```
R1# show ip ospf neighbor
2.2.2.2  1  FULL/BDR  ...  192.168.0.1  GigabitEthernet0/0
3.3.3.3  1  FULL/BDR  ...  192.168.0.6  GigabitEthernet0/1
```
Chaque routeur doit voir **deux voisins en FULL**.

> ⚠️ **Problème rencontré :** R2 et R3 ne voyaient que R1, pas l'un l'autre (lien 192.168.0.8/30). Causes possibles : délai (environ 40 s sur Ethernet, mais le voisin apparaîtrait alors dans un état intermédiaire), ligne `network 192.168.0.8 0.0.0.3 area 0` perdue au collage, ou `passive-interface` sur la mauvaise interface. Outil de diagnostic : `show ip protocols` (sections *Routing for Networks* et *Passive Interface(s)*).
>
> **Correction appliquée sur R2 et R3** (sans danger si la config était déjà correcte : IOS ignore les doublons) :
> ```
> router ospf 1
>  network 192.168.0.8 0.0.0.3 area 0
>  no passive-interface GigabitEthernet0/1
> ```
> Après ~40 s : `%OSPF-5-ADJCHG: ... Nbr 3.3.3.3 on GigabitEthernet0/1 from LOADING to FULL`.

**`FULL/DR`, `FULL/BDR` :** sur Ethernet, OSPF élit un routeur **désigné** (DR) et un **suppléant** (BDR) qui centralisent les échanges. Peu utile sur un lien point à point, mais fait par défaut sur Ethernet.

---

### Étape 4 – Vérifier le routage

```
R2# show ip route
C 192.168.0.0/30 ... GigabitEthernet0/0
O 192.168.0.4/30 [110/2] via 192.168.0.2, GigabitEthernet0/0
                 [110/2] via 192.168.0.10, GigabitEthernet0/1
C 192.168.0.8/30 ... GigabitEthernet0/1
C 192.168.100.0/24 ... GigabitEthernet0/2
O 192.168.200.0/24 [110/2] via 192.168.0.10, GigabitEthernet0/1
```

| Élément | Signification |
|---|---|
| `O` | Route apprise par OSPF |
| `[110/2]` | Distance administrative (110 = OSPF) / coût du chemin |
| `via 192.168.0.10` | Prochain saut (R3) |
| `GigabitEthernet0/1` | Interface de sortie |

- **192.168.200.0/24 via R3 directement** : chemin le moins coûteux.
- **192.168.0.4/30 apparaît deux fois, même coût** : **équilibrage de charge à coût égal** (ECMP).

Tests depuis Client 1 : `ping 192.168.200.1`, `tracert 192.168.200.1` (chemin attendu : 192.168.100.254 → 192.168.0.10 → Client 2).

---

### Étape 5 – Préparer le Telnet et établir une référence

Sans configuration des vty, les routeurs refusent le Telnet. Sur **R1, R2 et R3** :
```
configure terminal
! Mot de passe du mode privilégié (hash)
enable secret class
! Compte local pour l'authentification Telnet
username admin secret cisco
line vty 0 4
! Authentification par comptes locaux (identifiant + mot de passe)
 login local
! Autorise explicitement Telnet
 transport input telnet
 exit
end
copy running-config startup-config
```
- **`secret`** plutôt que `password` : stockage en **hash**, illisible dans la config (contrairement au `password 0` de HQ au TP 12.4).
- **`login local`** : identifiant + mot de passe, plus robuste qu'un mot de passe partagé.
- **`enable secret`** indispensable : sans lui, IOS refuse l'`enable` à distance.

#### Messages Telnet et causes

| Message | Cause probable |
|---|---|
| `Connection timed out` | Le paquet n'atteint pas la cible : routage, passerelle, adressage |
| `Connection refused by remote host` | La cible refuse : vty incomplètes, ACL vty |
| `Password required, but none set` | Pas de `login local` ni de mot de passe sur les vty |
| `% Login invalid` | Identifiants incorrects |

> ⚠️ **Piège rencontré :** premier Telnet depuis Client 1 → `Connection timed out`, et `ping 192.168.0.2` en échec. Cause : **les clients n'étaient pas encore configurés** (aucune adresse). Après configuration, Telnet OK.

#### La référence

```
C:\> telnet 192.168.0.2   → Username: admin / Password: cisco → R1> ✅
```
Le Telnet fonctionne **sans ACL**. Tout échec après la pose des ACL leur sera donc attribuable avec certitude.

> 💡 **Toujours établir une référence qui fonctionne avant d'ajouter du filtrage.** C'est ce qui a manqué au TP 12.4, où l'on ne savait pas si le Telnet avait jamais fonctionné.

---

### Étape 6 – Concevoir, appliquer et tester les ACL

#### Conception

**Placement :** ACL étendues → **au plus près de la source**, donc en **entrée** sur :
- **R2 Gi0/2** pour le trafic venant de 192.168.100.0/24 ;
- **R3 Gi0/2** pour le trafic venant de 192.168.200.0/24.

**Pourquoi pas sur les liens entre routeurs ?** Ils transportent les messages **OSPF** (protocole IP 89). Le `deny` implicite les bloquerait : voisinages perdus, routage effondré. Les interfaces LAN, passives, ne portent aucun message OSPF.

**Désigner « tous les routeurs » :**
- Liens entre routeurs (.1, .2, .5, .6, .9, .10) → un seul wildcard : **`192.168.0.0 0.0.0.15`** couvre 192.168.0.0 à .15, soit les trois /30. (15 = `00001111` : 4 bits libres, 16 adresses.)
- Passerelles des LAN → `host 192.168.100.254` et `host 192.168.200.254`.
- `any eq telnet` serait plus court, mais autoriserait le Telnet vers **n'importe quelle** machine, clients compris.

**Echo et echo-reply :** du point de vue de l'ACL en entrée sur R2 Gi0/2 :
- Client 1 pingue Client 2 → l'**echo** de Client 1 entre par Gi0/2 ;
- Client 2 pingue Client 1 → la **réponse** (echo-reply) de Client 1 entre par Gi0/2.

Sans `echo-reply`, le ping ne marcherait que dans un sens.

**Les réponses Telnet des routeurs** ne sont pas filtrées : elles **sortent** par les interfaces LAN, et les ACL sont en **entrée**.

#### ACL sur R2

```
configure terminal
ip access-list extended LAN100-IN
! Telnet vers les adresses des liens entre routeurs
 permit tcp 192.168.100.0 0.0.0.255 192.168.0.0 0.0.0.15 eq telnet
! Telnet vers les passerelles des deux LAN
 permit tcp 192.168.100.0 0.0.0.255 host 192.168.100.254 eq telnet
 permit tcp 192.168.100.0 0.0.0.255 host 192.168.200.254 eq telnet
! Ping du LAN 100 vers le LAN 200 (aller)
 permit icmp 192.168.100.0 0.0.0.255 192.168.200.0 0.0.0.255 echo
! Réponses du LAN 100 aux pings venus du LAN 200 (retour)
 permit icmp 192.168.100.0 0.0.0.255 192.168.200.0 0.0.0.255 echo-reply
 exit
interface GigabitEthernet0/2
 ip access-group LAN100-IN in
 exit
end
copy running-config startup-config
```

#### ACL sur R3 (symétrique)

```
configure terminal
ip access-list extended LAN200-IN
 permit tcp 192.168.200.0 0.0.0.255 192.168.0.0 0.0.0.15 eq telnet
 permit tcp 192.168.200.0 0.0.0.255 host 192.168.100.254 eq telnet
 permit tcp 192.168.200.0 0.0.0.255 host 192.168.200.254 eq telnet
 permit icmp 192.168.200.0 0.0.0.255 192.168.100.0 0.0.0.255 echo
 permit icmp 192.168.200.0 0.0.0.255 192.168.100.0 0.0.0.255 echo-reply
 exit
interface GigabitEthernet0/2
 ip access-group LAN200-IN in
 exit
end
copy running-config startup-config
```

#### Vérifications

```
R2# show access-lists LAN100-IN        → les 5 règles présentes
R2# show ip interface GigabitEthernet0/2 → Inbound access list is LAN100-IN
```
(Même chose sur R3 avec LAN200-IN.)

#### Tests et résultats

| Depuis | Test | Attendu | Obtenu |
|---|---|---|---|
| Client 1 | `telnet 192.168.0.2` | ✅ | ✅ |
| Client 1 | `ping 192.168.200.1` | ✅ | ✅ |
| Client 1 | `ping 192.168.100.254` | ❌ | ❌ |
| Client 2 | `telnet 192.168.0.6` / `telnet 192.168.100.254` | ✅ | ✅ |
| Client 2 | `ping 192.168.100.1` | ✅ | ✅ TTL=126 |
| Client 2 | `ping 192.168.200.254` | ❌ | ❌ `Destination host unreachable` |

**Lecture :**
- **TTL=126** : 128 − 2 → deux routeurs traversés (R3 puis R2), chemin direct. Ce ping valide les **deux** ACL : echo via LAN200-IN, echo-reply via LAN100-IN.
- **Ping vers sa propre passerelle bloqué** : une ACL en entrée filtre aussi les paquets destinés au routeur. C'est la conséquence voulue de l'énoncé (ICMP autorisé seulement entre les LAN).
- **`Destination host unreachable`** plutôt qu'un timeout : c'est **R3 lui-même** qui répond (`Reply from 192.168.200.254`) pour signaler le refus. Ce message ICMP n'est pas filtré : il **sort** par Gi0/2, et l'ACL ne s'applique qu'en **entrée**.

Les compteurs (`show access-lists` sur R2 et R3) montrent quelles règles ont servi pendant les tests.

---

> ### 📌 En résumé – TP 12.5
>
> **Ce qu'on a fait**
> - Construit un réseau complet **de zéro** : choix du matériel, plan d'adressage en /30 et /24, câblage, adresses IP.
> - Configuré **OSPF** pour que tous les réseaux se connaissent, en rendant passives les interfaces vers les clients.
> - Préparé l'accès Telnet sécurisé (`login local`, `secret`) et **vérifié une référence** avant tout filtrage.
> - Conçu puis appliqué deux **ACL étendues symétriques**, en entrée sur les interfaces LAN, pour n'autoriser que le Telnet vers les routeurs et le ping entre les deux LAN.
>
> **À quoi ça sert**
> - C'est le déroulé réel d'un projet réseau : **faire fonctionner**, **vérifier**, **puis sécuriser**. Chaque étape s'appuie sur la précédente.
> - Ce type d'ACL traduit une **politique de sécurité** en règles concrètes : qui peut administrer les équipements, quels échanges sont permis entre les sites, et tout le reste est refusé par défaut.
>
> **Pourquoi c'est important**
> - Le **placement** d'une ACL est aussi décisif que son contenu : posée sur les liens entre routeurs, la même ACL aurait coupé OSPF et tout le réseau.
> - **Penser aux deux sens d'un échange** : sans `echo-reply`, le ping ne marchait que dans un sens.
> - **Être précis plutôt que large** (`192.168.0.0 0.0.0.15` et `host` plutôt que `any`) : on autorise exactement ce qui est demandé.
> - **Tester aussi ce qui doit être bloqué** : une ACL qui laisse tout passer ne produit aucune erreur visible.
> - Les wildcards servent à la fois pour les ACL et pour OSPF : une même logique, deux usages.

---

## Leçons transversales

| Leçon | Rencontrée dans |
|---|---|
| **Vérifier l'invite** avant chaque commande (`Branch#`, `SW1#`, `HQ#`) | 12.4 (pings lancés depuis le mauvais équipement) |
| **Relire l'adresse tapée** avant de soupçonner le réseau | 12.3 (192.16.1.100), 12.4 (172.16.100) |
| **Vérifier après chaque collage** (`show ip interface brief`, `show access-lists`) | 12.5 (interfaces et ligne OSPF perdues) |
| **Coller jusqu'au `end`, taper `copy run start` à la main** | Tous |
| **`show ip interface`** pour savoir où/dans quel sens une ACL est appliquée | 12.3, 12.4 |
| **Lire une règle du point de vue du paquet** à l'interface et dans le sens d'application | 12.3 |
| **Un compteur prouve le passage dans l'ACL, pas la réponse** | 12.4 |
| **Relancer une vérification** avant de conclure à une anomalie | 12.3 (compteurs non mis à jour) |
| **Le point de test compte** (source différente, ACL `out` non traversée par le trafic du routeur) | 12.4 |
| **Établir une référence** avant d'ajouter du filtrage | 12.5 |
| **Tester en isolant** un composant à la fois | 12.4 |
| **Documenter ce qui est éliminé, puis escalader** | 12.4 |
| **Timeout vs refus vs unreachable** : qui répond, et pourquoi | 12.3, 12.4, 12.5 |

---

## Aide-mémoire

### ACL étendues

| Objectif | Commande | Mode |
|---|---|---|
| Créer une ACL étendue nommée | `ip access-list extended NOM` | `(config)#` |
| Bloquer un service d'un hôte vers un hôte | `deny tcp host A host B eq telnet` | `(config-ext-nacl)#` |
| Autoriser tout le reste | `permit ip any any` | `(config-ext-nacl)#` |
| Autoriser un ping aller / retour | `permit icmp SRC WC DST WC echo` / `echo-reply` | `(config-ext-nacl)#` |
| Insérer une règle à une position | `5 deny ...` | `(config-ext-nacl)#` |
| Supprimer une règle | `no deny ...` ou `no 10` | `(config-ext-nacl)#` |
| Appliquer sur une interface | `ip access-group NOM in\|out` | `(config-if)#` |
| Retirer d'une interface | `no ip access-group NOM in\|out` | `(config-if)#` |
| Voir le contenu et les compteurs | `show access-lists [NOM]` | `#` |
| Voir où une ACL est appliquée | `show ip interface INTERFACE` | `#` |
| Remettre les compteurs à zéro | `clear access-list counters [NOM]` | `#` |

### Routage

| Objectif | Commande | Mode |
|---|---|---|
| Route par défaut | `ip route 0.0.0.0 0.0.0.0 PROCHAIN_SAUT` | `(config)#` |
| Table de routage | `show ip route` | `#` |
| Démarrer OSPF | `router ospf 1` | `(config)#` |
| Identifiant OSPF | `router-id X.X.X.X` | `(config-router)#` |
| Annoncer un réseau | `network RESEAU WILDCARD area 0` | `(config-router)#` |
| Interface passive | `passive-interface INTERFACE` | `(config-router)#` |
| Voisins OSPF | `show ip ospf neighbor` | `#` |
| Résumé OSPF | `show ip protocols` | `#` |

### Diagnostic

| Objectif | Commande |
|---|---|
| État des interfaces | `show ip interface brief` |
| Détail d'une interface (erreurs, paquets) | `show interfaces INTERFACE` |
| Tester la connectivité | `ping ADRESSE` |
| Tracer le chemin (Cisco, UDP) | `traceroute ADRESSE` |
| Tracer le chemin (Windows, ICMP) | `tracert ADRESSE` |
| Tester un port TCP | `telnet ADRESSE PORT` |
| Interrompre une commande | `Ctrl+Shift+6` |
| Config IP d'un PC | `ipconfig` |
| Mode Simulation Packet Tracer | `Shift+S` |

### Accès distant sécurisé

```
enable secret class
username admin secret cisco
line vty 0 4
 login local
 transport input telnet    (ssh en production)
```
