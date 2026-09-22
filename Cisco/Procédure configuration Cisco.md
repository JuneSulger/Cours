# Procédure complète — Configuration d'une topologie Cisco (switch(s) + routeur)

Ordre logique unique, de la remise à zéro d'un appareil jusqu'à un réseau segmenté, routé et sécurisé. Chaque phase explique pourquoi elle vient à ce moment précis. À adapter selon ta topologie (un seul switch isolé → arrête-toi à la phase 8 ; plusieurs switchs + routeur → va jusqu'au bout).

Référence du lexique complet des commandes : voir `Lexique_Commandes_Cisco.md`.

---

## Phase 0 — Préparation matérielle

1. Câble la topologie (switch(s), routeur, PC) selon le schéma cible.
2. Prévois un accès **console** (câble RJ45↔USB) pour le tout premier contact avec chaque switch — c'est obligatoire tant qu'aucune IP n'est configurée : ni Telnet ni SSH ne fonctionnent sans configuration réseau préalable.
3. Configure ton logiciel terminal (PuTTY/Tera Term) en mode **Serial**, vitesse **9600**.

> **Pourquoi commencer ici :** sans câblage ni accès physique, aucune commande n'est possible. C'est le seul point d'entrée obligatoire.

---

## Phase 1 — Remise à zéro (si l'appareil a déjà une config)

Sur **chaque switch/routeur** :
```
enable
erase startup-config
delete vlan.dat
reload
```
Confirmer chaque étape ; répondre **no** à la demande de sauvegarde et **no** au dialogue de configuration initiale.

> **Pourquoi ici :** on veut repartir d'un état connu et propre avant de bâtir quoi que ce soit dessus. Sauter cette étape sur un appareil partagé (ex. un rack physique) risque d'écraser le travail d'un collègue — vérifier `show running-config` avant si le matériel est partagé.

---

## Phase 2 — Reconnaissance de l'appareil (diagnostic, avant toute config)

```
show version                  ! modèle, version IOS, RAM, flash
show flash:                   ! contenu de la mémoire flash
show ip interface brief       ! interfaces disponibles et leur état
show running-config | include line vty   ! lignes VTY disponibles (ou show running-config si la forme filtrée échoue)
```

> **Pourquoi ici :** on ne configure jamais à l'aveugle. Savoir quel modèle, quelle version d'IOS, quelles interfaces sont réellement disponibles évite des commandes qui échouent plus tard (ex. `g0/1` vs `g0/0/1` selon le modèle de routeur).

---

## Phase 3 — Confort de la CLI

Sur `line console 0` (et à dupliquer sur `line vty` plus tard une fois créées) :
```
enable
configure terminal
no ip domain-lookup
line console 0
exec-timeout 60
logging synchronous
history size 100
exit
```

> **Pourquoi ici, avant tout le reste :** ce sont des réglages de confort de travail (éviter les blocages DNS sur une faute de frappe, éviter que des messages système ne coupent ta frappe en cours). Les appliquer tôt rend **toute la suite de la configuration plus confortable**, alors autant les faire en premier.

---

## Phase 4 — Identité de l'appareil

```
hostname NOM
banner motd #Accès réservé au personnel autorisé. Toute tentative non autorisée sera journalisée.#
```

> **Pourquoi ici :** une fois l'appareil nommé, tous les prompts suivants (`NOM(config)#`, etc.) sont lisibles et sans ambiguïté — utile dès qu'on manipule plusieurs appareils dans la même session.

---

## Phase 5 — VLAN de gestion et IP de l'appareil (switch)

```
configure terminal
vlan 99
name Management
exit
interface vlan 99
ip address IP MASQUE
no shutdown
exit
```

> **Pourquoi ici, et pas plus tard :** un switch a besoin d'une IP de gestion pour être administrable à distance (SSH). On la met en place tôt pour pouvoir, dès que possible, libérer le câble console (utile si le câble est partagé entre plusieurs personnes) et continuer en SSH.
>
> **Piège à connaître :** l'interface VLAN reste en protocole **down** tant qu'aucun port physique n'est membre de ce VLAN — normal, pas une erreur. Elle passera **up** dès la Phase 9 (assignation des ports).

```
ip default-gateway IP_ROUTEUR
```
(passerelle de gestion du switch — pour son propre trafic d'administration, pas pour router du trafic client : un switch niveau 2 ne route rien)

---

## Phase 6 — Sécurisation des accès locaux (mots de passe)

```
configure terminal
enable secret MOT_DE_PASSE
line console 0
password MOT_DE_PASSE
login
exit
line vty 0 15
password MOT_DE_PASSE
login
exit
service password-encryption
```

> **Pourquoi ici :** avant d'ouvrir tout accès distant (Phase 7), on verrouille l'accès de base — mot de passe sur le mode privilégié et sur les lignes d'accès. `login` est **indispensable** : sans lui, le mot de passe défini n'est jamais demandé à la connexion. `service password-encryption` chiffre tout ce qui est encore en clair.

---

## Phase 7 — Accès distant sécurisé (SSH, jamais Telnet)

```
configure terminal
ip domain-name DOMAINE
username admin privilege 15 secret MOT_DE_PASSE
crypto key generate rsa general-keys modulus 1024
line vty 0 15
transport input ssh
login local
exit
ip ssh version 2
ip ssh time-out 75
ip ssh authentication-retries 2
end
copy running-config startup-config
```

> **Pourquoi ici :** dès que SSH fonctionne, le câble console n'est plus nécessaire pour continuer — tu peux administrer l'appareil à distance pour le reste de la procédure. C'est aussi le moment de sauvegarder une première fois (`copy running-config startup-config`), pour ne pas perdre cette base fonctionnelle en cas de plantage.
>
> `login local` (base d'utilisateurs) remplace le simple `password` de ligne pour les VTY — plus traçable qu'un mot de passe partagé. `transport input ssh` bloque Telnet de fait.

---

## Phase 8 — Vérification de connectivité de base

Depuis un PC connecté :
```
ping IP_DE_GESTION_DU_SWITCH
ssh -l admin IP_DE_GESTION_DU_SWITCH
```

> **Pourquoi ici :** avant d'aller plus loin dans la segmentation VLAN, on confirme que la base (IP, mots de passe, SSH) fonctionne. C'est aussi le point d'arrêt naturel si ta topologie ne comporte qu'un seul switch isolé.

*(Si ta topologie s'arrête à un switch + PC, tu peux t'arrêter ici après la Phase 12 de durcissement. Les phases suivantes concernent une topologie multi-switchs et/ou avec routeur.)*

---

## Phase 9 — VLANs de données et assignation des ports utilisateurs

Sur chaque switch concerné :
```
configure terminal
vlan 10
exit
vlan 20
exit
interface fa0/1
switchport mode access
switchport access vlan 10
exit
```
(un `switchport access vlan` par port, selon le VLAN cible de chaque appareil connecté)

**IP des PC concernés**, à mettre à jour pour correspondre à leur nouveau VLAN :
- Adresse IP (dans le bon sous-réseau)
- Masque
- Passerelle (l'IP de la future sous-interface du routeur pour ce VLAN — configurée en Phase 11)

> **Pourquoi ici :** on crée d'abord la structure logique (les VLANs) puis on y range les ports — dans cet ordre uniquement, sinon `switchport access vlan N` échoue si le VLAN N n'existe pas encore.
>
> **Piège à connaître :** après un changement de VLAN, vérifie les **3 champs** de l'IP du PC (adresse, masque, passerelle) — une mise à jour partielle (ex. passerelle changée mais pas l'adresse) casse la connectivité de façon plus difficile à repérer qu'un oubli total.

---

## Phase 10 — Trunking entre switchs

Sur le port reliant deux switchs (des deux côtés du lien) :
```
configure terminal
interface fa0/3
switchport mode trunk
switchport trunk allowed vlan 1,10,20
switchport nonegotiate
end
copy running-config startup-config
```

> **Pourquoi ici, après les VLANs (Phase 9) :** un trunk n'a de sens qu'une fois qu'il y a plusieurs VLANs à transporter. Restreindre les VLANs autorisés (`allowed vlan`) est une bonne pratique — un trunk laisse passer tous les VLANs par défaut, ce qui est excessif.
>
> **Piège à connaître :** `switchport nonegotiate` échoue (`Conflict between 'nonegotiate' and 'dynamic' status`) si `switchport mode trunk` n'a pas été appliqué avec succès juste avant — vérifie avec `show interface <port> switchport` (ligne `Administrative Mode`) avant d'enchaîner.

**Vérification :**
```
show interfaces trunk
show cdp neighbors
```
(`show cdp neighbors` est précieux pour confirmer qu'il n'y a pas de câble surnuméraire entre deux switchs, ce qui créerait une boucle de niveau 2)

---

## Phase 11 — Trunk vers le routeur + routage inter-VLAN (router-on-a-stick)

**Sur le switch**, côté port face au routeur : même config de trunk qu'à la Phase 10.

**Sur le routeur :**
```
enable
configure terminal
interface g0/0
no ip address
no shutdown
exit
interface g0/0.1
encapsulation dot1q 1
ip address 10.1.1.1 255.255.255.0
exit
interface g0/0.10
encapsulation dot1q 10
ip address 10.1.10.1 255.255.255.0
exit
interface g0/0.20
encapsulation dot1q 20
ip address 10.1.20.1 255.255.255.0
exit
end
copy running-config startup-config
```

> **Pourquoi ici, en dernier des étapes de connectivité :** le routeur ne peut router entre VLANs qu'une fois que (a) les VLANs existent (Phase 9) et (b) le trunk qui les transporte jusqu'à lui est en place (Phase 10). C'est la dernière pièce qui manque pour que deux PC sur des VLANs différents puissent enfin communiquer.

**Vérification :**
```
show ip interface brief
show interface g0/0.10
show ip route
```

---

## Phase 12 — Durcissement final (sécurité)

```
configure terminal
interface range fa0/X - Y
shutdown
exit
no ip http server
```

**Sortir les ports actifs du VLAN 1 et désactiver le VLAN 1 :**
```
vlan 45
exit
interface range fa0/1-24
switchport mode access
switchport access vlan 45
interface vlan 1
shutdown
exit
```
(si le VLAN 1 n'est déjà plus utilisé comme VLAN de gestion — vérifie qu'aucune interface active n'en dépend encore avant de l'éteindre)

**Port security sur les ports d'accès (au minimum ceux face à des appareils fixes/serveurs) :**
```
interface fa0/5
shutdown
switchport mode access
switchport port-security
switchport port-security maximum 1
switchport port-security mac-address sticky
switchport port-security violation shutdown
no shutdown
```

> **Pourquoi tout ceci en dernier :** le durcissement final vient après que **tout fonctionne** — on ferme ce qui n'est pas utile (ports inutilisés, VLAN 1 par défaut, service HTTP non chiffré) et on verrouille ce qui reste (Port Security) une fois que la topologie cible est stable. Durcir trop tôt complique le débogage des étapes précédentes.

---

## Phase 13 — Vérifications finales de connectivité

```
ping <PC1> → <passerelle PC1>
ping <PC1> → <PC2, autre VLAN>
show mac address-table
show port-security interface <port>
```

> Le premier ping après un changement de topologie peut échouer le temps de la résolution ARP — retenter avant de conclure à un problème.

---

## Phase 14 — Sauvegarde finale

Sur **chaque** appareil modifié (switchs et routeur) :
```
copy running-config startup-config
```

> **Pourquoi en tout dernier (en plus des sauvegardes intermédiaires déjà faites en Phase 7 et 10) :** une sauvegarde finale après durcissement capture l'état complet et définitif de la configuration — c'est ce qui doit survivre à un redémarrage.

---

## Récapitulatif de l'ordre logique

1. Câblage
2. Remise à zéro
3. Reconnaissance de l'appareil
4. Confort CLI
5. Identité (hostname, bannière)
6. VLAN de gestion + IP du switch
7. Mots de passe locaux
8. SSH (+ sauvegarde intermédiaire)
9. Vérification de connectivité de base *(point d'arrêt possible pour un switch isolé, après la Phase 12)*
10. VLANs de données + assignation des ports
11. Trunking entre switchs
12. Trunk + router-on-a-stick sur le routeur
13. Durcissement final (ports inutilisés, VLAN 1, HTTP, Port Security)
14. Vérifications finales
15. Sauvegarde finale
