# Docker — Manipulation des différents types de réseau

> Supports de cours : *Passage en revue des différents types de réseau* + *TP — Manipulation des différents types de réseau possible entre conteneurs sous Docker* (Cédric Surquin, Technocité)

---

## 1. Théorie — Le réseau sous Docker

### Principe général
- Les conteneurs peuvent **communiquer entre eux** et **initier des connexions sortantes**
- Mais on **ne peut pas** venir "toquer à leur porte" directement depuis l'extérieur
- Le réseau confinant les conteneurs et le réseau de la machine hôte sont séparés par un **NAT**

### Les drivers réseau
| Driver | Comportement |
|---|---|
| `bridge` | Réseau de type pont créé par le Docker Engine (`docker0`). Fait office de switch virtuel entre conteneurs. Isolation dans un sous-réseau `172.17.x.x` |
| `host` | Le conteneur accède directement à l'interface réseau du système — même IP que l'hôte, accessible plus directement depuis l'extérieur |
| `macvlan` | Chaque conteneur a une sous-interface dédiée pour se connecter directement à l'extérieur — pour les applis qui s'attendent à être connectées directement au réseau |
| `none` | Isolation totale : aucune interface réseau accessible en dehors de la loopback |
| `overlay` | Route automatiquement les paquets vers le bon hôte et le bon conteneur — utile avec plusieurs hôtes Docker reliés sur un même réseau logique |

### Mappage de port
Pour rendre un conteneur joignable depuis l'extérieur : relier le port utilisé par le conteneur à un port de la machine hôte (`-p PORT_HOTE:PORT_CONTENEUR`) — notion de **ports exposés**.

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

Un réseau personnalisé (driver `bridge` par défaut) offre un avantage clé par rapport au bridge par défaut : la **résolution DNS automatique** entre les conteneurs qui y sont rattachés.

### Étape 8 — Conteneurs `poste1` et `poste2` sur `reseau-tp` + résolution DNS

```bash
sudo docker run -dit --name poste1 --network reseau-tp ubuntu
sudo docker run -dit --name poste2 --network reseau-tp ubuntu
sudo docker ps

sudo docker exec -it poste1 bash
apt update
apt install -y iproute2 iputils-ping curl
ping poste2
```

**Résultat attendu : le `ping poste2` fonctionne directement par le nom du conteneur**, sans connaître son IP — contrairement au bridge par défaut où seule la communication par IP est possible. C'est la résolution DNS automatique propre aux réseaux personnalisés.

---

## Points clés à retenir

- Un conteneur peut toujours **sortir** vers l'extérieur (NAT), mais n'est jamais joignable **depuis** l'extérieur sans mappage de port explicite (`-p PORT_HOTE:PORT_CONTENEUR`).
- Le bridge par défaut (`bridge`) isole les conteneurs dans `172.17.x.x`, sans résolution DNS par nom entre eux — seule l'IP fonctionne.
- Un **réseau personnalisé** (`docker network create`), même en driver `bridge`, ajoute la résolution DNS automatique par nom de conteneur — un avantage pratique majeur pour faire communiquer plusieurs conteneurs d'une même application (ex. un conteneur web qui doit joindre un conteneur base de données par son nom plutôt que par une IP qui peut changer).
- `docker network inspect NOM_RESEAU` donne tous les détails d'un réseau (sous-réseau, passerelle, conteneurs connectés).
- `docker network disconnect --force NOM_RESEAU NOM_CONTENEUR` permet de détacher un conteneur d'un réseau, par exemple pour le relancer avec un autre driver.
- Le driver `host` supprime l'isolation réseau (le conteneur partage l'IP de l'hôte) ; le driver `none` l'isole totalement (aucune interface hors loopback) ; ce sont les deux extrêmes par rapport au compromis du `bridge`.
