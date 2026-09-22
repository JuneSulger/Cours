# Lab 1-1 / Travail Pratique — Démarrage et configuration initiale d'un Switch

**Date :** 06/04/23
**Intervenant :** Cédric Surquin
**Réalisé par :** June Sultan-Gerej
**Logiciel utilisé :** Cisco Packet Tracer

---

## Objectifs

1. Redémarrer le switch et vérifier les messages de configuration initiaux
2. Terminer la configuration initiale d'un switch Cisco Catalyst
3. Explorer l'aide sensible au contexte
4. Améliorer la convivialité de la CLI

---

## Topologie et adressage IP

| Appareils | Interfaces | Adresses IP | Masques de sous-réseau |
|-----------|------------|-------------|--------------------------|
| SW1       | VLAN 1     | 10.1.1.11   | 255.255.255.0            |
| PC1       | Connexion réseau locale (Ethernet) | 10.1.1.100 | 255.255.255.0 |

---

## Tâche 1 : Redémarrage du switch et vérification de l'absence de configuration

### Étape 1 : Mode d'exécution privilégié

```
Switch> enable
Switch#
```

### Étape 2 : Test d'une commande privilégiée depuis le mode utilisateur

```
Switch# disable
Switch> erase startup-config
```

**Résultat obtenu :**
```
% Invalid input detected at '^' marker.
```

**Quel était le résultat de l'utilisation de la commande dans un mode de privilège incorrect ?**
> La commande `erase startup-config` nécessite le mode d'exécution privilégié. Utilisée en mode utilisateur (`Switch>`), elle n'est pas reconnue — le switch renvoie une erreur `Invalid input`, car cette commande n'existe tout simplement pas à ce niveau de privilège.

### Étape 3 : Retour en mode privilégié

```
Switch> enable
Switch#
```

**Comment savez-vous que vous êtes désormais dans ce mode ?**
> Le prompt change et se termine par **`#`** au lieu de `>` — c'est l'indicateur visuel du mode d'exécution privilégié.

### Étape 4 : Effacement de la configuration de démarrage et du fichier vlan.dat

```
Switch# erase startup-config
```
→ `Erasing the nvram filesystem will remove all configuration files! Continue? [confirm]`
→ `Erase of nvram: complete`

```
Switch# delete vlan.dat
```
→ `Error deleting flash:/vlan.dat (No such file or directory)`

> Cette erreur est normale : aucun fichier `vlan.dat` n'existait encore en mémoire flash sur ce switch (aucun VLAN n'avait été créé auparavant dans cette simulation). Rien à supprimer, donc rien de problématique.

### Étape 5 : Redémarrage du switch

```
Switch# reload
Proceed with reload? [confirm]
System configuration has been modified. Save? [yes/no]: no
```

Après redémarrage, passage de la boîte de dialogue de configuration initiale (Entrée) :
```
Would you like to enter the initial configuration dialog? [yes/no]: [Entrée]
```

Le switch redémarre avec le prompt `Switch>` (nom par défaut).

**Comment savez-vous que le fichier startup-config a effectivement été effacé ?**
> Le switch redémarre avec le nom par défaut "Switch" (pas de nom personnalisé conservé), et on peut le confirmer explicitement avec :
> ```
> Switch> enable
> Switch# show startup-config
> ```
> Résultat : `startup-config is not present`

### Étape 6 : Informations matérielles du switch

```
Switch# show version
```

- **Numéro de modèle** : `WS-C2960-24TT-L`
- **Version Cisco IOS** : `15.0(2)SE4`
- **Mémoire vive (RAM)** : `65536K bytes` (~64 Mo)
- **Mémoire flash (configuration)** : `64K bytes of flash-simulated non-volatile configuration memory`

**Tâche 1 validée :**
- ✅ Switch redémarré
- ✅ Absence de configuration vérifiée après redémarrage

---

## Tâche 2 : Configuration du nom d'hôte et de l'adresse IP

### Étape 1 : Nom d'hôte

```
Switch# configure terminal
Switch(config)# hostname SW1
```

### Étape 2 : Adresse IP de l'interface VLAN1

```
SW1(config)# interface vlan 1
SW1(config-if)# ip address 10.1.1.11 255.255.255.0
SW1(config-if)# no shutdown
SW1(config-if)# exit
```

### Étape 3 : Configuration IP de PC1 et test de connectivité

| Paramètre | Valeur |
|-----------|--------|
| Adresse IP | 10.1.1.100 |
| Masque de sous-réseau | 255.255.255.0 |

```
C:\> ping 10.1.1.11
```
→ Ping réussi, connectivité de couche 3 confirmée.

**Tâche 2 validée :**
- ✅ Nouveau nom configuré sur le switch (`SW1`)
- ✅ IP attribuée à l'interface VLAN 1 (`10.1.1.11`)
- ✅ Adresse IP configurée sur PC1 (`10.1.1.100`)
- ✅ Ping de PC1 vers le VLAN1 de SW1 réussi

---

## Tâche 3 : Exploration de l'aide contextuelle

### Étape 1 : Liste des commandes disponibles

```
SW1> enable
SW1# ?
```

### Étape 2 : Réglage de l'heure et de la date via l'aide contextuelle

Exploration progressive avec `?` :
```
SW1# clock ?
SW1# clock set ?
SW1# clock set 14:30:00 ?
```

Commande finale construite :
```
SW1# clock set 14:30:00 21 September 2026
```

### Étape 3 : Vérification de l'heure configurée

```
SW1# show clock
```

### Étape 4 : Commentaire dans le fichier de configuration

```
SW1# configure terminal
SW1(config)# !cette commande change l'horloge sur le switch
```

> Le `!` en début de ligne indique à IOS qu'il s'agit d'un commentaire (non exécuté), utile pour documenter un fichier de configuration.

### Étape 5 : Raccourcis clavier de navigation

| Raccourci | Action |
|-----------|--------|
| Ctrl+A | Aller au début de la ligne |
| Ctrl+E | Aller à la fin de la ligne |
| Ctrl+B | Reculer d'un caractère |
| Ctrl+F | Avancer d'un caractère |

**Tâche 3 validée :**
- ✅ Aide contextuelle utilisée pour régler l'heure et la date
- ✅ Raccourcis de navigation dans la ligne de commande testés

---

## Tâche 4 : Amélioration de l'utilisabilité de la ligne de commande

### Étape 1 : Vérification de l'historique des commandes

```
SW1# show terminal
```
→ Historique activé, taille par défaut généralement de **10** lignes (ligne "History size" dans la sortie).

### Étape 2 : Augmentation de la taille de l'historique à 100 lignes

```
SW1# configure terminal
SW1(config)# line console 0
SW1(config-line)# history size 100
SW1(config-line)# end
SW1# show terminal
```
→ Vérification : taille de l'historique passée à **100**.

### Étape 3 : Désactivation de la recherche DNS

```
SW1(config)# no ip domain lookup
```

> Empêche le switch d'interpréter une commande mal orthographiée comme un nom de domaine et de tenter une résolution DNS (blocage de 5 à 10 secondes sinon).

### Étape 4 : Augmentation du délai d'inactivité (timeout) à 60 minutes

```
SW1(config)# line console 0
SW1(config-line)# exec-timeout 60
```

> Par défaut, la déconnexion automatique intervient après 10 minutes d'inactivité sur la ligne console.

### Étape 5 : Activation de `logging synchronous`

```
SW1(config-line)# logging synchronous
SW1(config-line)# end
```

> Empêche les messages système non sollicités d'interrompre la frappe en cours sur la ligne de commande.

### Étape 6 : Sauvegarde de la configuration

```
SW1# copy running-config startup-config
Destination filename [startup-config]? [Entrée]
Building configuration...
[OK]
```

**Tâche 4 validée :**
- ✅ Historique des commandes augmenté à 100 lignes
- ✅ Recherche DNS désactivée
- ✅ Timeout d'inactivité passé à 60 minutes
- ✅ `logging synchronous` activé
- ✅ Configuration sauvegardée dans le startup-config

---

## Tableau récapitulatif des commandes utilisées

| Commande | Description |
|----------|-------------|
| `? ou help` | Affiche la liste des commandes disponibles au niveau actuel |
| `clock set` | Configurer l'heure et la date de l'appareil |
| `configure terminal` | Entrer en mode de configuration globale |
| `copy running-config destination` | Copie la configuration courante vers une destination (ex. startup-config) |
| `delete NOM_FICHIER` | Supprime un fichier de la mémoire flash |
| `do command` | Exécute une commande d'un autre niveau, quel que soit le niveau actuel |
| `enable` | Passer en mode d'exécution privilégié |
| `end` | Met fin au mode de configuration |
| `erase startup-config` | Efface la configuration de démarrage |
| `exec-timeout NBR_MINUTES` | Définit le délai d'inactivité avant déconnexion automatique |
| `exit` | Met fin au mode de configuration courant |
| `history size number` | Change la taille de l'historique des commandes |
| `hostname NOM` | Change le nom de l'appareil |
| `interface vlan 1` | Entre dans l'interface VLAN1 pour lui assigner une IP |
| `ip address subnet-mask` | Applique une adresse IP et son masque à une interface |
| `line console 0` | Entre dans la configuration du port console |
| `logging synchronous` | Synchronise l'affichage des messages système avec la frappe clavier |
| `reload` | Redémarre l'appareil et relance Cisco IOS |
| `show clock` | Affiche la configuration temporelle de l'appareil |
| `show flash:` | Affiche le contenu de la mémoire flash |
| `show startup-config` | Affiche la configuration qui s'appliquera au démarrage |
| `show terminal` | Montre la configuration courante de la CLI |
| `show version` | Affiche la version de Cisco IOS et les infos matérielles |

---

*Fin du compte-rendu.*
