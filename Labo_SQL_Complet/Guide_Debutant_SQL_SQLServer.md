# SQL & SQL Server — Guide débutant

## 1. C'est quoi, SQL ?

**SQL** (*Structured Query Language*) est un langage de programmation spécialisé, créé pour **parler aux bases de données relationnelles** : créer des tables, y stocker des données, les interroger, les modifier, les supprimer.

Ce n'est pas un logiciel en soi — c'est un **langage**, un peu comme le HTML pour écrire des pages web. Le logiciel qui exécute ce langage s'appelle un **SGBD** (Système de Gestion de Base de Données Relationnelle), ou **RDBMS** en anglais. Il en existe plusieurs :

| SGBD | Éditeur | Usage typique |
|---|---|---|
| **SQL Server** | Microsoft | Environnements Windows/entreprise |
| **MySQL / MariaDB** | Oracle / communauté | Applications web, open source |
| **PostgreSQL** | Communauté | Applications complexes, open source |
| **Oracle Database** | Oracle | Grandes entreprises, systèmes critiques |
| **SQLite** | Communauté | Applications légères, mobile |

Tous parlent globalement le même langage SQL (avec des variantes propres à chacun), un peu comme des dialectes régionaux d'une même langue.

### Base relationnelle, ça veut dire quoi ?
Les données sont organisées en **tables** (comme des feuilles Excel), avec des **lignes** (les enregistrements) et des **colonnes** (les champs). Les tables peuvent être **reliées entre elles** via des clés, ce qui évite de dupliquer l'information.

**Exemple concret :**
```
Table "Clients"                    Table "Commandes"
┌────┬─────────┬──────────┐        ┌────┬───────────┬────────┐
│ ID │ Nom     │ Email    │        │ ID │ ClientID  │ Montant│
├────┼─────────┼──────────┤        ├────┼───────────┼────────┤
│ 1  │ Dupont  │ jd@x.com │  ←───  │ 1  │ 1         │ 150 €  │
│ 2  │ Martin  │ pm@x.com │  ←───  │ 2  │ 2         │ 89 €   │
└────┴─────────┴──────────┘        └────┴───────────┴────────┘
```
La colonne `ClientID` dans "Commandes" pointe vers `ID` dans "Clients" — c'est une **clé étrangère**. Ça permet de savoir quelle commande appartient à quel client, sans avoir à réécrire le nom/email du client à chaque commande.

---

## 2. Comment on utilise SQL — les 4 commandes de base (CRUD)

Le langage SQL se résume en grande partie à 4 opérations, qu'on retrouve sous l'acronyme **CRUD** :

### CREATE — Créer

```sql
-- Crée une nouvelle table nommée "Clients"
CREATE TABLE Clients
(
    ClientID INT IDENTITY(1,1) PRIMARY KEY,  -- Identifiant unique, s'incrémente tout seul
    Nom NVARCHAR(100),                        -- Texte, jusqu'à 100 caractères
    Email NVARCHAR(255)
);
```

### READ (SELECT) — Lire / interroger

```sql
-- Récupère toutes les colonnes, toutes les lignes de la table
SELECT * FROM Clients;

-- Récupère seulement le nom et l'email, filtré sur un critère
SELECT Nom, Email FROM Clients WHERE Nom = 'Dupont';
```

### UPDATE — Modifier

```sql
-- Met à jour l'email du client dont l'ID est 1
UPDATE Clients
SET Email = 'nouveau.email@x.com'
WHERE ClientID = 1;
```

### DELETE — Supprimer

```sql
-- Supprime le client dont l'ID est 2
DELETE FROM Clients WHERE ClientID = 2;
```

⚠️ Un `UPDATE` ou `DELETE` **sans** `WHERE` s'applique à **toutes les lignes** de la table — c'est l'erreur classique du débutant (et parfois du confirmé fatigué). Toujours vérifier la clause `WHERE` avant d'exécuter.

---

## 3. Pourquoi utiliser SQL Server plutôt qu'un simple fichier Excel ?

C'est la question que beaucoup de débutants se posent. Voici les vraies raisons concrètes :

| Besoin | Excel | SQL Server |
|---|---|---|
| Plusieurs personnes modifient en même temps | ❌ Conflits, fichier verrouillé | ✅ Conçu pour ça (transactions) |
| Des millions de lignes | ❌ Devient très lent | ✅ Optimisé pour de gros volumes |
| Garantir qu'une donnée n'est jamais incohérente (ex. une commande sans client) | ❌ Rien n'empêche l'erreur | ✅ Contraintes, clés étrangères |
| Une application (site web, logiciel métier) doit lire/écrire des données en continu | ❌ Pas prévu pour ça | ✅ Conçu pour être interrogé par du code |
| Sécuriser qui a accès à quoi | ⚠️ Basique | ✅ Gestion fine des droits par utilisateur/rôle |
| Sauvegardes automatiques, haute disponibilité | ❌ Manuel | ✅ Natif (comme vu dans ton TP avec Always On) |

---

## 4. Prérequis avant d'installer SQL Server

### Matériel / système
- **OS** : Windows Server (2016 et plus) ou Windows 10/11 pour un usage local/dev
- **RAM** : 4 Go minimum recommandé (bien plus en production)
- **Espace disque** : ~6-8 Go pour l'installation de base, plus l'espace pour tes futures bases de données
- **.NET Framework** : généralement installé automatiquement par l'installeur si absent

### Édition à choisir
| Édition | Usage | Coût |
|---|---|---|
| **Express** | Petits projets, apprentissage (limité à 10 Go par base) | Gratuite |
| **Developer** | Apprentissage et développement, toutes les fonctionnalités de l'édition Enterprise | Gratuite |
| **Standard / Enterprise** | Production, entreprise | Payante (licence) |

💡 Pour apprendre (comme dans ton TP), l'édition **Developer** est le meilleur choix : gratuite, et avec absolument toutes les fonctionnalités (y compris Always On Availability Groups) — contrairement à Express qui est limitée.

### Compte / droits nécessaires
- Un compte avec des droits **administrateur local** sur la machine pour l'installation
- Si le serveur est joint à un domaine Active Directory (comme dans ton TP), prévoir les comptes de service dès le départ (voir section 6)

---

## 5. Tuto d'installation rapide (SQL Server + SSMS)

### Étape 1 — Télécharger
Deux fichiers sont nécessaires :
1. **SQL Server** (le moteur de base de données) — depuis le site Microsoft, choisir l'édition **Developer**
2. **SSMS** (*SQL Server Management Studio*) — l'outil graphique pour piloter SQL Server (pas inclus automatiquement, à télécharger séparément)

### Étape 2 — Installer SQL Server
1. Lancer l'exécutable téléchargé
2. Choisir **Basic** pour une installation rapide avec les réglages par défaut, ou **Custom** pour tout personnaliser (recommandé si tu veux choisir précisément les composants, les comptes de service, les chemins de fichiers)
3. À l'écran **Feature Selection**, cocher au minimum **Database Engine Services**
4. À l'écran **Server Configuration**, définir les comptes qui feront tourner les services (par défaut, des comptes virtuels Windows suffisent pour un usage simple)
5. À l'écran **Database Engine Configuration** :
   - **Authentication Mode** : *Windows Authentication* est suffisant si tu es sur un domaine ou en usage local
   - **Data Directories** : définir où seront stockés les fichiers de données (par défaut `C:\Program Files\Microsoft SQL Server\...`, à adapter selon tes disques)
6. Cliquer sur **Install** et attendre la fin de l'installation

### Étape 3 — Installer SSMS
1. Lancer l'installeur SSMS téléchargé séparément
2. Suivre l'assistant (aucune configuration particulière requise, installation simple)

### Étape 4 — Se connecter
1. Ouvrir **SSMS**
2. Dans **Server name**, taper `.` ou `localhost` (si SQL Server est sur la même machine) ou le nom du serveur distant
3. **Authentication** : *Windows Authentication*
4. **Connect**

Tu es prêt à créer ta première base avec `CREATE DATABASE`.

---

## 6. Mise en perspective — pourquoi une entreprise utilise SQL Server (cas concret)

### Le scénario
Imagine une PME de 50 employés qui utilise un **logiciel de gestion de tickets de support technique** (un peu comme un mini-Zendesk interne). Ce logiciel doit :
- Stocker chaque ticket (client, problème, statut, technicien assigné, historique)
- Permettre à 5 techniciens de consulter/modifier les tickets **en même temps**, sans conflit
- Rester **disponible en permanence** — si le serveur tombe pendant les heures de bureau, plus personne ne peut travailler
- Garder un **historique fiable**, sans perte de données même en cas de panne

### Pourquoi SQL Server plutôt qu'un fichier partagé ou une simple base locale ?

1. **Accès concurrent** — SQL Server gère nativement le fait que plusieurs techniciens ouvrent/modifient des tickets simultanément, sans écraser les modifications des autres (via les transactions).

2. **Sécurité des comptes de service** — comme vu dans ton TP, plutôt que de faire tourner SQL Server avec un compte administrateur classique (risque énorme si ce compte est compromis), on utilise un **gMSA** : le mot de passe est géré automatiquement par Active Directory, jamais connu d'un humain, changé tous les 30 jours. Si un attaquant compromet l'application, il ne peut pas "voler" un mot de passe qui n'est jamais stocké nulle part de façon exploitable.

3. **Sauvegardes automatiques** — un Job SQL Server Agent (comme celui que tu as configuré) effectue une sauvegarde complète chaque nuit. Si le disque du serveur crashe un mardi après-midi, l'entreprise ne perd "que" les tickets créés depuis la dernière sauvegarde du journal des transactions (souvent quelques minutes de données, pas plusieurs jours).

4. **Haute disponibilité avec Always On** — c'est là que ton TP prend tout son sens concret : si le serveur SQL01 tombe en panne (disque dur mort, carte réseau grillée, mise à jour Windows qui plante), le second serveur **SQL02**, qui contient une **copie synchronisée en temps réel** de la base, prend automatiquement le relais. Les techniciens continuent à travailler, potentiellement sans même s'en rendre compte — la bascule est transparente grâce au **Listener** (`SQL-PROD`), qui redirige automatiquement les connexions vers le serveur actif.

### Ce que ça donne concrètement, techniquement
```
Techniciens (postes de travail)
        │
        ▼
   Listener SQL-PROD (adresse unique, fixe)
        │
   ┌────┴────┐
   ▼         ▼
 SQL01     SQL02
(PRIMARY) (SECONDARY — copie synchronisée en temps réel)
```
Tant que l'un des deux serveurs répond, l'application de tickets continue de fonctionner — c'est exactement l'infrastructure que tu es en train de construire dans ton TP, appliquée à un cas réel d'entreprise.

### Et les gMSA dans tout ça ?
Le logiciel de tickets (l'application) se connecte à SQL Server avec ses propres identifiants applicatifs — mais **SQL Server lui-même**, en tant que service Windows, tourne sous le compte `gMSA_SQL$`. Ça sépare bien deux niveaux de sécurité :
- **Qui peut faire tourner le service SQL Server** (le compte gMSA, géré par AD)
- **Qui peut se connecter à la base depuis l'application** (des comptes SQL ou Windows dédiés à l'application, avec des droits limités uniquement sur la base de tickets — pas sur tout le serveur)

---

## 7. Pour aller plus loin (liens avec ton TP)

| Concept vu dans ce guide | Où tu l'as pratiqué dans ton TP |
|---|---|
| CREATE DATABASE / CREATE TABLE | Partie 4 — création de `DB_Production` et de la table `Clients` |
| Sauvegardes (BACKUP) | Partie 5 — Job `BACKUP_FULL_DB_Production` |
| Comptes de service sécurisés | Partie 2 — comptes gMSA |
| Haute disponibilité | Parties 7 à 13 — cluster, Always On, Listener |

Ce guide couvre les bases théoriques ; ton fichier `TP_Labo_AD_gMSA_SQL_AlwaysOn.md` documente la mise en pratique complète, avec les erreurs réelles rencontrées et leurs résolutions.
