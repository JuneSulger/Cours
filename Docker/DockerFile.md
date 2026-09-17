# Docker — Le Dockerfile en détails + TD Heartbeat

> Support de cours : *Docker — Le DockerFile, plus en détails* (Cédric Surquin, Technocité)
> Travail dirigé : *Création d'une première application containérisée* (19/05/26)

---

## 1. Théorie — Le Dockerfile

### Nature du Dockerfile

- Un Dockerfile est un simple **fichier texte**, contenant une suite d'instructions plus ou moins nombreuses et précises.
- Il doit respecter une **syntaxe précise**.
- Il est interprété au moment de l'exécution de la commande `docker build`, pour construire l'image correspondante.

### Table des directives principales

| Directive | Rôle |
|---|---|
| `FROM` | Définit l'image de base — **toujours la 1ère instruction** (sauf `ARG`, voir plus bas) |
| `ARG` | Déclare des paramètres de ligne de commande pour le processus de build — **seule instruction pouvant précéder `FROM`** |
| `ENV` | Définit des variables d'environnement, pour le build **et** pour l'exécution du conteneur |
| `WORKDIR` | Modifie le répertoire de travail utilisé pour la construction du conteneur |
| `USER` | Modifie l'utilisateur/groupe sous lequel s'exécutent les instructions suivantes |
| `COPY` | Copie des fichiers/répertoires depuis l'hôte vers l'image |
| `ADD` | Comme `COPY`, avec des fonctionnalités supplémentaires (URL, extraction automatique d'archives) |
| `EXPOSE` | Déclare les ports devant être exposés lors du lancement du conteneur |
| `VOLUME` | Inclut un répertoire dans l'image en tant que volume au lancement du conteneur |
| `RUN` | Exécute une commande **pendant la construction** de l'image |
| `CMD` | Définit les arguments par défaut **au lancement** du conteneur |
| `ENTRYPOINT` | Définit la toute première commande exécutée dans le conteneur — combinable avec `CMD` pour lui fournir des arguments |

### Détail de chaque directive

**`FROM`**
- Un conteneur est forcément basé sur une image.
- Si on ne se base sur rien d'existant : `FROM scratch` (cas de `hello-world`).

**`ARG`**
- Permet de paramétrer le build, y compris pour rendre `FROM` dynamique :
  ```dockerfile
  ARG ALPINE_VERSION=3.14
  FROM alpine:${ALPINE_VERSION}
  ```
- **N'est pas persistant** dans l'image finale — disponible uniquement pendant le build. Pour des variables persistantes à l'exécution, utiliser `ENV`.

**`ENV`**
- Exemple : `ENV PORT=3000` pour une application qui écoute sur ce port.

**`WORKDIR`**
- Change le répertoire dans lequel s'exécutent toutes les directives suivantes (`COPY`, `RUN`, `CMD`...).
- Évite les longs chemins absolus, fragiles si la structure du projet change.

**`COPY`**
- Syntaxe proche de la commande `cp` sous GNU/Linux.

**`ADD`**
- Fonctionnalités supplémentaires par rapport à `COPY` : peut copier un contenu directement depuis une **URL**, et **extrait automatiquement** les archives téléchargées — `COPY` demanderait une étape d'extraction manuelle en plus.

**`EXPOSE`**
- Précise le(s) port(s) à exposer, et le protocole (TCP par défaut si non précisé, ou UDP).
- ⚠️ **Ne garantit pas** l'accessibilité réelle depuis l'extérieur — le pare-feu de l'hôte reste maître à bord. Pour rendre le port réellement accessible :
  ```bash
  docker run -p 8000:3000 NOM_IMAGE
  ```

**`VOLUME`**
- Définit un répertoire hôte servant de stockage permanent, **non lié au cycle de vie** du conteneur.
- Doit être monté explicitement à chaque démarrage : `docker run -v`.

**`ENTRYPOINT`**
- Définit la toute première commande exécutée dans le conteneur.
- Peut être combinée avec `CMD`, qui lui fournit alors des arguments par défaut (modifiables au lancement).

### Écrire et construire un Dockerfile

1. Un simple éditeur de texte suffit (ex. `nano MON_1ER_DOCKER_FILE`), enregistré **dans le même dossier** que le code source qu'il devra containériser.
2. Construire l'image à partir du Dockerfile :
   ```bash
   docker build -t NOM_IMAGE .
   ```
3. Exécuter le conteneur avec les options utiles :
   ```bash
   docker run -p port_local:port_conteneur NOM_IMAGE
   ```

> Le cours précise qu'un Dockerfile réel peut être bien plus complexe que les exemples vus, et qu'il existe d'autres directives non couvertes — libre à chacun d'approfondir celles rencontrées en pratique.

---

## 2. Application — Analyse d'un Dockerfile NodeJS

Dockerfile fourni en exercice :

```dockerfile
FROM node:14
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

| Ligne | Commentaire |
|---|---|
| `FROM node:14` | Image de base officielle Node.js v14 (au lieu de `scratch`, qui repartirait de zéro) |
| `WORKDIR /app` | Toutes les instructions suivantes s'exécutent depuis `/app` |
| `COPY package*.json ./` | Copie `package.json` et `package-lock.json` en premier — optimisation du cache de build : tant que ces fichiers ne changent pas, `npm install` n'est pas rejoué |
| `RUN npm install` | Installe les dépendances **au moment du build** (équivalent conceptuel à un `apt install` manuel, mais rendu reproductible) |
| `COPY . .` | Copie ensuite le reste du code source |
| `EXPOSE 3000` | Documente le port utilisé par l'application — nécessitera `-p` au lancement pour être réellement accessible |
| `CMD ["npm", "start"]` | Point d'entrée : commande exécutée au lancement du conteneur (forme *exec*, recommandée, sans passer par un shell intermédiaire) |

**Nuance du cours** : ce Dockerfile utilise `COPY` plutôt que `ADD`, choix cohérent puisqu'on copie de simples fichiers locaux (pas une archive distante à extraire). Il utilise aussi `CMD` seul plutôt que `ENTRYPOINT` + `CMD` — suffisant ici, la nuance entre les deux directives n'entrant en jeu que pour des cas d'usage plus riches (ex. rendre certains arguments modifiables au lancement tout en figeant le programme exécuté).

---

## 3. TD — Application Python containérisée ("heartbeat")

### Étape 1 — Le script Python

Script demandé : affiche un message en boucle, avec un délai entre chaque affichage, en récupérant message et nombre de répétitions en arguments de ligne de commande.

**Bugs rencontrés et corrigés** lors de la recopie du script depuis le PDF :
1. Le bloc de récupération des arguments et l'appel à `afficher_message()` étaient indentés au même niveau que le `print("Usage: ...")` — donc *à l'intérieur* du `if len(sys.argv) != 3:`, ne s'exécutant que si le nombre d'arguments était **incorrect** (l'inverse de l'effet voulu). Correction : ajout d'un `else:` manquant.
2. Faute de frappe `sys.arv[1]` → `sys.argv[1]`
3. Faute de frappe `repeitions` → `repetitions` dans l'appel de fonction

Version finale (`heartbeat.py`) :

```python
import sys
import time

def afficher_message(message, repetitions, delai):
    for _ in range(repetitions):
        print(message)
        time.sleep(delai)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python heartbeat.py <message> <repetitions>")
    else:
        message = sys.argv[1]
        repetitions = int(sys.argv[2])
        delai = 1
        afficher_message(message, repetitions, delai)
```

Test (sous Ubuntu, `python3` et non `python`) :
```bash
python3 heartbeat.py coucou 3
```

### Étape 2 — Organisation des fichiers

Le Dockerfile doit être **dans le même dossier** que le script. Réorganisation depuis `~` :
```bash
mkdir ~/td-docker-heartbeat
mv heartbeat.py ~/td-docker-heartbeat/
cd ~/td-docker-heartbeat
```

### Étape 3 — Premier Dockerfile (`BUILDTEST`)

```dockerfile
# Utilisation d'une image de base légère basée sur Alpine Linux
FROM python:3.8-alpine

# Création du répertoire de travail dans le conteneur
WORKDIR /app

# Copie du script Python dans le répertoire de travail
COPY heartbeat.py .

# Commande par défaut pour exécuter le script
CMD ["python", "heartbeat.py", "coucou", "3"]
```

**⚠️ Erreur rencontrée** : ligne `COPY heartbeat.py` sans le `.` final (destination manquante) →
```
ERROR: failed to build: dockerfile parse error on line 3: COPY requires at least two arguments, but only one was provided
```
Correction : `COPY heartbeat.py .`

### Étape 4 — Build et exécution

```bash
sudo docker build -t heartbeat-app -f BUILDTEST .
sudo docker run heartbeat-app
```

Résultat : "coucou" affiché 3 fois. Le conteneur passe ensuite en statut `Exited (0)` — normal pour un script séquentiel qui se termine de lui-même, sans erreur (code `0`).

Vérification :
```bash
sudo docker ps -a
```

### Étape 5 — Instance nommée et logs

```bash
sudo docker run -it --name app1 heartbeat-app
sudo docker logs app1
```

### Étape 6 — Version avec variables d'environnement

Copie du script pour créer une version paramétrable (l'énoncé demande une **copie**, mais fournit par erreur la commande `mv`, qui renomme au lieu de dupliquer — point relevé et corrigé en recréant `heartbeat.py` séparément après coup) :
```bash
sudo mv heartbeat.py heartbeat2.py   # ⚠️ renomme, ne copie pas — cp aurait été plus cohérent avec l'énoncé
sudo nano heartbeat2.py
```

Version modifiée (`heartbeat2.py`), avec `os.environ.get` :
```python
import sys
import time
import os

def afficher_message(message, repetitions, delai):
    for _ in range(repetitions):
        print(message)
        time.sleep(delai)

if __name__ == "__main__":
    message = os.environ.get("MESSAGE", "coucou")
    repetitions = int(os.environ.get("REPETITIONS", 3))
    delai = float(os.environ.get("DELAI", 1.0))
    afficher_message(message, repetitions, delai)
```

**⚠️ Erreur rencontrée** : faute de frappe `MESSAFE` au lieu de `MESSAGE` dans `os.environ.get()`. Résultat : le script ne trouvait jamais la variable d'environnement passée via `-e MESSAGE=...`, et retombait systématiquement sur la valeur par défaut `"coucou"`. Corrigé en renommant la clé.

### Étape 7 — Deuxième Dockerfile (`BUILDTEST2`)

```dockerfile
FROM python:3.8-alpine
WORKDIR /app
COPY heartbeat2.py .
CMD ["python", "heartbeat2.py"]
```

### Étape 8 — Build et exécution avec variables d'environnement

```bash
sudo docker build -t heartbeat-app2 -f BUILDTEST2 .
sudo docker run -e MESSAGE="salut" -e REPETITIONS=5 -e DELAI=1.5 heartbeat-app2
```

Résultat final : "salut" affiché 5 fois, avec 1,5 seconde entre chaque affichage — confirmant que le conteneur prend bien en charge des paramètres modifiables à l'exécution, sans reconstruire l'image.

> **Point clé retenu** : toute modification du script source nécessite un **nouveau `docker build`** — une image est figée au moment de sa construction, elle ne relit pas les fichiers modifiés sur l'hôte.

---

## Points clés à retenir

- Un Dockerfile encode la **construction** d'une image (`RUN`, `COPY`, `ADD`) ; `CMD`/`ENTRYPOINT` définissent son comportement **à l'exécution**.
- `ARG` (build uniquement, non persistant) ≠ `ENV` (persistant, disponible à l'exécution).
- `COPY` (simple) ≠ `ADD` (gère aussi URL et extraction d'archives).
- `EXPOSE` documente un port mais ne le rend pas accessible — il faut `-p` au lancement.
- Les variables d'environnement (`-e` au lancement, lues via `os.environ.get()` côté script) permettent de paramétrer un conteneur sans reconstruire l'image à chaque changement de comportement.
- Toujours vérifier attentivement les fautes de frappe dans les noms de variables/arguments — plusieurs bugs de ce TD provenaient de lettres inversées ou manquantes, sans qu'aucune erreur explicite ne soit levée (le script s'exécutait silencieusement avec un comportement différent de celui attendu).
