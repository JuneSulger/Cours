# Docker Compose — Application Flask + PostgreSQL

> Supports de cours : *Initiation à Docker Compose* + *TP — Créer une application Python, construire son image Docker, et composer une application complète utilisant PostgreSQL avec Docker Compose* (Cédric Surquin, Technocité)

---

## 1. Théorie — Docker Compose

### Le problème

- Les paramètres d'exécution d'un conteneur sont potentiellement nombreux (nom, volume, réseau, mapping de ports...)
- Il faut les **rappeler à chaque nouvelle exécution** du conteneur — fastidieux à taper
- Une application un minimum complexe est composée de **plusieurs conteneurs**

### La solution

Écrire un **fichier** qui stocke ces informations, et qui est lu à chaque exécution du conteneur : **= Docker Compose**.

> En production, on utilise Compose même pour un conteneur isolé !

### Installation

Dans 99 % des cas, rien à faire : le paquet `docker-compose` s'installe automatiquement avec `docker-ce`/`docker.io`. Si besoin manuel, chercher `docker-compose` ou `docker-compose-plugin` dans le gestionnaire de paquets.

### Structure de base (`compose.yml` ou `docker-compose.yml`)

```yaml
services:        # obligatoire
  web:            # nom donné à la 1ère brique logicielle
    image: nginx  # image Docker à utiliser dans cette brique
    ports:
      - "8080:80"  # mappage port hôte vers port conteneur
```

La 2ᵉ brique se trouve dans le **même fichier**, au paragraphe suivant, séparée d'une ligne vide.

À noter : depuis un autre conteneur, `curl http://web` fonctionnerait — Docker Compose crée automatiquement un **réseau** et un **DNS interne** entre les services.

### Volumes

```yaml
services:
  db:
    image: mysql:8
    volumes:
      - db_data:/var/lib/mysql

volumes:
  db_data:
```

### Dépendances entre services

```yaml
services:
  web:
    image: nginx:3
    depends_on:
      - db
```

⚠️ `depends_on` ne garantit **pas** que le service dont l'autre dépend est prêt à fonctionner — juste l'**ordre de lancement**.

### Politique de redémarrage

```yaml
services:
  web:
    image: nginx:3
    restart: always|on-failure[:3]|no|unless-stopped
```

Par défaut, cette politique est sur `no`.

### Mapping mental Docker CLI ↔ Compose

| Docker CLI | Compose |
|---|---|
| `docker run` | `services:` |
| `-p` | `ports:` |
| `-v` | `volumes:` |
| réseau manuel | Automatique ! |
| Nom conteneur | Nom sous `service` |

### Exécution

```bash
docker compose up [-d]        # interprète et lance l'application décrite dans le YAML (-d = arrière-plan, 99% des cas)
docker compose down [-v]      # stoppe l'application et tous ses conteneurs (-v = supprime aussi les volumes)
docker compose ps             # liste les conteneurs exécutés par l'application
docker compose logs           # journaux des conteneurs et de l'application
```

---

## 2. Pratique — Application Flask + PostgreSQL

### Étape 1 — Arborescence du projet

```bash
mkdir tp-compose-flask-postgres
cd tp-compose-flask-postgres
```

### Étape 2 — Création des fichiers

```bash
touch app.py requirements.txt Dockerfile compose.yml
```

**⚠️ Point relevé** : le PDF écrit "Docker file" (avec un espace), mais le nom conventionnel attendu par `docker build` (sans option `-f`) est **`Dockerfile`**, en un seul mot.

### Étape 3 — Application Python (`app.py`)

```python
from flask import Flask
import os
import psycopg2

app = Flask(__name__)

@app.route("/")
def index():
    db_host = os.environ.get("DB_HOST", "db")
    db_name = os.environ.get("DB_NAME", "demo")
    db_user = os.environ.get("DB_USER", "demo")
    db_password = os.environ.get("DB_PASSWORD", "demo")

    conn = psycopg2.connect(
        host=db_host,
        database=db_name,
        user=db_user,
        password=db_password
    )
    cur = conn.cursor()
    cur.execute("SELECT 'Connexion PostgreSQL OK depuis Docker Compose !';")
    message = cur.fetchone()[0]
    cur.close()
    conn.close()
    return f"<h1>{message}</h1>"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
```

- `os.environ.get("DB_HOST", "db")` : lit la variable d'environnement `DB_HOST`, avec `"db"` par défaut — ce sera justement le **nom du service** PostgreSQL dans `compose.yml`, joignable grâce au DNS interne de Compose.
- `host="0.0.0.0"` dans `app.run()` : indispensable en conteneur — signifie "écoute sur toutes les interfaces réseau", contrairement à `127.0.0.1` qui ne serait joignable que depuis l'intérieur du conteneur, même avec un mappage de port.

### Étape 4 — Dépendances (`requirements.txt`)

```
flask
psycopg2-binary
```

`psycopg2-binary` (plutôt que `psycopg2` seul) inclut les dépendances système précompilées, évitant d'avoir besoin d'outils de compilation C dans l'image.

### Étape 5 — `Dockerfile`

```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 5000

CMD ["python", "app.py"]
```

- `COPY requirements.txt .` avant `COPY app.py .` : optimisation du cache de build — tant que `requirements.txt` ne change pas, `pip install` n'est pas rejoué à chaque modification du code Python.
- `--no-cache-dir` : évite de stocker le cache pip dans l'image, ce qui l'allège.
- `EXPOSE 5000` : documente le port utilisé — ne le rend pas accessible tout seul (rappel théorique du TD Dockerfile), il faudra un mappage explicite dans `compose.yml`.

**⚠️ Erreur rencontrée** : tentative de taper `RUN pip install --no-cache-dir -r requirements.txt` directement dans le terminal bash (`bash: run: commande inconnue`). `RUN` est un mot-clé propre à la syntaxe **Dockerfile**, qui dit à Docker "exécute cette commande pendant la construction de l'image" — ce n'est pas une commande shell existant sur le système. Le test s'effectue soit avec `pip install` seul (sans `RUN`) en dehors de Docker, soit en laissant Docker exécuter l'intégralité du Dockerfile via `docker build` ou `docker compose up`.

### Étape 6 — `compose.yml`

```yaml
services:
  app:
    build: .
    ports:
      - "8080:5000"
    environment:
      DB_HOST: db
      DB_NAME: demo
      DB_USER: demo
      DB_PASSWORD: demo
    depends_on:
      - db

  db:
    image: postgres:16
    environment:
      POSTGRES_DB: demo
      POSTGRES_USER: demo
      POSTGRES_PASSWORD: demo
    volumes:
      - db_data:/var/lib/postgresql/data

volumes:
  db_data:
```

- `build: .` (au lieu d'une `image:` toute faite) : Compose construit l'image localement à partir du `Dockerfile` du dossier courant.
- `ports: "8080:5000"` : équivalent du `-p` en CLI.
- `environment:` (bloc `app`) : les 4 variables lues par `app.py` via `os.environ.get(...)`.
- `depends_on: - db` : ordre de lancement (db avant app), sans garantie que Postgres soit déjà prêt à accepter des connexions.
- `image: postgres:16` (bloc `db`, pas de `build`) : image officielle depuis Docker Hub.
- `environment:` (bloc `db`) : variables spécifiques à l'image officielle Postgres, utilisées pour l'auto-configuration au premier démarrage (création base/utilisateur/mot de passe).
- `volumes: - db_data:/var/lib/postgresql/data` : relie le volume nommé `db_data` au répertoire où PostgreSQL stocke physiquement ses données.
- Section `volumes:` de fin (niveau racine, **même indentation que `services:`**) : déclare le volume nommé utilisé plus haut.

**Le lien invisible entre les deux blocs** : `DB_HOST: db` (côté `app`) correspond exactement au nom du service `db` — Docker Compose crée automatiquement un réseau et un DNS interne entre les services d'un même fichier, donc `app` peut joindre `db` simplement par ce nom.

**⚠️ Erreurs rencontrées lors de l'écriture de `compose.yml` :**
1. `could not find expected ':'` — erreur classique d'**indentation YAML** (tabulation glissée à la place d'espaces, ou décalage incohérent entre deux lignes). YAML n'accepte que des espaces, jamais de tabulations.
2. `services.volumes additional properties 'db_data' not allowed` — la section `volumes:` finale (déclaration du volume nommé) était indentée comme si elle se trouvait *à l'intérieur* de `services:`, alors qu'elle doit être au même niveau (aucune indentation, collée à la marge de gauche).
3. Ligne `build: .` manquante après une première tentative avec `nano` — sans elle, Compose cherche une image `app` déjà existante au lieu de la construire.
4. Utilisation d'un heredoc (`cat > compose.yml << 'EOF' ... EOF`) pour garantir un fichier sans tabulations — mais le marqueur de fin `EOF` s'est retrouvé écrit *dans* le fichier lui-même (`EOF` non reconnu comme délimiteur de fin, probablement à cause d'un caractère invisible). Corrigé avec `sed -i '/^EOF$/d' compose.yml` pour supprimer la ligne parasite.

### Étape 7 — Lancer l'application (sans arrière-plan)

```bash
sudo docker compose up
```

Volontairement sans `-d` : le terminal reste attaché, affichant en direct les logs des deux conteneurs (préfixés par leur nom de service). Nécessite une seconde session pour les étapes suivantes.

### Étape 8 — Test dans le navigateur

```
http://<IP_VM>:8080
```
ou
```bash
curl http://localhost:8080
```

Résultat attendu : **Connexion PostgreSQL OK depuis Docker Compose !**

### Étape 9 — Liste des conteneurs de l'application

```bash
sudo docker compose ps
```

### Étape 10 — Journaux (globaux puis application)

```bash
sudo docker compose logs
sudo docker compose logs app
sudo docker compose logs -f app   # suivi en direct, façon tail -f
```

### Étape 11 — Journaux du service `db`

```bash
sudo docker compose logs db
```

### Étape 12 — Test du DNS interne de Compose

```bash
sudo docker compose exec app bash
apt update
apt install -y iputils-ping
ping db
```

**Constat** : le ping fonctionne directement avec `db` comme nom d'hôte, sans connaître son IP — même principe que la résolution DNS testée dans le TP réseaux précédent (`poste1` → `poste2`), sauf qu'ici Compose crée ce réseau et ce DNS **automatiquement**, sans `docker network create` explicite.

### Étape 13 — Arrêt / relance : persistance du volume

```bash
sudo docker compose down
sudo docker compose up -d
sudo docker compose logs db
```

**Constat** : après relance, pas de nouveaux messages d'initialisation de la base (création des rôles, etc.) dans les logs — la base PostgreSQL réutilise le même volume `db_data`, ses données ont survécu à l'arrêt/suppression des conteneurs.

### Étape 14 — Arrêt en désassociant le volume

```bash
sudo docker compose down -v
sudo docker volume ls
```

Le `-v` supprime cette fois aussi les volumes déclarés — `db_data` disparaît de la liste, les données sont réellement effacées.

### Étape 15 — Modification du code (`app.py`)

```python
return f"<h1>{message}</h1><p>Application modifiée.</p>"
```

### Étape 16 — Relance avec reconstruction explicite de l'image

```bash
sudo docker compose up -d --build
curl http://localhost:8080
```

`--build` force la reconstruction de l'image avant de (re)lancer les conteneurs, même si une image existait déjà pour ce service — sans quoi Compose réutiliserait l'ancienne image en cache, contenant encore l'ancienne version du code.

---

## 3. Questions de réflexion

**1. Quel service est accessible depuis l'extérieur de la machine ?**
Le service `app` (Flask), grâce au mappage de port `"8080:5000"` dans `compose.yml`. C'est ce mappage qui crée le pont entre le port du conteneur et un port de la machine hôte, rendant le service joignable depuis l'extérieur.

**2. Quel service reste uniquement accessible depuis le réseau Docker interne ?**
Le service `db` (PostgreSQL) — aucun mappage de port n'est défini pour lui dans `compose.yml`. Il n'est joignable que par les autres conteneurs du même réseau Compose (ici `app`, via le nom `db`), jamais depuis l'hôte ou l'extérieur.

**3. Pourquoi l'application utilise-t-elle `DB_HOST=db` ?**
Parce que `db` correspond exactement au **nom du service** PostgreSQL déclaré dans `compose.yml`. Docker Compose crée automatiquement un réseau et un DNS interne entre tous les services d'un même fichier : `app` peut donc joindre `db` simplement par ce nom, sans connaître son adresse IP (qui pourrait d'ailleurs changer à chaque redémarrage du conteneur).

**4. À quoi sert le volume `db_data` ?**
Il assure la **persistance des données** de PostgreSQL au-delà du cycle de vie des conteneurs. Sans lui, toutes les données de la base seraient perdues à chaque suppression du conteneur `db` (`docker compose down` puis `up`). Le volume est monté sur `/var/lib/postgresql/data`, l'emplacement où PostgreSQL écrit physiquement ses données à l'intérieur du conteneur.

**5. Pourquoi faut-il utiliser `--build` après modification du code Python ?**
Parce qu'une image Docker est **figée** au moment de sa construction — elle ne relit jamais automatiquement les fichiers modifiés sur l'hôte. Sans `--build`, Docker Compose relancerait le conteneur `app` avec l'**ancienne image déjà construite** (mise en cache), contenant encore l'ancienne version d'`app.py`. `--build` force la reconstruction de l'image à partir du `Dockerfile` et du code source à jour.

**6. Que fait `docker compose down -v` de plus que `docker compose down` ?**
`docker compose down` arrête et supprime les conteneurs et le réseau créés par Compose, mais **conserve les volumes nommés** (comme `db_data`) — les données survivent donc à un simple arrêt/redémarrage. `docker compose down -v` va plus loin : il supprime **également les volumes** déclarés dans `compose.yml`, effaçant ainsi définitivement les données qu'ils contenaient.

---

## En résumé — qu'a-t-on fait, et à quoi ça sert ?

**Ce qu'on a construit :** une petite application web en deux parties — un service Flask (`app`), qui affiche une page web, et une base de données PostgreSQL (`db`) à laquelle il se connecte. Plutôt que de lancer ces deux conteneurs séparément avec des commandes `docker run` longues et à retaper à chaque fois, on a décrit l'ensemble dans **un seul fichier** (`compose.yml`), que Docker Compose sait lire et exécuter d'un coup.

**Ce que ça change concrètement :** au lieu de gérer manuellement le réseau entre les deux conteneurs, leurs variables d'environnement, l'ordre de démarrage et le stockage persistant de la base, tout est désormais **déclaré une fois pour toutes** dans un fichier texte versionnable (que tu peux d'ailleurs committer sur GitHub comme le reste de tes TDs). Une seule commande (`docker compose up -d`) suffit ensuite à reconstruire toute l'application, où que ce soit, à l'identique.

**À quoi ça sert en pratique :** c'est la méthode standard pour développer et déployer des applications composées de plusieurs services qui doivent collaborer (ici : un frontend web + une base de données, mais le principe s'étend à des architectures plus riches : cache Redis, reverse proxy, plusieurs microservices...). Concrètement, ça permet par exemple :
- de **partager l'intégralité d'un environnement de développement** avec un collègue en lui donnant simplement le dossier du projet — `docker compose up` reproduit fidèlement la même stack chez lui
- de **séparer proprement le code applicatif du stockage** : le conteneur `app` peut être détruit et reconstruit à volonté (nouvelle version du code) sans jamais perdre les données de `db`, tant que le volume reste en place
- de préparer le terrain vers des outils plus avancés utilisés en production (Kubernetes, Docker Swarm), qui reposent sur les mêmes concepts de base : services déclarés, réseau interne automatique, volumes persistants
