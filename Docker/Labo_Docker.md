# Labo Docker — Installation, conteneurs et démonstration SSH

> Environnement : Ubuntu 26.04 (VM Linux), Docker Engine installé via le dépôt `apt` officiel.

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
