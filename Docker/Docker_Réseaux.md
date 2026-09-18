# Docker — Manipulation des différents types de réseau

> Supports de cours : *Passage en revue des différents types de réseau* + *TP — Manipulation des différents types de réseau possible entre conteneurs sous Docker* (Cédric Surquin, Technocité)

---

## 1. Théorie — Le réseau sous Docker

### Les conteneurs et le réseau : un fonctionnement particulier

- Les conteneurs peuvent **communiquer entre eux**
- Ils peuvent **initier des connexions sortantes**
- **Mais** on ne peut pas venir toquer à leur porte **directement** depuis l'extérieur

### Le mode Bridge (par défaut)

Le Docker Engine crée un réseau de type pont appelé **`Bridge`** :
- Ce réseau fait office de **switch virtuel** entre les conteneurs
- Les conteneurs sont isolés dans ce sous-réseau, typiquement en `172.17.X.X`
- Le réseau confinant les conteneurs et le réseau de la machine hôte sont séparés par un **NAT** (traduction d'adresses)

Schéma du mode Bridge :
```
Conteneur Apache (172.16.0.5)  Conteneur MariaDB (172.16.0.9)
              \                    /
           RÉSEAU BRIDGE (interface docker0)
                      |
                 NAT (traduction d'adresses)
                      |
           Interface réelle enp0s3 (192.168.1.17)
```

### Et si je veux que l'extérieur puisse contacter directement un conteneur ?

Il faut faire du **mappage de port** : relier le port qu'utilise le conteneur à un port de la machine hôte qui le fait tourner. C'est la notion de **ports exposés**.

Exemple : le conteneur Apache écoute sur `172.16.0.5:4477`, mappé vers `192.168.0.37:9063` côté hôte — c'est ce port hôte qui devient joignable depuis l'extérieur.

### Les autres drivers réseau

| Driver | Comportement |
|---|---|
| **`bridge`** | Réseau pont par défaut, switch virtuel isolé en `172.17.x.x`, séparé de l'hôte par un NAT |
| **`host`** | Permet aux conteneurs d'accéder directement à l'interface réseau du système. Ils ont la **même adresse IP que l'hôte**, ce qui les rend accessibles encore plus directement depuis l'extérieur |
| **`macvlan`** | Chaque conteneur a une **sous-interface dédiée** pour se connecter à l'extérieur — pour les applications qui s'attendent à être connectées directement au réseau (chaque conteneur a alors sa propre IP visible sur le réseau physique) |
| **`none`** | Offre une **isolation totale** des conteneurs : aucune interface réseau ne leur est accessible, en dehors de la loopback |
| **`overlay`** | Route automatiquement les paquets vers le bon hôte, puis vers le bon conteneur — pensé pour plusieurs systèmes hôtes faisant tourner des conteneurs qu'on veut réunir sur un même réseau logique |

### Lister et inspecter les drivers/réseaux installés

```bash
sudo docker network ls
sudo docker network inspect NOM_DU_RESEAU
```
(`docker inspect NOM` fonctionne aussi — Docker détecte automatiquement le type d'objet)

### Créer et utiliser un driver particulier

Exemple avec un driver bridge personnalisé :
```bash
# Créer le bridge (--subnet et --gateway ne sont pas obligatoires)
docker network create --driver bridge --subnet=172.16.10.0/24 --gateway=172.16.10.254 nouveau-bridge

# Rattacher un conteneur au bridge
docker run -dit --name OS1 --network nouveau-bridge ubuntu
```

Mappage de port d'un conteneur particulier :
```bash
sudo docker run -d -p 8080:80 NOM_CONTENEUR
```

### Déconnecter un conteneur d'un réseau

```bash
sudo docker network disconnect --force NOM_RESEAU NOM_CONTENEUR
```
(`--force` n'est pas obligatoire — utile par exemple pour relancer ensuite le conteneur avec un autre driver)

---

## 2. Pratique

### Étape 1 — Vérification de Docker et des réseaux existants

```bash
sudo docker version
sudo docker network ls
```

Réseaux par défaut confirmés : `bridge`, `host`, `none`, tous en driver `local`.

### Étape 2 — Conteneur `client1`

```bash
sudo docker run -dit --name client1 ubuntu
sudo docker ps
```

### Étape 3 — Installation des outils réseau + vérification IP/routes

```bash
sudo docker exec -it client1 bash
apt update
apt install -y iproute2 iputils-ping curl
ip addr
ip route
```

Résultat obtenu : interface `eth0` en `172.17.0.2/16`, route par défaut `default via 172.17.0.1 dev eth0` (passerelle = interface `docker0` de l'hôte).

### Étape 4 — Test d'accès à l'extérieur

```bash
ping 8.8.8.8
ping google.com
```

Confirme que le conteneur peut **initier des connexions sortantes**, malgré son isolation réseau — le NAT laisse sortir le trafic.

### Étape 5 — Conteneur `web1` (nginx, sans paramètre réseau)

```bash
sudo docker run -d --name web1 nginx:latest
sudo docker ps
curl http://localhost:80
```

**Résultat attendu : `Connection refused`.**

**Pourquoi ?** nginx écoute bien sur le port 80, mais uniquement à l'intérieur du sous-réseau bridge (`172.17.x.x`), isolé du réseau de l'hôte par un NAT. Le NAT laisse sortir le trafic initié par le conteneur, mais ne redirige rien automatiquement dans l'autre sens : l'hôte n'a aucune raison de savoir qu'un port doit être redirigé vers ce conteneur tant qu'aucun mappage explicite n'a été créé.

### Étape 6 — Republication avec mappage de port

```bash
sudo docker stop web1
sudo docker rm web1
sudo docker run -d --name web1 -p 8080:80 nginx:latest
sudo docker ps
curl http://localhost:8080
```

**Résultat : page d'accueil nginx reçue avec succès.** Le mappage `-p 8080:80` crée le pont manquant entre le port du conteneur et un port de la machine hôte.

### Étape 7 — Réseau personnalisé `reseau-tp`

```bash
sudo docker network create reseau-tp
sudo docker network ls
sudo docker network inspect reseau-tp
```

(`sudo docker inspect reseau-tp` donne le même résultat — Docker reconnaît l'objet par son nom, quel que soit son type)

Résultat obtenu : driver `bridge`, subnet `172.18.0.0/16` attribué automatiquement (un cran au-dessus du bridge par défaut qui est en `172.17.x.x`), gateway `172.18.0.1`, aucun conteneur encore rattaché (`Containers: {}`).

Un réseau personnalisé (driver `bridge` par défaut) offre un avantage clé par rapport au bridge par défaut : la **résolution DNS automatique** entre les conteneurs qui y sont rattachés.

### Étape 8 — Conteneurs `poste1` et `poste2` sur `reseau-tp` + test ping

```bash
sudo docker run -dit --name poste1 --network reseau-tp ubuntu
sudo docker run -dit --name poste2 --network reseau-tp ubuntu
sudo docker ps

sudo docker exec -it poste1 bash
apt update
apt install -y iproute2 iputils-ping curl
ping poste2
```

**Que constate-t-on ?** Le `ping poste2` fonctionne directement **par le nom du conteneur**, sans jamais avoir eu besoin de connaître son adresse IP — contrairement au bridge par défaut où seule la communication par IP est possible entre conteneurs. C'est la résolution DNS automatique propre aux réseaux personnalisés.

**Note sur `-dit` vs `sleep infinity` :** contrairement au conteneur `nfs_test` (TD NFS) qui s'arrêtait immédiatement avec `busybox` lancé en `-d` seul (pas d'entrée standard ouverte → EOF immédiat → arrêt), ici `-dit` suffit à garder `poste1`/`poste2` actifs : le `-i` garde l'entrée standard ouverte même en arrière-plan, et le `bash` par défaut de l'image `ubuntu` attend alors indéfiniment sans recevoir de signal de fin. `sleep infinity` n'est donc utile que lorsque l'image n'a pas de commande interactive par défaut qui garde `stdin` ouvert.

### Étape 9 — Conteneur `webapp` (nginx) sur `reseau-tp` + test DNS via `curl`

```bash
sudo docker run -d --name webapp --network reseau-tp nginx:latest
sudo docker exec -it poste1 bash
curl http://webapp
```

**Que constate-t-on ?** La page d'accueil nginx s'affiche — `curl` a réussi à joindre `webapp` **uniquement par son nom**, sans IP, et **sans aucun mappage de port** cette fois. Contrairement aux étapes 5-6 (`web1`), la communication ici reste **interne au réseau `reseau-tp`**, entre deux conteneurs qui s'y trouvent tous les deux : le mappage de port ne sert qu'à exposer un conteneur vers l'**extérieur** du réseau Docker (l'hôte), pas pour la communication entre conteneurs d'un même réseau personnalisé.

### Étape 10 — Nettoyage

```bash
sudo docker stop client1 web1 poste1 poste2 webapp
sudo docker rm client1 web1 poste1 poste2 webapp
sudo docker network rm reseau-tp

# Vérification
sudo docker ps -a
sudo docker network ls
```

Plus aucun de ces conteneurs ne doit apparaître, et `reseau-tp` ne doit plus figurer dans la liste des réseaux (seuls `bridge`, `host`, `none` restent).

---

## Points clés à retenir

- Un conteneur peut toujours **sortir** vers l'extérieur (NAT), mais n'est jamais joignable **depuis** l'extérieur sans mappage de port explicite (`-p PORT_HOTE:PORT_CONTENEUR`).
- Le bridge par défaut (`bridge`) isole les conteneurs dans `172.17.x.x`, sans résolution DNS par nom entre eux — seule l'IP fonctionne.
- Un **réseau personnalisé** (`docker network create`), même en driver `bridge`, ajoute la résolution DNS automatique par nom de conteneur — un avantage pratique majeur pour faire communiquer plusieurs conteneurs d'une même application (ex. un conteneur web qui doit joindre un conteneur base de données par son nom plutôt que par une IP qui peut changer).
- La communication **entre conteneurs d'un même réseau personnalisé** (ex. `poste1` → `webapp`) ne nécessite **aucun mappage de port** — le `-p` ne sert qu'à exposer un conteneur vers l'hôte/l'extérieur, pas pour le trafic interne au réseau Docker.
- `docker network inspect NOM_RESEAU` (ou `docker inspect NOM_RESEAU`) donne tous les détails d'un réseau (sous-réseau, passerelle, conteneurs connectés).
- `docker network disconnect --force NOM_RESEAU NOM_CONTENEUR` permet de détacher un conteneur d'un réseau, par exemple pour le relancer avec un autre driver.
- Le driver `host` supprime l'isolation réseau (le conteneur partage l'IP de l'hôte) ; le driver `none` l'isole totalement (aucune interface hors loopback) ; le driver `macvlan` donne à chaque conteneur sa propre IP visible sur le réseau physique ; l'`overlay` relie plusieurs hôtes Docker sur un même réseau logique.
- `-dit` (avec `-i`) suffit à garder un conteneur actif en arrière-plan tant que son processus par défaut garde l'entrée standard ouverte (ex. `bash` sur une image `ubuntu`) ; `sleep infinity` n'est nécessaire que si ce n'est pas le cas (ex. `busybox` lancé sans `-it`).
