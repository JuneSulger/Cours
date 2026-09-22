# TP Physique — Configuration initiale d'un switch réel (Rack Cisco)

**Réalisé par :** June Sultan-Gerej
**Matériel utilisé :** Switch Cisco Catalyst 2960-Plus, étiquette **B01551**, renommé **S4**
**Méthode de connexion :** Câble console (RJ45 ↔ USB) pour l'initialisation, puis **SSH** à distance

---

## Consigne de l'exercice

- Connectez-vous à un switch ou routeur réel
- Remettez-le en conf d'usine
- Déterminez la version IOS tournant dessus
- Déterminez les interfaces disponibles
- Déterminez les lignes VTY disponibles
- Changez son nom
- Mettez un long délai avant déconnexion par inactivité
- Empêchez les recherches DNS indésirables (`no ip domain-lookup`)
- Empêchez les évènements d'interrompre votre frappe (`logging synchronous`)
- Modifiez la taille de l'historique des commandes
- Sauvegardez la conf pour qu'elle s'applique au démarrage
- Mettez un mot de passe sur le port console
- Appliquez une bannière MOTD au port console

---

## Contexte matériel (rack)

| Appareil | Référence | Rôle |
|----------|-----------|------|
| Switch S4 | B01551 | Switch utilisé pour ce TP |
| Switch (collègue) | B01552 | Configuré en parallèle par un collègue |
| Switch (config existante) | B01553 | **À ne pas toucher** — config déjà réalisée par le formateur (Gilles) |
| Routeurs R1/R2/R3 | B01533 / B01534 / B01535 | Non utilisés pour ce TP |

> Un seul câble console étant disponible pour plusieurs personnes, la stratégie retenue a été : utiliser le câble console **brièvement** pour l'initialisation et l'activation de SSH, puis **rendre le câble** et poursuivre la configuration à distance.

---

## Étape 1 : Connexion physique initiale (câble console)

- Câble console RJ45 (switch) ↔ USB (PC), branché sur le port **CONSOLE** du switch B01551
- Port COM identifié via le **Gestionnaire de périphériques Windows** (section "Ports COM et LPT")
- Connexion établie avec **PuTTY**, mode **Serial** :
  - Serial line : port COM détecté
  - Speed : **9600**

---

## Étape 2 : Remise en configuration d'usine ✅

```
Switch> enable
Switch# erase startup-config
```
→ Confirmation avec Entrée → `Erase of nvram: complete`

```
Switch# delete vlan.dat
```
→ `Error deleting flash:/vlan.dat (No such file or directory)` — normal, aucun fichier vlan.dat présent au préalable.

```
Switch# reload
Proceed with reload? [confirm]
System configuration has been modified. Save? [yes/no]: no
```

Redémarrage effectué, boîte de dialogue de configuration initiale passée (Entrée).

---

## Étape 3 : Changement de nom ✅

```
Switch> enable
Switch# configure terminal
Switch(config)# hostname S4
```

---

## Étape 4 : Configuration SSH pour permettre l'accès à distance ✅

> Nécessaire pour libérer le câble console et continuer le TP sans matériel physique partagé.

```
S4(config)# ip domain-name cisco
S4(config)# crypto key generate rsa modulus 1024
```
→ Résultat : `%SSH-5-ENABLED: SSH 2.0 has been enabled`

```
S4(config)# username admin secret cisco123
S4(config)# interface vlan 1
S4(config-if)# ip address 192.168.10.4 255.255.255.0
S4(config-if)# no shutdown
S4(config-if)# exit
S4(config)# line vty 0 4
S4(config-line)# transport input ssh
S4(config-line)# login local
S4(config-line)# exit
S4(config)# ip ssh version 2
```

**Sauvegarde intermédiaire effectuée** (pour sécuriser cette première partie de config) :
```
S4(config)# end
S4# copy running-config startup-config
```

---

## Étape 5 : Dépannage de connectivité réseau (SSH inaccessible) ✅ résolu

**Symptôme initial :** `ping 192.168.10.4` et connexion SSH échouaient (`Connection timed out`), alors que le switch était bien configuré.

**Diagnostic :**
- `ipconfig /all` a révélé que le PC utilisait une IP DHCP (`10.10.28.5`) sur le réseau `pedagogique.lan`, totalement différent du réseau du rack (`192.168.10.0/24`).
- `tracert 192.168.10.4` confirmait que le PC ne trouvait aucune route directe vers ce sous-réseau.

**Causes identifiées et corrigées :**
1. Le PC n'avait pas d'IP fixe dans le bon sous-réseau → **IP statique configurée sur la carte Ethernet du PC**
2. Des **VM locales avaient des IP en conflit** avec celles utilisées pour le labo → commutateurs virtuels désactivés
3. Ajustement final des adresses pour éviter tout conflit :

| Appareil | Adresse IP |
|----------|------------|
| Switch S4 (VLAN1) | 192.168.10.4 |
| PC (carte Ethernet, IP fixe) | 192.168.10.14 |

**Résultat : connexion SSH établie avec succès** depuis PuTTY (`192.168.10.4`, port 22, utilisateur `admin`).

---

## État d'avancement à l'arrêt de la session

✅ **Fait :**
- Connexion à un switch réel
- Remise en config d'usine
- Changement de nom (`S4`)
- Configuration et validation de l'accès SSH à distance
- Résolution complète du problème de connectivité réseau PC ↔ switch

⏳ **Restant à faire** (reprendre ici à la prochaine session, via SSH, plus besoin du câble console) :

### Déterminer la version IOS
```
S4# show version
```

### Déterminer les interfaces disponibles
```
S4# show ip interface brief
```

### Déterminer les lignes VTY disponibles
```
S4# show running-config | include line vty
```
(ou, si la syntaxe filtrée ne fonctionne pas sur ce modèle : `show running-config` puis repérer manuellement la ligne `line vty 0 4`)

### Long délai avant déconnexion par inactivité
```
S4# configure terminal
S4(config)# line console 0
S4(config-line)# exec-timeout 60
S4(config-line)# exit
```

### Empêcher les recherches DNS indésirables
```
S4(config)# no ip domain-lookup
```
> À vérifier si déjà appliqué lors de la session précédente — à confirmer avec `show running-config`.

### Empêcher les évènements d'interrompre la frappe
```
S4(config)# line console 0
S4(config-line)# logging synchronous
S4(config-line)# exit
```

### Modifier la taille de l'historique des commandes
```
S4(config)# line console 0
S4(config-line)# history size 50
S4(config-line)# exit
```

### Mot de passe sur le port console
```
S4(config)# line console 0
S4(config-line)# password cisco
S4(config-line)# login
S4(config-line)# exit
```

### Bannière MOTD sur le port console
```
S4(config)# banner motd #
Accès non autorisé strictement interdit.#
```

### Sauvegarde finale de la configuration
```
S4(config)# end
S4# copy running-config startup-config
```

---

## Points de vigilance pour la suite

- Se reconnecter en **SSH** (`192.168.10.4`, port 22, utilisateur `admin`) — plus besoin du câble console pour cette partie.
- Vérifier si `no ip domain-lookup` a déjà été appliqué avant de le refaire.
- Faire la sauvegarde finale (`copy running-config startup-config`) une fois **toutes** les étapes restantes terminées, pour capturer l'ensemble de la configuration en une fois.

---

*Compte-rendu arrêté ici — à reprendre à la prochaine session.*
