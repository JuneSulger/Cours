# Labo Docker — Installation, conteneurs et démonstration SSH

> Environnement : Ubuntu 26.04 (VM Linux), Docker Engine installé via le dépôt `apt` officiel.
> Rappels théoriques basés sur les supports de cours (CPU, virtualisation, Docker — Technocité).

---

## 0. Rappels théoriques du cours

### Le CPU (processeur)

- Le CPU (*Central Processing Unit*) est le composant qui exécute les opérations arithmétiques et le traitement de données — le « cerveau » de la machine. Concrètement, c'est une puce de silicium gravée de milliards de transistors ; plus la gravure est fine (nanomètres), plus le CPU est efficace et économe en énergie.
- Tous les CPU ne partagent pas la même **architecture** (jeu d'instructions), et ces architectures sont incompatibles entre elles. Les deux principales aujourd'hui :
  - **x86_64** (aka `amd64`) : architecture classique des PC (Intel, AMD)
  - **ARM** (aka `aarch64`) : architecture classique des smartphones, et de plus en plus des Mac (puces M1/M2)
- Un logiciel compilé pour une architecture ne fonctionne pas nativement sur une autre, sauf via un **émulateur** ou une couche de traduction (ex. Rosetta chez Apple pour faire tourner du x86_64 sur ARM, avec une perte de performance).
- Historiquement, la puissance d'un CPU se mesurait en fréquence (MHz puis GHz). Depuis 2006, cette course a atteint ses limites physiques ; on combine désormais plusieurs facteurs : fréquence, nombre de cœurs, nombre de transistors, finesse de gravure. L'unité de mesure moderne est le **FLOPS** (opérations en virgule flottante par seconde), qui donne une mesure théorique de la vitesse de pointe.
- Un CPU moderne est **multi-cœurs** : plusieurs cœurs physiques dans une même puce, parfois complétés par des cœurs « virtuels » via l'**HyperThreading** (gain de l'ordre de 30 %). Un logiciel conçu pour exploiter plusieurs cœurs à la fois est dit **multi-threadé**.
- Sur un CPU de PC de bureau, le processeur est en général changeable (« clipsé » sur un socket) ; sur la quasi-totalité des ordinateurs portables, il est soudé à la carte mère.
- Ce point est directement lié à Docker : une image construite pour `amd64` ne tournera pas nativement sur une machine `arm64` (et inversement) sans émulation — un point de vigilance quand on télécharge une image depuis le Docker Hub sur des architectures différentes (ex. Raspberry Pi vs PC).

### La virtualisation

- **Concept** : exécuter un ou plusieurs systèmes d'exploitation (potentiellement d'éditeurs différents) à l'intérieur d'un autre système d'exploitation, chacun isolé des autres.
- **Vocabulaire** : la machine qui héberge s'appelle l'**hyperviseur** (ou « hôte de virtualisation ») ; les machines virtuelles exécutées sont les **invités de virtualisation**.
- Deux types d'hyperviseurs :
  - **Type 1** : tourne directement sur un système hôte minimaliste dédié à la virtualisation (ex. VMware ESX).
  - **Type 2** : tourne comme une application au sein d'un système hôte complet déjà utilisé pour autre chose (ex. VirtualBox sur une machine de bureau classique).
- Avantages classiques d'un hyperviseur : isolation entre VM et vis-à-vis de l'hôte, pause/reprise, exécution en tâche de fond, clonage complet ou partiel (**snapshot**, qui ne stocke que les différences par rapport à l'état de référence), import/export sous forme de fichier unique portable, dossiers partagés, presse-papier partagé, réseau isolé ou mutualisé entre VM. Les hyperviseurs avancés permettent aussi le **PassThrough** : dédier un périphérique physique (disque, carte réseau, GPU) à une VM avec un accès exclusif et des performances natives.
- Pré-requis matériels : un CPU supportant les technologies d'accélération de virtualisation (**Intel-VT** ou **AMD-VX**), activées dans le BIOS/UEFI, plus suffisamment de RAM et d'espace disque.
- Trois grandes familles de virtualisation :
  - **Virtualisation complète** : la plus simple à mettre en œuvre, simule du matériel pour l'OS invité, mais uniquement pour une architecture CPU identique à l'hôte (ex. Oracle VirtualBox, VMware Workstation, Parallels Desktop, KVM).
  - **Para-virtualisation** : le système invité *sait* qu'il est virtualisé (noyau modifié), et communique plus directement avec l'hôte via des pilotes spécifiques (ex. virtio) — performances bien supérieures (ex. VMware ESX, Microsoft Hyper-V, KVM avec paquets additionnels).
  - **Isolateurs / conteneurs** : la famille à laquelle appartient Docker — voir plus bas.

### Docker — concepts et commandes de base (complément au cours)

- `docker info` : donne l'état général du moteur Docker (nombre de conteneurs, running/paused/stopped, nombre d'images, version du serveur).
- Le **Dockerfile** d'`hello-world` illustre le principe de construction d'une image :
  ```
  FROM scratch        # image qui ne repose sur aucune autre image
  COPY hello /        # copie le binaire "hello" à la racine du conteneur
  CMD ["/hello"]       # exécute ce binaire au démarrage du conteneur
  ```
  Avant d'exécuter le programme, Docker crée un conteneur avec son propre espace de nommage et ses propres ressources, un système de fichiers isolé (via `chroot`), et lui applique un driver réseau.
- **Le Docker Hub** (`hub.docker.com`, anciennement « docker store ») est le dépôt central et officiel d'images Docker. Il comporte une section d'images officiellement vérifiées (parfois avec support ou licence payante) et une section communautaire plus fournie mais moins fiable.
  - Rechercher une image depuis la CLI : `docker search --filter=stars=15 ubuntu`
  - Télécharger sans exécuter : `docker pull NOM_DE_L'IMAGE`
  - Publier une image sur le registre public : `docker push NOM_DE_L'IMAGE` (nécessite un compte gratuit sur le Docker Hub)
  - Se connecter / déconnecter en CLI : `docker login` / `docker logout`
- **Docker Desktop** (Windows/macOS/Linux) s'appuie sur WSL 2 sous Windows — contrairement à son prédécesseur Docker-Toolbox qui installait une VM Linux complète via VirtualBox. Les interfaces graphiques de gestion de conteneurs ne remplacent pas la maîtrise de la CLI, qui reste l'objectif pédagogique du cours.

### Commandes complémentaires vues en cours (non pratiquées dans ce labo)

| Commande | Usage |
|---|---|
| `docker ps` / `docker ps --all` | Conteneurs en cours / tous les conteneurs (y compris arrêtés) |
| `docker images` | Lister les images téléchargées localement |
| `docker (un)pause NOM` | Met en pause / reprend un conteneur |
| `docker update NOM` | Modifie les ressources CPU/mémoire allouées à un conteneur |
| `docker restart NOM` | Redémarre un conteneur en cours |
| `docker kill -s 9 NOM` | Tue le conteneur immédiatement, sans lui laisser terminer sa tâche (contrairement à `stop`) |
| `docker logs NOM` | Consulter les journaux d'un conteneur |
| `docker logs --follow NOM` | Suivre les journaux en continu |
| `docker logs --tail 10 NOM` | Afficher les 10 dernières lignes du journal |
| `docker events` | Voir les évènements du moteur Docker en temps réel |
| `docker stats NOM` (`--no-stream`) | Monitorer les ressources consommées par un conteneur (vue instantanée avec `--no-stream`) |
| `docker rename NOM` | Renommer un conteneur |
| `docker cp Container:SRC DEST` | Copier un fichier/dossier entre conteneur et hôte |
| `docker export NOM > fichier.tar` | Exporter l'entièreté du système de fichiers d'un conteneur |
| `docker diff NOM` | Consulter les modifications apportées à un conteneur par rapport à son image de base |
| `docker commit NOM_IMAGE MA_NOUVELLE_IMAGE` | Sauvegarder les modifications d'un conteneur dans une nouvelle image locale (ne publie pas sur le Hub ; n'enregistre que la différence avec l'image de base) |
| `docker rm NOM` | Supprimer un conteneur (après arrêt) |
| `docker system prune` | Nettoyer toutes les images/conteneurs orphelins ou inutiles |
| `docker run --privileged` | Lance le conteneur avec les droits root étendus — ⚠️ à utiliser avec prudence |
| `docker run --name NOM` | Personnalise le nom d'une instance |
| `docker run --rm` | Supprime automatiquement le conteneur une fois stoppé |
| `docker run --volumes-from` | Hérite des volumes d'un autre conteneur |
| `docker run --volume-driver` | Choisit la technologie de gestion des volumes |

> **Rappel important** : le système de fichiers d'un conteneur est **immuable** par défaut — toute modification vit dans sa writable layer (cf. point clé n°8 de ce labo). `docker commit` est le mécanisme officiel pour figer ces modifications dans une nouvelle image réutilisable.

---

## 1. Installation de Docker Engine

Installation suivie depuis la [documentation officielle Docker](https://docs.docker.com/engine/install/ubuntu/), méthode recommandée : le dépôt `apt`.

### Désinstaller les anciens paquets

```bash
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc docker-buildx podman-docker containerd runc | cut -f1)
```

### Ajouter la clé GPG officielle de Docker

```bash
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

### Ajouter le dépôt apt de Docker

```bash
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
```

> **Note :** toute la commande (y compris le bloc entre `<<EOF` et `EOF`) se colle d'un seul coup dans le terminal, avec les retours à la ligne conservés. Les `$(...)` sont exécutés automatiquement par le shell (ex. détection automatique de la version — ici `resolute` pour Ubuntu 26.04 — et de l'architecture, `amd64`).

### Installer Docker Engine

```bash
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### Vérifier que le service tourne

```bash
sudo systemctl status docker
# si nécessaire :
sudo systemctl start docker
```

### Tester avec hello-world

```bash
sudo docker run hello-world
```

✅ Résultat obtenu : message *"Hello from Docker!"*, confirmant que le client a contacté le daemon, l'image a été téléchargée et exécutée, et la sortie a bien été streamée jusqu'au terminal.

---

## 2. Récupérer l'image Ubuntu (dernière version)

```bash
sudo docker pull ubuntu:latest
sudo docker images
```

---

## 3. Exécuter le conteneur, entrer dans son shell, supprimer `/home`

```bash
sudo docker run -it ubuntu bash
```

- `-i` : interactif (garde stdin ouvert)
- `-t` : alloue un pseudo-terminal

Une fois dans le conteneur (`root@<id>:/#`) :

```bash
rm -rf /home
```

- `-r` : récursif (obligatoire pour supprimer un dossier et son contenu)
- `-f` : force, sans confirmation

**⚠️ Erreur rencontrée :** `rm /home` (sans `-r`) renvoie `rm: cannot remove '/home': Is a directory` — `rm` seul ne supprime que des fichiers, pas des dossiers.

Vérification :

```bash
ls /
```

---

## 4. Sortir du conteneur sans le stopper + interface réseau hôte

Détachement du conteneur **sans** `exit` (qui l'aurait stoppé) :

**Ctrl+P** puis **Ctrl+Q**

Sur la VM hôte :

```bash
ip a
```

➡️ Une interface pont **`docker0`** est créée automatiquement par Docker (plage `172.17.0.0/16` typiquement), permettant d'isoler et de router le trafic entre les conteneurs et l'hôte.

**⚠️ Erreur rencontrée :** tentative avec `docker attach ubuntu:latest /bin/bash` → `docker attach requires 1 argument`. `attach` prend un **nom/ID de conteneur en cours d'exécution**, pas une image, et ne prend pas de commande en argument (contrairement à `run`).

---

## 5. Lister les conteneurs en cours d'exécution

```bash
sudo docker ps
```

➡️ Le conteneur Ubuntu apparaît toujours avec le statut `Up`, preuve qu'il continue de tourner en arrière-plan malgré la déconnexion.

---

## 6. Stopper proprement le conteneur

```bash
sudo docker stop <container_id>
```

Envoie un `SIGTERM` (arrêt propre, avec délai de grâce) plutôt qu'un `SIGKILL` immédiat.

**⚠️ Erreur rencontrée :** en tapant `<container_id>` avec les chevrons littéraux (`<`, `>`), bash renvoie `syntax error near unexpected token 'newline'` — `<` est un caractère spécial de redirection en bash. Il faut remplacer `<container_id>` par l'ID réel, sans les chevrons.

---

## 7. Démarrer en tant que démon

```bash
sudo docker start <container_id>
```

**⚠️ Confusion rencontrée :** `docker start -d <id>` → `unknown shorthand flag: 'd' in -d`. Le flag `-d` (detached) existe pour `docker run`, **pas** pour `docker start`. `docker start` est détaché **par défaut** : sans option, il démarre déjà en arrière-plan, sans interaction. Pour le rattacher au terminal, il faudrait au contraire ajouter `-a`/`-i` (logique inverse de `run`).

---

## 8. `/home` est-il de retour ?

```bash
sudo docker exec -it <container_id> bash
ls /
```

**Résultat : `/home` est toujours absent.**

**Pourquoi ?** Un conteneur possède sa propre couche de système de fichiers en écriture (*writable layer*), posée par-dessus l'image `ubuntu` d'origine, qui reste toujours immuable. `docker stop` puis `docker start` agissent sur le **même conteneur** (même ID) — sa writable layer, et donc la suppression de `/home`, est conservée. Ce n'est qu'en créant un **nouveau** conteneur (`docker run`) qu'on repart d'une image vierge, et que `/home` réapparaîtrait.

---

## 9. Nouveau conteneur interactif + rafraîchissement de la base logicielle

```bash
sudo docker run -it ubuntu bash
apt update
```

`apt update` rafraîchit uniquement le cache local des paquets disponibles (versions, dépendances) — il ne met à jour aucun logiciel installé.

**⚠️ Erreur de méthode évitée :** relancer `sudo docker run -it ubuntu bash` **depuis l'intérieur** d'un conteneur ne fonctionne pas — Docker n'est pas installé dans le conteneur lui-même. Il faut d'abord ressortir vers le shell de la VM hôte (`exit` ou Ctrl+P Ctrl+Q), puis relancer la commande depuis là.

---

## 10. Installer et exécuter fastfetch

```bash
apt install fastfetch -y
fastfetch
```

➡️ `fastfetch` affiche un résumé système (logo ASCII de la distribution + infos : OS, kernel, uptime, shell, CPU, mémoire...). Point notable : le **kernel affiché est celui de la VM hôte**, car les conteneurs partagent le noyau de l'hôte au lieu d'en avoir un propre — contrairement à une VM complète. Bonne illustration de la différence fondamentale entre conteneurisation et virtualisation.

---

## 11. Adresse IP du conteneur sans `iproute2`

```bash
hostname -I
```

➡️ Adresse notée (ex. `172.17.0.2`), sans avoir besoin d'installer `iproute2` pour disposer de `ip addr show`.

---

## 12. Nouvelle interface réseau sur l'hôte

```bash
ip addr show
```

➡️ En plus de `docker0`, une nouvelle interface virtuelle (type `veth...`) est créée spécifiquement pour le conteneur Ubuntu actif, faisant le pont entre le namespace réseau isolé du conteneur et `docker0`.

---

## 13. Démonstration SSH (pratiques volontairement dangereuses ⚠️)

> Cette section reproduit une démonstration de **mauvaises pratiques de sécurité** à des fins pédagogiques uniquement (root autorisé en SSH, authentification par mot de passe, pas de clés). À ne jamais reproduire en environnement réel.

### Installer et configurer sshd

```bash
sudo docker run -i ubuntu:latest -t /bin/bash
apt update && apt install openssh-server nano -y
nano /etc/ssh/sshd_config
```

Modifications dans `sshd_config` :

```
PermitRootLogin yes
PasswordAuthentication yes
```

**⚠️ Point de vigilance rencontré :** la ligne `PermitRootLogin` n'était pas commentée dans le fichier mais réglée sur `prohibit-password` (root autorisé uniquement par clé SSH). Il fallait donc **remplacer la valeur**, pas décommenter une ligne.

### Démarrer sshd sans systemd

Dans un conteneur, **systemd ne tourne pas** (PID 1 = `bash`, pas `init`). `service sshd restart` échoue :

```
grep: /etc/init.d/sshd: No such file or directory
sshd: unrecognized service
```

Solution : démarrage manuel du binaire.

```bash
mkdir -p /run/sshd
/usr/sbin/sshd
```

Vérification :

```bash
ps aux | grep sshd
```

### Mot de passe root

```bash
passwd
```

### Test de connexion SSH depuis l'hôte

Sortie du conteneur **sans l'arrêter** (Ctrl+P puis Ctrl+Q), puis depuis la VM hôte :

```bash
ssh root@172.17.0.2
```

---

## 14. Fin de l'exercice : arrêt et suppression du conteneur

```bash
exit               # dans le conteneur, pour le stopper
sudo docker ps      # vérifier qu'il n'apparaît plus comme actif
sudo docker ps -a   # retrouver son ID (statut "Exited")
sudo docker rm <container_id>
```

**⚠️ Erreur rencontrée :** `docker rm <id>` → `Error response from daemon: cannot remove container "...": container is running: stop the container before removing`. Le conteneur tournait encore (détachement précédent au lieu d'un `exit` complet). Deux solutions possibles :

```bash
# Option 1 — en deux étapes
sudo docker stop <container_id>
sudo docker rm <container_id>

# Option 2 — forcer directement
sudo docker rm -f <container_id>
```

---

## Points clés retenus

- **Image vs conteneur** : l'image est immuable ; le conteneur ajoute une couche writable par-dessus. `stop`/`start` conserve cette couche (même conteneur) ; `run` en crée une nouvelle (nouveau conteneur).
- **`attach` vs `exec`** : `attach` se raccroche au processus principal existant ; `exec` lance un nouveau processus dans un conteneur déjà actif.
- **`docker start` est détaché par défaut** — pas de flag `-d` nécessaire (contrairement à `run`).
- **Pas de systemd dans un conteneur minimal** — les démons doivent être lancés manuellement en exécutable.
- **Isolation réseau** : `docker0` (pont hôte) + une interface `veth` dédiée par conteneur actif.
- **Kernel partagé** entre hôte et conteneurs — différence fondamentale avec une VM complète.
- **Docker = conteneurs/isolateurs**, une des trois grandes familles de virtualisation aux côtés de la virtualisation complète et de la para-virtualisation — plus légère qu'une VM classique car elle ne simule pas de matériel et partage le noyau de l'hôte.
- **PID 1 dans un conteneur = l'application elle-même**, pas `systemd` comme sur un Linux classique. Un « service » Docker correspond en général à *un* processus applicatif, isolé dans *son propre* conteneur — d'où l'absence de `systemctl` et la nécessité de lancer les démons manuellement (ex. `/usr/sbin/sshd`) ou via `docker run --name`, un conteneur par service plutôt qu'un conteneur multi-services.
