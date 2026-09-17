# Docker — Volume exploitant un système de fichiers distant (NFS)

> Supports de cours : *Mettre en place un serveur NFS pour l'exercice qui suit* + *Création d'un volume exploitant un système de fichiers distant* (Cédric Surquin, Technocité)

---

## 0. Infrastructure

Deux VMs Ubuntu Server LTS créées sous **Hyper-V** (Génération 2), reliées par un **switch virtuel existant réutilisé**, sur le même réseau afin d'éviter tout problème de routage :

| VM | Hostname | Rôle | Adresse IP |
|---|---|---|---|
| VM 1 | `lab-nfs` | Serveur NFS | `192.168.100.10` |
| VM 2 | `lab-docker` | Hôte Docker | `192.168.100.11` |

- Subnet : `192.168.100.0/24`
- Gateway : `192.168.100.1`
- Name server : `127.0.0.1, 8.8.8.8`
- Utilisateur : `june` (minuscules — convention Unix standard pour les usernames)
- Hostnames en minuscules-tirets (`lab-nfs`, `lab-docker`) — convention DNS/Unix, contrairement aux noms `LAB_NFS`/`LAB_DOCKER` initialement envisagés (majuscules + underscore non recommandés pour un hostname)
- Installation Ubuntu Server : option **"Install OpenSSH server"** cochée pour permettre une administration à distance sans dépendre de la console Hyper-V
- Secure Boot laissé activé (contrairement à Debian, Ubuntu démarre sans souci en Gen 2 avec Secure Boot grâce à sa signature Microsoft)

---

## 1. Partie 1 — Mise en place du serveur NFS (sur `lab-nfs`)

### Étape 1 — Installation du service NFS

```bash
sudo apt update
sudo apt install nfs-kernel-server
sudo systemctl status nfs-kernel-server
```

### Étape 2 — Création du répertoire partagé

```bash
sudo mkdir -p /srv/nfs/docker
sudo chmod 777 /srv/nfs/docker
```

> Permissions larges (`777`) utilisées uniquement à des fins pédagogiques, pour rester concentré sur NFS/Docker — à éviter en production.

### Étape 3 — Déclaration de l'export NFS

```bash
sudo nano /etc/exports
```

Ligne ajoutée :
```
/srv/nfs/docker 192.168.100.0/24(rw,sync,no_subtree_check)
```

### Étape 4 — Rechargement de la configuration

```bash
sudo exportfs -ra
sudo exportfs -v
```

Résultat obtenu :
```
/srv/nfs/docker
                192.168.100.0/24(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
```

### Étape 5 — Vérification de l'adresse IP du serveur

```bash
ip -br address
```
→ confirmé : `eth0` en `UP`, adresse `192.168.100.10/24`.

### Étape 6 — Test de connectivité depuis `lab-docker`

```bash
ping 192.168.100.10
```
→ ping réussi, confirmant que les deux VMs se voient bien sur le réseau.

---

## 2. Partie 2 — Création du volume Docker exploitant le partage NFS (sur `lab-docker`)

### Étape 0 — Prérequis non mentionnés dans le PDF

**⚠️ Point relevé** : le support de cours ne précise à aucun moment qu'il faut installer Docker et le client NFS sur la machine `lab-docker` — l'énoncé part du principe que c'est déjà en place. Deux installations ont donc été nécessaires en cours de route :

```bash
sudo apt update
sudo apt install docker.io -y      # Docker Engine (absent au départ → "sudo: 'docker': command not found")
sudo apt install nfs-common -y     # client NFS (absent au départ → montage impossible)
```

### Étape 1 — Création du volume Docker (driver `local` + options NFS)

```bash
sudo docker volume create --driver local \
--opt type=nfs \
--opt o=addr=192.168.100.10,rw \
--opt device=:/srv/nfs/docker \
my_nfs_volume
```

- Retour à la ligne via `\` en fin de ligne (aucun espace après, sinon bash considère la commande comme terminée)
- `--opt o=addr=...` → adresse IP du serveur NFS
- `--opt device=:/chemin` → chemin exporté côté serveur (le `:` initial fait partie de la syntaxe NFS classique `serveur:chemin`)

**⚠️ Erreur rencontrée** : première tentative avec les valeurs d'exemple du PDF recopiées telles quelles (`addr=192.168.1.100`, `device=:/path/to/nfs/share`) au lieu des valeurs réelles de l'infrastructure (`192.168.100.10`, `/srv/nfs/docker`). Corrigé en adaptant la commande à l'adressage réel.

Vérification :
```bash
sudo docker volume ls
```

### Étape 2 — Montage du volume dans un conteneur

```bash
sudo docker run -d --name nfs_test --mount source=my_nfs_volume,target=/app busybox sleep infinity
```

**⚠️ Erreur rencontrée (1/2)** : `error while mounting volume ... connection refused` → causée par l'absence du client `nfs-common` sur `lab-docker` (voir Étape 0). Résolu après installation du paquet ; un montage manuel de test a permis de confirmer :
```bash
sudo mkdir -p /mnt/test-nfs
sudo mount -t nfs 192.168.100.10:/srv/nfs/docker /mnt/test-nfs
df -h | grep test-nfs   # confirme le montage
sudo umount /mnt/test-nfs
```

**⚠️ Erreur rencontrée (2/2)** : en suivant la commande du PDF à la lettre (`docker run -d --name CONTENEUR --mount source=my_nfs_volume,target=/app busybox`, sans commande finale), le conteneur démarrait puis s'arrêtait **immédiatement** — `busybox` sans argument lance son `sh` par défaut, qui se termine aussitôt faute de terminal interactif attaché (`-it` absent avec `-d`). `docker ps` restait donc vide, et même un `docker start` suivi d'un `exec -it` échouait car le conteneur s'arrêtait plus vite que la commande `exec` ne pouvait s'exécuter.
Solution retenue : ajouter `sleep infinity` à la fin de la commande `docker run` pour garder le conteneur actif en arrière-plan — même logique que pour `My_Debian` dans le TD précédent sur les volumes locaux.

### Étape 3 — Entrer dans le conteneur

```bash
sudo docker exec -it nfs_test sh
```

### Étape 4 — Génération de données dans le volume

```bash
echo "Hello !" > /app/hello.txt
exit
```

**⚠️ Erreur rencontrée** : le PDF utilise des guillemets typographiques français `« »` (`echo « Hello ! »`), non interprétés par bash — génère une erreur de syntaxe. Remplacés par des guillemets doubles standards `"` `"`.

### Étape 5 — Arrêt et suppression du conteneur

```bash
sudo docker stop nfs_test
sudo docker rm nfs_test
```

### Étape 6 — Vérification de la persistance côté serveur NFS

Sur `lab-nfs` :
```bash
ls /srv/nfs/docker
cat /srv/nfs/docker/hello.txt
```
→ `hello.txt` bien présent, malgré la suppression du conteneur. Confirme que les données générées dans le conteneur sont réellement persistées sur le stockage distant via NFS.

---

## Points clés à retenir

- Un volume Docker peut s'appuyer sur un système de fichiers **distant** via `--driver local` combiné aux options `--opt type=nfs`, `--opt o=addr=...`, `--opt device=:/chemin` — le driver reste `local`, seul le backend de stockage change.
- Le client NFS (`nfs-common`) doit être installé sur la machine hôte Docker, en plus du serveur NFS (`nfs-kernel-server`) sur la machine distante — souvent omis des énoncés qui supposent l'environnement déjà prêt.
- Une image minimaliste comme `busybox`, lancée en arrière-plan (`-d`) sans commande de premier plan durable, s'arrête instantanément — toujours lui fournir une commande bloquante (`sleep infinity`) si on veut la garder active pour y entrer ensuite.
- Toujours reproduire les guillemets/valeurs d'un PDF avec prudence : guillemets typographiques (`« »`) et adresses/chemins d'exemple doivent être adaptés en guillemets standards et valeurs réelles avant exécution.
- La convention Unix pour les hostnames et usernames est minuscules (+ tirets pour les hostnames, jamais d'underscore ni de majuscule).
- La persistance des données au-delà du cycle de vie du conteneur est ici démontrée à deux niveaux : sur un volume local (TD précédent) et sur un stockage réseau distant via NFS (ce TD) — le principe reste identique, seul le support physique change.

---

## En résumé — qu'a-t-on fait, et à quoi ça sert ?

**Ce qu'on a construit :** deux machines virtuelles distinctes sur le même réseau — l'une (`lab-nfs`) jouant le rôle de **serveur de stockage**, l'autre (`lab-docker`) hébergeant le **moteur Docker**. La première partage un répertoire via le protocole **NFS** (Network File System), un protocole qui permet à un système de fichiers physiquement situé sur une machine d'être monté et utilisé comme s'il était local, depuis une autre machine du réseau. La seconde a ensuite créé un **volume Docker** qui, au lieu de stocker ses données sur son propre disque, les écrit directement sur ce partage réseau distant.

**Ce que ça change concrètement :** dans le TD précédent (volume local), les données d'un conteneur survivaient à sa suppression, mais restaient **physiquement liées à la machine hôte** qui l'exécutait. Ici, elles sont écrites sur une **machine complètement séparée** — le conteneur peut donc être détruit, recréé, voire déplacé sur une toute autre machine Docker connectée au même réseau, et retrouvera toujours ses données au même endroit, puisqu'elles ne dépendent plus du disque local d'un hôte en particulier.

**À quoi ça sert en pratique :** c'est le principe de base derrière le **stockage centralisé** en environnement de production. Concrètement, ça permet par exemple :
- de faire tourner plusieurs conteneurs Docker sur différents serveurs tout en leur donnant accès aux **mêmes données partagées** (fichiers de configuration, uploads utilisateurs, etc.)
- de **remplacer ou reconstruire une machine Docker** sans perdre aucune donnée, puisqu'elles vivent ailleurs
- de préparer le terrain pour des architectures plus avancées (clusters, haute disponibilité, migration de charge d'un serveur à l'autre) où les conteneurs doivent pouvoir être redémarrés n'importe où sans dépendre du disque d'une machine précise
