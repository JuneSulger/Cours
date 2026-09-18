# Lexique des commandes Docker – Formation Technocité

2026-09-18 · @Someone

Toutes les commandes rencontrées dans les 4 labos Docker (Introduction, Réseaux, Dockerfile, Volume NFS), classées dans l'ordre chronologique habituel d'une session de travail : installation → images → conteneurs → réseaux → volumes → build → diagnostic/pare-feu → nettoyage.

## 1. Installation de Docker Engine (dépôt apt officiel)

| Commande | Explication |
| --- | --- |
| `sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc docker-buildx podman-docker containerd runc \| cut -f1)` | Désinstalle les anciens paquets Docker/Podman pour repartir d'une base propre |
| `sudo apt update` | Rafraîchit le cache local des paquets apt disponibles |
| `sudo apt install ca-certificates curl` | Installe les prérequis nécessaires pour ajouter le dépôt Docker |
| `sudo install -m 0755 -d /etc/apt/keyrings` | Crée le dossier de stockage des clés GPG apt |
| `sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc` | Télécharge la clé GPG officielle de Docker |
| `sudo chmod a+r /etc/apt/keyrings/docker.asc` | Rend la clé GPG lisible par tous |
| `sudo tee /etc/apt/sources.list.d/docker.sources <<EOF ... EOF` | Déclare le dépôt apt officiel de Docker (version Ubuntu et architecture détectées automatiquement) |
| `sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin` | Installe Docker Engine et ses plugins (buildx, compose) |
| `sudo systemctl status docker` | Vérifie que le service Docker tourne |
| `sudo systemctl start docker` | Démarre le service Docker si nécessaire |
| `sudo usermod -aG docker $USER` | Ajoute l'utilisateur courant au groupe `docker`, pour se passer de `sudo` à chaque commande (nécessite de se reconnecter ou `newgrp docker`) |
| `sudo docker run hello-world` | Teste l'installation : télécharge et exécute une image minimale de vérification |

## 2. Informations, recherche et gestion des images

| Commande | Explication |
| --- | --- |
| `docker info` | État général du moteur Docker (nb de conteneurs running/paused/stopped, nb d'images, version serveur) |
| `docker version` | Affiche les versions du client et du serveur Docker |
| `docker search --filter=stars=15 ubuntu` | Recherche une image sur le Docker Hub, filtrée ici sur un nombre minimum d'étoiles |
| `docker pull NOM_IMAGE` | Télécharge une image sans l'exécuter (ex. `docker pull ubuntu:latest`, `docker pull debian:latest`) |
| `docker images` | Liste les images téléchargées localement |
| `docker push NOM_IMAGE` | Publie une image sur le registre public du Hub (compte gratuit requis) |
| `docker login` / `docker logout` | Connexion / déconnexion en CLI au Docker Hub |
| `docker commit NOM_CONTENEUR NOUVELLE_IMAGE` | Sauvegarde les modifications d'un conteneur dans une nouvelle image locale (ne publie pas sur le Hub, n'enregistre que la différence avec l'image de base) |

## 3. Cycle de vie des conteneurs

| Commande | Explication |
| --- | --- |
| `docker run -it IMAGE bash` | Lance un conteneur en mode interactif (`-i` = stdin ouvert, `-t` = pseudo-terminal) et ouvre un shell |
| `docker run -dit --name NOM IMAGE` | Lance un conteneur détaché mais interactif et nommé (le `-i` garde stdin ouvert même en arrière-plan) |
| `docker run -d --name NOM -p HOTE:CONTENEUR IMAGE` | Lance en arrière-plan avec mappage de port explicite |
| `docker run --network NOM_RESEAU IMAGE` | Rattache le conteneur à un réseau Docker dès le lancement |
| `docker run --rm ...` | Supprime automatiquement le conteneur une fois stoppé |
| `docker run --privileged ...` | Lance avec des droits root étendus — ⚠️ à utiliser avec prudence |
| `docker run --volumes-from ...` | Hérite des volumes d'un autre conteneur |
| `docker run --volume-driver ...` | Choisit la technologie de gestion des volumes |
| `docker run -e VAR=valeur IMAGE` | Passe une variable d'environnement au conteneur au lancement |
| `docker ps` | Liste les conteneurs en cours d'exécution |
| `docker ps -a` (ou `--all`) | Liste tous les conteneurs, y compris arrêtés |
| `docker exec -it NOM bash` (ou `sh`) | Exécute une nouvelle commande/un nouveau processus dans un conteneur déjà actif |
| Ctrl+P puis Ctrl+Q | Se détache d'un conteneur interactif sans l'arrêter (contrairement à `exit`) |
| `docker attach NOM` | Se raccroche au processus principal déjà en cours d'un conteneur actif (prend un nom/ID, pas une image) |
| `docker logs NOM` | Consulte les journaux d'un conteneur |
| `docker logs --follow NOM` | Suit les journaux en continu |
| `docker logs --tail 10 NOM` | Affiche les 10 dernières lignes du journal |
| `docker stats NOM` (`--no-stream`) | Monitore les ressources consommées (vue instantanée avec `--no-stream`) |
| `docker events` | Affiche les événements du moteur Docker en temps réel |
| `docker pause NOM` / `docker unpause NOM` | Met en pause / reprend un conteneur |
| `docker update NOM` | Modifie les ressources CPU/mémoire allouées à un conteneur |
| `docker restart NOM` | Redémarre un conteneur en cours |
| `docker stop NOM` | Arrêt propre : envoie un `SIGTERM` avec délai de grâce |
| `docker start NOM` | Redémarre un conteneur arrêté — détaché par défaut, pas besoin de `-d` (contrairement à `run`) |
| `docker kill -s 9 NOM` | Tue le conteneur immédiatement, sans lui laisser terminer sa tâche (contrairement à `stop`) |
| `docker rename NOM NOUVEAU_NOM` | Renomme un conteneur |
| `docker cp Conteneur:SRC DEST` | Copie un fichier/dossier entre un conteneur et l'hôte |
| `docker export NOM > fichier.tar` | Exporte l'intégralité du système de fichiers d'un conteneur |
| `docker diff NOM` | Consulte les modifications apportées à un conteneur par rapport à son image de base |
| `docker stop NOM` puis `docker rm NOM` | Arrête proprement puis supprime un conteneur |
| `docker rm -f NOM` | Force l'arrêt et la suppression en une seule commande |

> **Repères utiles** : une image est immuable, un conteneur ajoute une couche *writable* par-dessus (`stop`/`start` la conserve, `run` en crée une nouvelle) ; `exec` lance un nouveau processus dans un conteneur actif là où `attach` se raccroche à l'existant ; pas de `systemd` dans un conteneur minimal — les démons se lancent manuellement (ex. `/usr/sbin/sshd`).

## 4. Réseaux Docker

| Commande | Explication |
| --- | --- |
| `docker network ls` | Liste les réseaux Docker existants |
| `docker network inspect NOM_RESEAU` (ou `docker inspect NOM`) | Affiche les détails d'un réseau (sous-réseau, passerelle, conteneurs connectés) |
| `docker network create NOM_RESEAU` | Crée un réseau personnalisé (driver `bridge` par défaut), avec résolution DNS automatique entre conteneurs rattachés |
| `docker network create --driver bridge --subnet=X --gateway=Y NOM` | Crée un réseau bridge personnalisé avec sous-réseau et passerelle spécifiés |
| `docker run --network NOM_RESEAU IMAGE` | Rattache un conteneur à un réseau donné dès son lancement |
| `docker run -p PORT_HOTE:PORT_CONTENEUR IMAGE` | Mappe un port du conteneur vers un port de l'hôte, seul moyen de rendre un conteneur joignable **depuis l'extérieur** |
| `docker network disconnect --force NOM_RESEAU NOM_CONTENEUR` | Détache un conteneur d'un réseau (utile ex. pour le relancer avec un autre driver) |

> **Repères utiles** : le bridge par défaut isole les conteneurs en `172.17.x.x` (résolution uniquement par IP) ; un réseau personnalisé ajoute la résolution DNS par nom de conteneur ; le mappage `-p` ne sert qu'à exposer vers l'hôte/l'extérieur, pas pour la communication interne entre conteneurs d'un même réseau. Drivers disponibles : `bridge` (défaut, NAT), `host` (même IP que l'hôte), `macvlan` (IP dédiée par conteneur), `none` (isolation totale), `overlay` (plusieurs hôtes Docker reliés).

## 5. Volumes Docker (locaux et distants NFS)

| Commande | Explication |
| --- | --- |
| `docker volume create NOM_VOLUME` | Crée un volume local (driver `local` par défaut) |
| `docker run -d --name NOM -v NOM_VOLUME:/chemin IMAGE` | Monte un volume dans un conteneur au lancement (syntaxe `-v`) |
| `docker run -d --name NOM --mount source=NOM_VOLUME,target=/chemin IMAGE` | Monte un volume via la syntaxe `--mount` (plus explicite que `-v`) |
| `docker volume ls` | Liste les volumes existants |
| `docker volume inspect NOM_VOLUME` | Affiche les détails d'un volume, dont son `Mountpoint` (emplacement réel sur l'hôte) |
| `docker volume inspect --format '{{ .Mountpoint }}' NOM_VOLUME` | Récupère directement le chemin du volume sur l'hôte, sans le JSON complet |
| `sudo apt install nfs-kernel-server` (sur le serveur NFS) | Installe le service serveur NFS |
| `sudo nano /etc/exports` + `/chemin RESEAU(rw,sync,no_subtree_check)` | Déclare un répertoire exporté via NFS |
| `sudo exportfs -ra` / `sudo exportfs -v` | Recharge / vérifie la configuration des exports NFS |
| `sudo apt install nfs-common` (sur l'hôte Docker) | Installe le client NFS, indispensable pour qu'un volume Docker de type `nfs` puisse se monter |
| `docker volume create --driver local --opt type=nfs --opt o=addr=IP_SERVEUR,rw --opt device=:/chemin NOM_VOLUME` | Crée un volume Docker exploitant un partage NFS distant (le driver reste `local`, seul le backend de stockage change) |
| `sudo mount -t nfs IP:/chemin /point/de/montage` | Montage NFS manuel de test, indépendant de Docker |
| `sudo umount /point/de/montage` | Démonte un partage NFS monté manuellement |

> **Repères utiles** : les données écrites dans un volume survivent à la suppression du conteneur ; un volume local reste lié à la machine hôte, un volume NFS est écrit sur une machine distante et suit le partage réseau, pas le disque local. `nc -vz IP PORT` permet de tester en amont si le port NFS (2049 en v4, 111 pour rpcbind en v3) est joignable, indépendamment de Docker.

## 6. Dockerfile et build d'images

| Commande | Explication |
| --- | --- |
| `docker build -t NOM_IMAGE .` | Construit une image à partir d'un fichier nommé `Dockerfile` dans le dossier courant |
| `docker build -t NOM_IMAGE -f NOM_FICHIER .` | Idem, avec un nom de fichier Dockerfile personnalisé (`-f`) |
| `docker run NOM_IMAGE` | Exécute un conteneur à partir de l'image construite |
| `docker run -p PORT_HOTE:PORT_CONTENEUR NOM_IMAGE` | Rend réellement accessible un port déclaré par `EXPOSE` dans le Dockerfile |
| `docker run -e VAR=valeur NOM_IMAGE` | Passe une variable d'environnement à l'exécution, sans reconstruire l'image |
| `docker run -it --name NOM IMAGE` | Instance nommée, pour pouvoir consulter ses logs (`docker logs NOM`) après coup |

### Principales directives d'un Dockerfile

| Directive | Rôle |
| --- | --- |
| `FROM` | Définit l'image de base — toujours la 1ère instruction (sauf `ARG`) |
| `ARG` | Paramètres de ligne de commande pour le build — seule instruction pouvant précéder `FROM` ; non persistant dans l'image finale |
| `ENV` | Variables d'environnement, pour le build **et** l'exécution du conteneur (persistant) |
| `WORKDIR` | Change le répertoire de travail pour les instructions suivantes |
| `USER` | Change l'utilisateur/groupe d'exécution des instructions suivantes |
| `COPY` | Copie des fichiers/répertoires depuis l'hôte vers l'image |
| `ADD` | Comme `COPY`, avec en plus le support des URL et l'extraction automatique d'archives |
| `EXPOSE` | Déclare les ports à exposer — ne garantit pas l'accessibilité réelle, `-p` reste nécessaire au lancement |
| `VOLUME` | Inclut un répertoire en tant que volume au lancement, non lié au cycle de vie du conteneur |
| `RUN` | Exécute une commande **pendant la construction** de l'image |
| `CMD` | Définit les arguments par défaut **au lancement** du conteneur (modifiables) |
| `ENTRYPOINT` | Définit la toute première commande exécutée dans le conteneur, combinable avec `CMD` pour lui fournir des arguments |

> **Repère utile** : toute modification du script/code source nécessite un nouveau `docker build` — une image est figée au moment de sa construction, elle ne relit pas les fichiers modifiés sur l'hôte.

## 7. Diagnostic réseau et pare-feu (UFW)

| Commande | Explication |
| --- | --- |
| `nc -vz IP PORT` | Teste si un port TCP précis est ouvert et joignable, indépendamment de Docker/NFS (`-z` = scan sans envoi de données, `-v` = verbeux) |
| `sudo apt install ufw` | Installe UFW (surcouche simplifiée d'iptables) — pas installé par défaut sur Debian |
| `sudo ufw enable` | Active le pare-feu (installé par défaut sur Ubuntu, mais inactif) |
| `sudo ufw allow N°PORT` | Autorise/ouvre un port |
| `sudo ufw deny N°PORT` | Interdit/ferme un port |
| `sudo ufw reload` | Force l'application des règles |
| `sudo ufw status numbered` | Vérifie les règles appliquées |

## 8. Nettoyage et maintenance

| Commande | Explication |
| --- | --- |
| `docker stop NOM1 NOM2 ...` | Arrête plusieurs conteneurs en une seule commande |
| `docker rm NOM1 NOM2 ...` | Supprime plusieurs conteneurs arrêtés en une seule commande |
| `docker network rm NOM_RESEAU` | Supprime un réseau personnalisé devenu inutile |
| `docker system prune` | Nettoie toutes les images/conteneurs orphelins ou inutiles |

> **Bonnes pratiques repérées dans les TD** : vérifier systématiquement avec `docker ps -a` et `docker network ls` après un nettoyage pour confirmer qu'il ne reste plus rien ; toujours arrêter un conteneur avant de le supprimer (ou utiliser `docker rm -f`) ; adapter les valeurs d'exemple d'un PDF/support de cours (IP, chemins, guillemets typographiques) aux valeurs réelles avant exécution, source récurrente d'erreurs dans ces labos.
