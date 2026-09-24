# Lexique des commandes Cisco IOS

*Compilé à partir de l'ensemble des TP et supports de théorie : Sécurisation de base, Connectivité de base avec un switch, VLAN & Trunking, TP1 Démarrage, TP physique sur rack, STP/RSTP/PortFast/BPDU Guard.*

Les commandes sont classées par ce à quoi elles servent, pas par ordre alphabétique — pour retrouver rapidement "comment on fait X".

---

## 1. Navigation entre les modes de privilège

| Commande | Effet |
|---|---|
| `enable` | Passe du mode utilisateur (`>`) au mode privilégié (`#`) |
| `disable` | Repasse du mode privilégié au mode utilisateur |
| `configure terminal` (`conf t`) | Entre en mode configuration globale (`(config)#`) |
| `interface TYPE N°` | Entre en mode configuration d'une interface précise (`(config-if)#`) |
| `interface range TYPE N°-N°[, TYPE N°-N°]` | Entre en mode configuration pour plusieurs interfaces à la fois |
| `line console 0` | Entre en mode configuration du port console |
| `line vty N-N` | Entre en mode configuration des lignes VTY (accès distant Telnet/SSH) |
| `vlan N°` | Entre en mode configuration d'un VLAN (`(config-vlan)#`) |
| `exit` | Remonte d'un niveau de configuration |
| `end` | Quitte directement tout mode configuration, retour au mode privilégié |
| `Ctrl+Z` | Raccourci clavier équivalent à `end` |
| `do COMMANDE` | Exécute une commande d'un autre niveau sans quitter le niveau courant |

**Les 4 niveaux de privilège :**
| Niveau | Prompt | Nom |
|---|---|---|
| 1 | `Switch>` | User EXEC |
| 2 | `Switch#` | Privileged EXEC |
| 3 | `Switch(config)#` | Global Configuration |
| 4 | `Switch(config-if)#` / `(config-line)#` / `(config-vlan)#` | Sous-modes (interface, ligne, VLAN...) |

---

## 2. Aide et personnalisation de la CLI

| Commande | Effet |
|---|---|
| `?` | Liste les commandes disponibles au niveau actuel (aide contextuelle) |
| `COMMANDE ?` | Complète l'aide contextuelle pour une commande en cours de frappe |
| `clock set HH:MM:SS JOUR MOIS ANNÉE` | Configure l'heure et la date de l'appareil |
| `show clock` | Affiche l'heure/date configurée |
| `!COMMENTAIRE` | Ligne de commentaire dans la config (non exécutée) |
| `history size NOMBRE` (dans `line console 0`) | Change la taille de l'historique des commandes de cette ligne |
| `show terminal` | Affiche la config courante de la CLI (dont la taille d'historique) |
| `no ip domain-lookup` (ou `no ip domain lookup`) | Empêche le switch d'essayer de résoudre en DNS une commande mal tapée (évite un blocage de 5-10 sec) |
| `logging synchronous` (dans `line console 0`) | Empêche les messages système non sollicités d'interrompre la frappe en cours |
| `exec-timeout MINUTES` (dans `line console 0` ou `line vty`) | Délai d'inactivité avant déconnexion automatique (défaut : 10 min) |

**Raccourcis de navigation dans une ligne :**
| Raccourci | Action |
|---|---|
| Ctrl+A | Début de ligne |
| Ctrl+E | Fin de ligne |
| Ctrl+B | Reculer d'un caractère |
| Ctrl+F | Avancer d'un caractère |

---

## 3. Identification, version, mémoire

| Commande | Effet |
|---|---|
| `show version` | Modèle, version Cisco IOS, RAM, mémoire flash |
| `show flash:` / `show flash` / `dir flash:` | Contenu de la mémoire flash (fichier image IOS, `vlan.dat`...) |
| `show running-config` (`show run`) | Configuration actuellement active (en RAM) |
| `show startup-config` | Configuration qui s'appliquera au prochain démarrage (en NVRAM) — renvoie `startup-config is not present` si jamais sauvegardée |

---

## 4. Réinitialisation / remise en config d'usine

| Commande | Effet |
|---|---|
| `erase startup-config` | Efface la configuration de démarrage (NVRAM) — **nécessite le mode privilégié** |
| `delete vlan.dat` | Supprime le fichier de base de données VLAN en mémoire flash |
| `reload` | Redémarre l'appareil et relance Cisco IOS |

**Séquence complète de remise à zéro :**
```
enable
erase startup-config
delete vlan.dat
reload
```
(confirmer chaque étape ; répondre "no" à la demande de sauvegarde et "no" au dialogue de config initiale)

---

## 5. Identité et confort de l'appareil

| Commande | Effet |
|---|---|
| `hostname NOM` | Change le nom de l'appareil |
| `banner motd #MESSAGE#` | Bannière d'avertissement affichée à la connexion (le `#` délimite le message, peut être n'importe quel caractère absent du texte) |

---

## 6. Sauvegarde de la configuration

| Commande | Effet |
|---|---|
| `copy running-config startup-config` | Sauvegarde la config active vers la NVRAM (persiste au redémarrage) |

---

## 7. Interfaces — IP et activation

| Commande | Effet |
|---|---|
| `ip address IP MASQUE` | Applique une IP et son masque à une interface |
| `no ip address` | Retire l'IP d'une interface (utile avant de créer des sous-interfaces) |
| `[no] shutdown` | Active/désactive une interface |
| `show ip interface brief` | Vue synthétique : IP, statut (up/down) et protocole de toutes les interfaces |
| `show interface INTERFACE` | Détail complet d'une interface (MAC, vitesse/duplex, statut, compteurs) |
| `show interface vlan N` | Détail de l'interface virtuelle (SVI) d'un VLAN |
| `ip default-gateway IP` | Passerelle de gestion d'un switch (pour son propre trafic de management — un switch niveau 2 ne route pas) |

---

## 8. VLAN

| Commande | Effet |
|---|---|
| `vlan N°` | Crée un VLAN (mode config globale) |
| `name NOM` (dans `(config-vlan)#`) | Nomme le VLAN en cours de création |
| `switchport mode MODE` | `access` (1 seul VLAN) / `trunk` (plusieurs VLANs) / `dynamic auto`\|`desirable` (négociation DTP) |
| `switchport access vlan N°` | Assigne un port au VLAN indiqué (mode access) |
| `show vlan` | Détail des VLANs : nom, statut, ports membres |
| `show vlan brief` | Version condensée de `show vlan` |
| `show vlan \| include active` | Filtre l'affichage aux VLANs actifs uniquement |

---

## 9. Trunking (liens multi-VLAN)

| Commande | Effet |
|---|---|
| `switchport mode trunk` | Déclare un port en trunk (transporte plusieurs VLANs) |
| `switchport trunk allowed vlan N,N,N` | Restreint les VLANs autorisés à traverser le trunk (sinon : tous par défaut) |
| `switchport nonegotiate` | Désactive le DTP (négociation automatique du mode trunk), fige le mode manuellement — **nécessite que `switchport mode trunk` ait déjà été appliqué avec succès**, sinon rejeté avec `Conflict between 'nonegotiate' and 'dynamic' status` |
| `show interface trunk` / `show interfaces trunk` | État des ports en mode trunk (VLANs autorisés, encapsulation, statut) |
| `show interface INTERFACE switchport` | Détail du mode d'un port (`Administrative Mode` / `Operational Mode`) — utile pour diagnostiquer un trunk qui ne prend pas |

---

## 10. Redondance et Spanning Tree Protocol (STP / RSTP / PVST+ / MST)

| Commande | Effet |
|---|---|
| `show spanning-tree` | Vue complète : version STP, Root ID, délais (Hello/Max Age/Forward Delay), Bridge ID local, statut/coût/priorité des interfaces |
| `show spanning-tree summary` | Résumé STP : mode (PVST), root bridge par VLAN, état des ports |
| `show spanning-tree vlan N` | Détail STP pour un VLAN donné (Root ID, Bridge ID, rôle de chaque interface) |
| `show spanning-tree vlan N root detail` | Détail du root bridge pour un VLAN |
| `show spanning-tree vlan N bridge detail` | Détail de la config STP du switch local pour un VLAN |
| `spanning-tree vlan N root primary` | Force le switch à devenir root bridge pour le VLAN N (abaisse automatiquement sa priorité) |
| `spanning-tree vlan N hello SECONDES` | Délai entre les messages STP (Hello) |
| `spanning-tree vlan N max-age SECONDES` | Temps de rétention en mémoire des messages Hello |
| `spanning-tree vlan N forward-delay SECONDES` | Temps d'attente avant changement d'état d'un port |
| `spanning-tree mode mst` | Active le mode MST (une seule instance STP pour plusieurs VLANs, économise les ressources) |
| `spanning-tree mst configuration` | Entre en config MST (`region-name`, `instance N vlan X,Y,Z`) |
| `[no] debug spanning-tree events` | Active/désactive le debug STP en temps réel (affiche les transitions d'état) — **non simulé sur Packet Tracer** |

**PortFast et BPDU Guard (surcouches sur les ports d'accès) :**
| Commande | Effet |
|---|---|
| `spanning-tree portfast` | Fait passer un port directement en `forwarding` (au lieu des ~30 sec de convergence normale) — **uniquement sur un port relié à un hôte final**, jamais vers un autre switch |
| `[no] spanning-tree bpduguard enable` | (Dés)active BPDU Guard sur un port : coupe automatiquement (`err-disabled`) un port non-trunk qui reçoit un BPDU (signe qu'un switch non autorisé y a été branché) |
| `spanning-tree portfast default` | Active PortFast sur tous les ports éligibles |
| `spanning-tree portfast bpduguard default` | Active BPDU Guard sur tous les ports déjà en PortFast |

**Repères théoriques :**
- **BID (Bridge ID)** = priorité (32768 par défaut) + numéro de VLAN ; le plus faible l'emporte pour devenir Root Bridge ; en cas d'égalité, l'adresse MAC la plus "petite" tranche.
- **IEEE 802.1D** (STP original, lent) → **802.1w / RSTP** (rapide) → **PVST+** (Cisco, une instance par VLAN, activé par défaut) → **MST** (Cisco, une instance pour plusieurs VLANs).
- Méthodologie de dépannage : 1) connaître la topologie L2, 2) déterminer qui *devrait* être root, 3) vérifier que c'est le cas, 4) visiter chaque switch pour confirmer les ports bloqués/forwarding.

---

## 11. Router-on-a-stick (routage inter-VLAN sur routeur)

| Commande | Effet |
|---|---|
| `interface TYPE N°.SOUS-N°` | Crée une sous-interface (ex. `g0/0.10`) |
| `encapsulation dot1q N°VLAN` | Associe la sous-interface à un VLAN, active le tag 802.1Q (mode trunk uniquement) |
| `show vlans` (pluriel) | VLANs + sous-interfaces en mode router-on-a-stick — **non simulé sur Packet Tracer**, utiliser `show ip interface brief` + `show interface <sous-interface>` à la place |

---

## 12. Sécurisation des accès (mots de passe, chiffrement)

| Commande | Effet |
|---|---|
| `password MOT_DE_PASSE` (dans `line console 0` ou `line vty`) | Définit le mot de passe d'une ligne |
| `login` (dans `line console 0` ou `line vty`) | **Active la vérification du mot de passe** — sans cette commande, le mot de passe défini n'est jamais demandé |
| `login local` (dans `line vty`) | Authentification via la base d'utilisateurs locale (`username`) plutôt qu'un simple mot de passe de ligne |
| `enable secret MOT_DE_PASSE` | Mot de passe du mode privilégié, **haché automatiquement** (plus sûr que `enable password`, à éviter) |
| `service password-encryption` | Chiffre tous les mots de passe en clair du fichier de configuration (sauf `enable secret`, déjà haché) |
| `username NOM secret MDP` | Crée un compte dans la base d'utilisateurs locale |
| `username NOM privilege 15 secret MDP` | Idem, avec accès administrateur complet (niveau 15) |

---

## 13. Accès distant (Telnet / SSH)

| Commande | Effet |
|---|---|
| `transport input ssh` | Restreint les lignes VTY au SSH uniquement (bloque Telnet de fait) |
| `transport input telnet` (ou rien, par défaut) | Autorise Telnet — **à proscrire en production**, mots de passe envoyés en clair |
| `ip domain name NOM` (ou `ip domain-name`) | Nom de domaine requis pour générer la clé SSH |
| `crypto key generate rsa` | Génère la paire de clés RSA nécessaire au chiffrement SSH (peut demander la taille de clé, ex. 1024, via prompt séparé) |
| `crypto key generate rsa general-keys modulus 1024` | Idem, avec taille de clé précisée directement dans la commande |
| `ip ssh version 2` | Force la version 2 de SSH (plus sûre que le mode de compatibilité 1.99) |
| `ip ssh time-out SECONDES` | Délai d'attente avant échec d'authentification SSH |
| `ip ssh authentication-retries NOMBRE` | Nombre de tentatives d'authentification SSH autorisées |
| `show ip ssh` | Affiche la config SSH active (version, tentatives, timeout) |

**Côté client (PC) :**
| Commande | Effet |
|---|---|
| `ssh -l UTILISATEUR IP` | Ouvre une session SSH vers l'appareil |
| `telnet IP` | Ouvre une session Telnet vers l'appareil |

---

## 14. Ports inutilisés et services non sécurisés

| Commande | Effet |
|---|---|
| `interface range TYPE N°-N°` puis `shutdown` | Désactive un lot de ports d'un coup |
| `no ip http server` | Désactive le serveur web non chiffré du switch |
| `show ip http server status` | Vérifie l'état des serveurs HTTP/HTTPS — **non simulé sur Packet Tracer** |

---

## 15. Port Security (protection par adresse MAC)

| Commande | Effet |
|---|---|
| `switchport port-security` | Active la sécurité de port sur l'interface (mode access requis au préalable) |
| `switchport port-security maximum N` | Nombre maximum d'adresses MAC autorisées sur le port (défaut : 1) |
| `switchport port-security mac-address MAC` | Fige une adresse MAC précise et autorisée sur le port |
| `switchport port-security mac-address sticky` | Apprend et fige automatiquement la/les première(s) adresse(s) MAC vue(s) sur le port |
| `switchport port-security violation MODE` | Politique en cas de MAC non autorisée : `shutdown` (coupe le port, défaut), `restrict` (rejette + logue + compteur), `protect` (rejette silencieusement) |
| `show port-security` | Vue synthétique de tous les ports sécurisés (compteurs, violations, action) |
| `show port-security interface PORT` | Détail d'un port : statut (`Secure-up`/`Secure-shutdown`), MAC configurée, compteur de violations |
| `show port-security address` | Table des adresses MAC sécurisées, par port |

---

## 16. Table des adresses MAC

| Commande | Effet |
|---|---|
| `show mac address-table` | Table complète des adresses MAC apprises (dynamiques + statiques) |
| `show mac address-table dynamic` | Uniquement les entrées apprises automatiquement |
| `show mac address-table static` | Uniquement les entrées figées manuellement |
| `show mac address-table ?` | Liste les sous-options disponibles (`dynamic`, `interfaces`, `static`) |
| `clear mac address-table dynamic` | Efface toutes les entrées dynamiques (elles seront réapprises au prochain trafic) |
| `mac address-table static MAC vlan N interface TYPE N°` | Fige manuellement une entrée MAC↔port↔VLAN |
| `no mac address-table static MAC vlan N interface TYPE N°` | Retire une entrée MAC statique |

---

## 17. Diagnostic réseau (routeur et switch)

| Commande | Effet |
|---|---|
| `show ip route` | Table de routage (routes connectées `C`, statiques `S`, etc.) |
| `show cdp neighbors` | Liste les appareils Cisco voisins directement connectés, avec le port local et distant utilisé — précieux pour vérifier le câblage réel |
| `mac-address MAC` (sur une interface) | Force une adresse MAC personnalisée sur l'interface (utile en test pour simuler une violation de sécurité) |
| `no mac-address MAC` | Retire l'adresse MAC forcée, revient à la MAC physique (bia) d'origine |

---

## 18. Réinitialiser un port en erreur (`err-disabled`)

Qu'elle vienne de Port Security ou de BPDU Guard, une interface en `err-disabled` **ne se réactive jamais automatiquement**, même après avoir retiré la cause du problème.

```
interface PORT
shutdown
no shutdown
```

---

## 19. Diagnostic côté PC (client)

| Commande | Effet |
|---|---|
| `ping IP` | Teste la connectivité vers une IP |
| `ipconfig /all` | Affiche la config réseau complète du PC (IP, masque, passerelle, MAC) |
| `tracert IP` | Trace le chemin réseau vers une IP, utile pour repérer une absence de route |

---

## Notes générales sur Packet Tracer

- Certaines commandes `show` complexes ou abrégées échouent (`show running-config interface fa0/1` en version courte, `show vlans` au pluriel, `show ip http server status`) → utiliser la forme longue (`show running-config interface FastEthernet0/1`), ou repérer l'info dans `show running-config` complet, ou utiliser une commande équivalente (`show spanning-tree interface X detail` pour PortFast, `show ip interface brief` pour les sous-interfaces).
- Les commandes `debug` (ex. `debug spanning-tree events`) ne sont généralement **pas simulées**.
- Les éditions IOS proposées sont basiques (comparable à LAN Base).
- Packet Tracer peut planter → sauvegarder régulièrement (`copy running-config startup-config`).
