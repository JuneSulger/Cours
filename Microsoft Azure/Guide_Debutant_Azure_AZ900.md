# Microsoft Azure — Guide débutant orienté AZ-900

## 0. Repères sur la certification AZ-900

**AZ-900 (Microsoft Azure Fundamentals)** est la certification d'entrée de Microsoft sur le cloud — aucun prérequis technique, pensée pour les débutants complets en cloud. L'examen est structuré en 3 domaines, avec leur pondération officielle :

| Domaine | Poids dans l'examen |
|---|---|
| Describe cloud concepts (concepts du cloud) | 25–30 % |
| Describe Azure architecture and services (architecture et services Azure) | 35–40 % |
| Describe Azure management and governance (gestion et gouvernance) | 30–35 % |

Ce guide suit cette structure en 3 grandes parties, plus un glossaire à la fin.

---

## 1. C'est quoi, Azure ? (et le cloud en général)

**Microsoft Azure** est une plateforme de **cloud computing** : un ensemble de services (serveurs, stockage, bases de données, réseaux, intelligence artificielle...) hébergés dans les centres de données de Microsoft à travers le monde, que tu loues à la demande plutôt que d'acheter et gérer toi-même du matériel physique.

### Cloud vs infrastructure classique (on-premises)

| | On-premises (sur site) | Cloud (Azure) |
|---|---|---|
| Matériel | Tu achètes tes serveurs | Microsoft possède et gère le matériel |
| Coût | Investissement initial élevé (CapEx) | Paiement à l'usage (OpEx) |
| Scalabilité | Limitée à ta capacité physique | Quasi illimitée, à la demande |
| Maintenance | À ta charge (pannes, mises à jour physiques) | Gérée par Microsoft pour l'infrastructure |
| Délai de mise en service | Semaines/mois (achat, livraison, install) | Minutes |

**CapEx vs OpEx**, c'est un des tout premiers concepts testés à l'examen :
- **CapEx** (*Capital Expenditure*) : dépense d'investissement, un gros montant payé d'avance (ex. acheter un serveur physique)
- **OpEx** (*Operational Expenditure*) : dépense de fonctionnement, payée au fur et à mesure de la consommation (ex. facture Azure mensuelle selon l'usage réel)

Le cloud fait basculer les entreprises du CapEx vers l'OpEx.

### Les 3 modèles de service (IaaS / PaaS / SaaS)

C'est **LE** concept central de l'examen — comprends bien qui gère quoi :

| | IaaS | PaaS | SaaS |
|---|---|---|---|
| Nom complet | Infrastructure as a Service | Platform as a Service | Software as a Service |
| Ce que tu gères | OS, mises à jour, applis, données | Applis et données | Rien — juste utiliser le logiciel |
| Ce que le fournisseur gère | Matériel, virtualisation, réseau | Tout ce qui précède + OS, runtime | Tout |
| Exemple Azure | Machines virtuelles (VM) | Azure App Service, Azure SQL Database | Microsoft 365, Dynamics 365 |
| Cas d'usage typique | Migrer un serveur existant tel quel | Héberger une application web sans gérer le serveur | Utiliser directement un logiciel (Outlook, Teams) |

> **Vos données restent votre responsabilité.** Quel que soit le modèle — IaaS, PaaS ou SaaS —, les données que vous y placez restent, en dernier ressort, sous votre responsabilité. Microsoft garantit la disponibilité et la résilience de son infrastructure, mais n'est responsable ni du contenu de vos données ni de leur sauvegarde applicative : une suppression accidentelle, une erreur humaine ou un ransomware restent à votre charge. Cette sauvegarde (Azure Backup, réplication, versionnement...) doit être mise en place explicitement — elle ne fait partie d'aucun service par défaut.

💡 **Image mentale utile pour retenir ça (analogie pizza)** :
- **On-premises** = tu fais ta pizza toi-même, de A à Z, dans ta cuisine
- **IaaS** = tu loues une cuisine déjà équipée (four, plan de travail) et tu fais ta pizza
- **PaaS** = tu achètes une pâte à pizza toute faite, tu n'as plus qu'à ajouter tes garnitures
- **SaaS** = tu commandes une pizza déjà prête, livrée chez toi

### Les 3 modèles de déploiement

| Modèle | Description |
|---|---|
| **Public cloud** | Ressources hébergées chez Microsoft, partagées entre plusieurs clients (multi-tenant), accessibles via Internet |
| **Private cloud** | Infrastructure cloud dédiée à une seule organisation (sur site ou hébergée) |
| **Hybrid cloud** | Combinaison des deux — une partie on-premises, une partie dans le cloud public, connectées entre elles (ex. VPN ou ExpressRoute) |
| **Multicloud** | Utilisation de plusieurs fournisseurs cloud en parallèle (Azure, AWS, GCP...), pour éviter la dépendance à un seul fournisseur (*lock-in*) ou répartir les risques |

### Les 6 bénéfices du cloud (souvent cités à l'examen)

1. **Haute disponibilité** (*High availability*) — les services restent accessibles même en cas de panne d'un composant
2. **Scalabilité** (*Scalability*) — augmenter ou réduire les ressources selon le besoin
3. **Élasticité** (*Elasticity*) — la capacité s'ajuste **automatiquement** selon la charge, en temps réel
4. **Agilité** — déployer rapidement de nouvelles ressources
5. **Reprise après sinistre** (*Disaster recovery*) — capacité à restaurer un service après un incident majeur
6. **Économie de coûts** — payer uniquement ce qu'on consomme

⚠️ Nuance testée à l'examen : **scalabilité ≠ élasticité**. La scalabilité, c'est la *capacité* à grandir/rétrécir (souvent manuellement ou planifiée). L'élasticité, c'est le fait que ça se fasse **automatiquement** en fonction de la demande réelle.

**Scalabilité verticale vs horizontale :**
- **Verticale (scale up/down)** : ajouter plus de puissance à une même machine (plus de RAM, plus de CPU)
- **Horizontale (scale out/in)** : ajouter/retirer des machines en parallèle

### Exemple concret — pourquoi le cloud change la décision elle-même

Une entreprise veut tester une nouvelle application pendant deux semaines avant de décider d'un investissement plus large.

**Avec un datacenter traditionnel** : il faut commander un serveur, attendre sa livraison (souvent plusieurs semaines), l'installer en salle machine, le configurer — puis, une fois le test terminé, le revendre ou le stocker si le projet est abandonné. **La dépense est engagée quel que soit le résultat du test.**

**Avec Azure** : elle crée une Virtual Machine ou déploie directement son code sur App Service en quelques minutes, fait tourner le test 14 jours, consulte les résultats, puis supprime la ressource. Elle n'a payé que ces deux semaines d'usage réel — sans rien à revendre ni à stocker ensuite. Si le test est concluant, elle passe à une échelle plus grande sans rien racheter ; sinon, elle n'a perdu que le temps du test.

C'est cet exemple qui illustre le mieux, à l'examen, pourquoi le cloud ne se limite pas à « louer des serveurs ailleurs » — il change la façon dont une capacité informatique est **achetée, livrée et exploitée**.

| Critère | Datacenter traditionnel | Azure / cloud public |
|---|---|---|
| Achat de capacité | Serveurs achetés à l'avance, dimensionnés pour le pic anticipé | Provisionnement à la demande, dimensionné pour l'usage réel |
| Délai de mise à disposition | Semaines à mois | Minutes, via le portail, la CLI, une API ou de l'IaC |
| Ajustement de la capacité | Fixe une fois le matériel acheté | Ajustable à la hausse ou à la baisse selon la charge réelle |
| Exploitation | Équipe interne (correctifs, matériel, climatisation, alimentation) | Services managés — Azure prend en charge une grande partie |
| Fin d'usage | Matériel à revendre, stocker ou recycler | Ressource supprimée en un clic, facturation arrêtée immédiatement |

### Tableau de correspondance bénéfice → scénario (fréquent à l'examen)

| Bénéfice | Se traduit par | Scénario concret |
|---|---|---|
| Disponibilité | Continuité | Un site e-commerce doit rester joignable 24 h/24, même si un datacenter entier tombe en panne |
| Scalabilité | Croissance | Une startup passe de 100 à 100 000 utilisateurs en un an : il faut ajouter des ressources durablement |
| Élasticité | Pic ponctuel | Une billetterie en ligne absorbe un pic de trafic à l'ouverture des ventes, puis revient à la normale |
| Agilité | Rapidité de mise en œuvre | Une équipe lance un environnement de test en quelques minutes, sans attendre le service informatique |

---

## 2. Architecture et services Azure

### 2.1 La structure physique d'Azure

```
Geography (ex. Europe)
    │
    └── Region (ex. France Central)
            │
            └── Availability Zone (ex. Zone 1, 2, 3)
                    │
                    └── Datacenter (bâtiment physique)
```

| Terme | Définition |
|---|---|
| **Region** | Un ensemble de datacenters dans une zone géographique précise (ex. "France Central", "West Europe") |
| **Region pair** (paire de régions) | Deux régions associées dans la même géographie, utilisées pour la réplication en cas de sinistre régional (ex. West Europe ↔ North Europe) |
| **Availability Zone** (Zone de disponibilité) | Un ou plusieurs datacenters physiquement séparés au sein d'une même région, avec leur propre alimentation/refroidissement/réseau — protège contre la panne d'un seul datacenter |
| **Geography** | Un regroupement de régions respectant des frontières de résidence des données et de conformité légale (ex. "Europe", "Amérique du Nord") |

**Pourquoi c'est important :** si ton application est répartie sur plusieurs Availability Zones d'une même région, elle continue de fonctionner même si un datacenter entier tombe en panne (incendie, coupure électrique majeure, etc.).

### 2.2 Les services de calcul (Compute)

| Service | À quoi ça sert |
|---|---|
| **Azure Virtual Machines (VM)** | Un serveur virtuel classique (IaaS) — tu gères l'OS, les mises à jour, tout |
| **Azure App Service** | Héberger des applications web/API sans gérer de serveur (PaaS) |
| **Azure Container Instances (ACI)** | Lancer des conteneurs Docker rapidement, sans gérer l'orchestration |
| **Azure Kubernetes Service (AKS)** | Orchestrer des conteneurs à grande échelle avec Kubernetes managé |
| **Azure Functions** | Exécuter du code à la demande, déclenché par un événement, sans gérer aucun serveur (*serverless*) — facturé à l'exécution, pas en continu |
| **Virtual Machine Scale Sets (VMSS)** | Groupe de VM identiques qui s'ajoutent/se retirent automatiquement selon la charge (élasticité) |

💡 **Serverless**, terme souvent mal compris : ça ne veut pas dire "sans serveur" au sens propre (il y a bien un serveur physique quelque part), mais que **tu n'as plus à t'en soucier du tout** — ni le provisionner, ni le dimensionner, ni le maintenir.

### 2.3 Les services réseau

| Service | À quoi ça sert |
|---|---|
| **Virtual Network (VNet)** | Un réseau privé isolé dans Azure, où tu places tes ressources (VM, etc.) |
| **Subnet** | Une subdivision d'un VNet, pour organiser/segmenter les ressources |
| **Network Security Group (NSG)** | Un pare-feu virtuel — règles autorisant/bloquant le trafic entrant/sortant |
| **Azure VPN Gateway** | Connexion chiffrée entre ton réseau on-premises et Azure via Internet |
| **Azure ExpressRoute** | Connexion privée dédiée entre ton réseau on-premises et Azure, **sans passer par Internet public** (plus rapide, plus fiable, plus cher) |
| **Azure Load Balancer** | Répartit le trafic réseau entre plusieurs VM/ressources (niveau 4 - transport) |
| **Azure Application Gateway** | Répartiteur de charge pour trafic web (niveau 7 - application), avec fonctions avancées (SSL, pare-feu applicatif) |
| **Azure DNS** | Hébergement de noms de domaine dans Azure |
| **Azure Content Delivery Network (CDN)** | Cache le contenu (images, vidéos, fichiers statiques) au plus proche géographique de l'utilisateur final, pour accélérer le chargement |

### 2.4 Les services de stockage

| Service | À quoi ça sert |
|---|---|
| **Azure Blob Storage** | Stockage d'objets non structurés (fichiers, images, vidéos, sauvegardes) |
| **Azure Files** | Partages de fichiers accessibles via le protocole SMB, comme un lecteur réseau classique |
| **Azure Disk Storage** | Disques durs virtuels attachés à des VM |
| **Azure Queue Storage** | File d'attente de messages, pour faire communiquer des composants applicatifs entre eux |
| **Azure Table Storage** | Stockage NoSQL simple, clé-valeur |
| **Azure Data Lake Storage** | Stockage massif optimisé pour l'analytique big data |

**Niveaux d'accès du Blob Storage (souvent testés)** :
| Niveau (*tier*) | Usage | Coût stockage | Coût accès |
|---|---|---|---|
| **Hot** | Données consultées fréquemment | Élevé | Faible |
| **Cool** | Données peu consultées, gardées ≥30 jours | Moyen | Moyen |
| **Archive** | Archivage long terme, très rarement consulté | Très faible | Élevé (et délai de récupération de plusieurs heures) |

**Redondance du stockage (durabilité des données)** :
| Type | Description |
|---|---|
| **LRS** (*Locally Redundant Storage*) | 3 copies dans un seul datacenter |
| **ZRS** (*Zone Redundant Storage*) | 3 copies réparties sur plusieurs Availability Zones de la même région |
| **GRS** (*Geo-Redundant Storage*) | Copie LRS + réplication asynchrone vers une région secondaire jumelée |
| **GZRS** (*Geo-Zone-Redundant Storage*) | Combine ZRS dans la région primaire + réplication vers une région secondaire |

### 2.5 Les services de base de données

| Service | À quoi ça sert |
|---|---|
| **Azure SQL Database** | SQL Server managé en PaaS — plus besoin de gérer l'OS/le patching du moteur (contrairement à une VM SQL Server classique comme dans ton TP) |
| **Azure Database for MySQL/PostgreSQL** | Équivalents managés pour MySQL et PostgreSQL |
| **Azure Cosmos DB** | Base de données NoSQL, multi-modèle, distribuée mondialement, très faible latence |

💡 **Lien avec ton TP :** ce que tu as monté manuellement sur SQL01/SQL02 (installation, patchs, comptes de service, Always On) est justement le travail qu'**Azure SQL Database** (PaaS) prend en charge à ta place — c'est l'illustration concrète de la différence IaaS (VM + SQL Server installé toi-même) vs PaaS (base de données directement prête à l'emploi).

### 2.6 Identité — Microsoft Entra ID (anciennement Azure Active Directory)

⚠️ **Renommage important à connaître pour l'examen** : *Azure Active Directory (Azure AD)* s'appelle désormais **Microsoft Entra ID**. Le service et les concepts sont les mêmes, seul le nom a changé (rebranding Microsoft).

| Terme | Définition |
|---|---|
| **Microsoft Entra ID** | Service de gestion des identités et des accès de Microsoft (cloud) — gère qui peut se connecter et à quoi |
| **Tenant** | L'instance dédiée de Microsoft Entra ID d'une organisation — un espace isolé qui contient ses utilisateurs, groupes, applications |
| **Authentification multifacteur (MFA)** | Exiger plusieurs preuves d'identité (mot de passe + code sur le téléphone, par exemple) pour se connecter |
| **Single Sign-On (SSO)** | Se connecter une seule fois pour accéder à plusieurs applications sans se ré-authentifier |
| **Conditional Access** (Accès conditionnel) | Règles qui autorisent/bloquent l'accès selon des conditions (localisation, appareil, risque détecté) |

### 2.7 Sécurité avancée (au-delà de l'identité)

| Service | À quoi ça sert |
|---|---|
| **Zero Trust** (Confiance zéro) | Principe de sécurité : ne jamais faire confiance par défaut, toujours vérifier — même à l'intérieur du réseau de l'entreprise |
| **Microsoft Defender for Cloud** | Évalue la posture de sécurité des ressources Azure et détecte les menaces |
| **Microsoft Sentinel** | Solution SIEM cloud — centralise et analyse les journaux de sécurité pour détecter des attaques |
| **Azure Key Vault** | Coffre-fort managé pour stocker secrets, clés de chiffrement et certificats |
| **Azure DDoS Protection** | Absorbe et atténue les attaques par déni de service distribué visant les ressources publiques |

---

## 3. Gestion et gouvernance Azure

### 3.1 La hiérarchie d'organisation des ressources

```
Management Group (groupe d'administration)
    │
    └── Subscription (abonnement)
            │
            └── Resource Group (groupe de ressources)
                    │
                    └── Resource (ressource — ex. une VM, une base de données)
```

| Niveau | Rôle |
|---|---|
| **Management Group** | Regroupe plusieurs abonnements pour appliquer des règles/politiques communes à grande échelle |
| **Subscription** (abonnement) | Unité de facturation et de limite d'accès — sépare généralement les environnements (ex. Prod / Dev / Test) |
| **Resource Group** | Conteneur logique qui regroupe des ressources liées à un même projet/application — permet de tout gérer/supprimer d'un coup |
| **Resource** | L'élément concret déployé (une VM, une base de données, un compte de stockage...) |

💡 Les règles (RBAC, Policy) appliquées à un niveau supérieur de la hiérarchie **héritent** automatiquement vers les niveaux inférieurs.

### 3.2 Gouvernance et contrôle d'accès

| Concept | Définition |
|---|---|
| **Azure RBAC** (*Role-Based Access Control*) | Contrôle d'accès basé sur les rôles — définit **qui peut faire quoi** sur une ressource (ex. rôle *Reader* = lecture seule, *Contributor* = peut modifier, *Owner* = contrôle total y compris les droits d'accès) |
| **Azure Policy** | Définit des règles de conformité (ex. "toutes les VM doivent être dans la région France Central") et empêche/signale les déploiements non conformes |
| **Azure Blueprints** | Modèles réutilisables combinant ressources, policies et rôles RBAC pour déployer un environnement conforme d'un coup |
| **Azure Resource Manager (ARM)** | Le moteur de déploiement d'Azure — toutes les actions (portail, CLI, PowerShell) passent par lui ; les **modèles ARM** (fichiers JSON) permettent de déployer une infrastructure de façon reproductible (*Infrastructure as Code*) |
| **Tags** (étiquettes) | Paires clé-valeur attachées aux ressources pour les organiser/filtrer (ex. `Environnement: Production`, `Département: Finance`) |
| **Resource Locks** (verrous de ressource) | Empêchent la suppression ou la modification accidentelle d'une ressource critique, quel que soit le rôle RBAC de la personne |

### 3.3 Coûts et facturation

| Concept | Définition |
|---|---|
| **Azure Pricing Calculator** | Outil pour estimer le coût d'une architecture avant de la déployer |
| **Azure Total Cost of Ownership (TCO) Calculator** | Compare le coût d'une infrastructure on-premises existante avec son équivalent sur Azure |
| **Azure Cost Management** | Outil de suivi et d'analyse des dépenses réelles une fois les ressources déployées |
| **Budgets** | Alertes configurables quand les dépenses approchent/dépassent un seuil défini |
| **Reserved Instances** | Engagement sur 1 ou 3 ans en échange d'une réduction tarifaire importante (bien moins cher qu'à l'usage classique) |

💡 Le coût d'une ressource dépend de son type, de sa région, et de la **bande passante sortante** consommée — la bande passante **entrante** est, elle, toujours gratuite sur Azure.

### 3.4 SLA et disponibilité

| Concept | Définition |
|---|---|
| **SLA** (*Service Level Agreement*) | Engagement contractuel de Microsoft sur un niveau de disponibilité garanti (ex. 99,9 %) — avec compensation financière si non respecté |
| **Composite SLA** | Quand une architecture combine plusieurs services ayant chacun leur SLA, le SLA global résultant peut être **inférieur** au plus bas des deux (à calculer en multipliant les taux de disponibilité) |

**Exemple de calcul (souvent testé à l'examen) :**
Si un service A a un SLA de 99,9 % et un service B (dont dépend A) a un SLA de 99,99 %, le SLA composite de l'ensemble = 99,9 % × 99,99 % ≈ **99,89 %** — légèrement inférieur au plus faible des deux pris isolément.

### 3.5 Confidentialité, conformité et confiance

| Concept | Définition |
|---|---|
| **Microsoft Trust Center** | Portail centralisant les informations de Microsoft sur la sécurité, la confidentialité et la conformité |
| **Service Trust Portal** | Accès aux rapports d'audit et certifications de conformité d'Azure |
| **Azure compliance documentation** | Documentation sur les normes respectées (RGPD, ISO 27001, HDS, etc.) |
| **Responsabilité partagée** (*Shared Responsibility Model*) | Répartition des responsabilités de sécurité entre Microsoft et le client — varie selon IaaS/PaaS/SaaS (plus tu montes vers le SaaS, plus Microsoft prend de responsabilités à sa charge) |

### 3.6 Outils de gestion

| Outil | Usage |
|---|---|
| **Azure Portal** | Interface web graphique pour gérer les ressources |
| **Azure CLI** | Outil en ligne de commande multiplateforme (Linux/Mac/Windows) pour piloter Azure par script |
| **Azure PowerShell** | Équivalent CLI mais avec des cmdlets PowerShell |
| **Azure Cloud Shell** | Terminal CLI/PowerShell accessible directement depuis le navigateur, sans rien installer |
| **Azure Mobile App** | Application mobile pour surveiller/gérer des ressources basiques en déplacement |
| **Azure Advisor** | Recommandations personnalisées (coût, sécurité, performance, fiabilité) sur ton environnement existant |
| **Azure Service Health** | Statut en temps réel des services Azure, alertes en cas d'incident affectant tes ressources |
| **Azure Monitor** | Collecte et analyse des métriques/logs de tes ressources |

---

## 4. Cas concret — pourquoi une entreprise migre vers Azure

### Le scénario
La même PME de 50 employés que dans ton guide SQL héberge aujourd'hui son logiciel de tickets support sur **un unique serveur physique dans un local technique**, avec SQL Server dessus.

### Les problèmes rencontrés
- Le serveur a 6 ans, tombe parfois en panne — plus de garantie constructeur
- Un seul technicien sait le maintenir, il est en vacances → personne ne peut intervenir en cas de souci
- Le budget IT vient d'imposer une réduction du CapEx (plus d'achat de gros matériel)
- La direction veut que l'application soit accessible même si un employé télétravaille depuis un site distant

### La solution avec Azure
1. **Migration du serveur SQL en IaaS d'abord** — une **Azure Virtual Machine** reproduit l'environnement existant à l'identique (même logique que SQL01 dans ton TP, mais hébergée chez Microsoft plutôt que sur un Hyper-V local)
2. **Bascule progressive vers Azure SQL Database (PaaS)** — élimine le besoin de patcher/maintenir l'OS et le moteur SQL Server soi-même
3. **Réplication sur plusieurs Availability Zones** — remplace le rôle que jouait ton cluster SQL01/SQL02 en Always On, mais géré nativement par Azure
4. **Microsoft Entra ID** pour gérer les accès des employés, avec MFA activé
5. **Azure Cost Management** pour suivre précisément la facture mensuelle et fixer des alertes de budget
6. **Azure Policy** pour garantir que toute nouvelle ressource créée reste bien dans une région européenne (conformité RGPD)

### Le résultat concret
- Plus de matériel physique à racheter (fin du CapEx sur ce poste)
- Application accessible depuis n'importe où, avec authentification sécurisée
- Continuité de service même en cas de panne d'un datacenter (Availability Zones)
- Facturation uniquement sur l'usage réel, ajustable à tout moment

---

## 5. Glossaire des termes AZ-900

| Terme | Définition courte |
|---|---|
| **Agility** | Capacité à déployer/adapter rapidement des ressources |
| **ARM (Azure Resource Manager)** | Moteur de déploiement et de gestion des ressources Azure |
| **ARM Template** | Fichier JSON décrivant une infrastructure à déployer de façon reproductible (Infrastructure as Code) |
| **Availability Zone** | Datacenter(s) physiquement isolé(s) au sein d'une région |
| **Azure Advisor** | Outil de recommandations personnalisées |
| **Azure CLI** | Outil en ligne de commande multiplateforme pour Azure |
| **Azure Policy** | Service de définition et d'application de règles de conformité |
| **Azure Portal** | Interface web de gestion d'Azure |
| **Blob Storage** | Stockage d'objets non structurés |
| **Budget (Cost Management)** | Alerte configurable sur un seuil de dépense |
| **CapEx** | Dépense d'investissement (achat matériel, paiement d'avance) |
| **Cloud Shell** | Terminal Azure accessible depuis le navigateur |
| **Composite SLA** | SLA résultant de la combinaison de plusieurs services |
| **Conditional Access** | Règles d'accès contextuelles (Microsoft Entra ID) |
| **Elasticity** | Ajustement automatique des ressources selon la demande |
| **ExpressRoute** | Connexion privée dédiée entre on-premises et Azure |
| **Fault tolerance** | Capacité d'un système à continuer de fonctionner malgré une panne partielle |
| **Geography** | Regroupement de régions Azure selon des frontières légales/conformité |
| **GRS (Geo-Redundant Storage)** | Réplication du stockage vers une région secondaire |
| **High availability** | Disponibilité continue d'un service |
| **Hybrid cloud** | Combinaison d'infrastructure on-premises et cloud public |
| **IaaS** | Infrastructure as a Service — le fournisseur gère uniquement le matériel/virtualisation |
| **LRS (Locally Redundant Storage)** | Réplication du stockage dans un seul datacenter |
| **Management Group** | Regroupement d'abonnements pour une gouvernance à grande échelle |
| **MFA (Multi-Factor Authentication)** | Authentification à plusieurs facteurs |
| **Microsoft Entra ID** | Service de gestion des identités d'Azure (ex-Azure AD) |
| **OpEx** | Dépense de fonctionnement (paiement à l'usage) |
| **PaaS** | Platform as a Service — le fournisseur gère aussi l'OS et le runtime |
| **RBAC (Role-Based Access Control)** | Contrôle d'accès basé sur des rôles attribués |
| **Region** | Ensemble de datacenters dans une zone géographique |
| **Region pair** | Deux régions associées pour la réplication/reprise après sinistre |
| **Reserved Instance** | Engagement tarifaire sur 1 ou 3 ans en échange d'une réduction |
| **Resource Group** | Conteneur logique regroupant des ressources liées |
| **SaaS** | Software as a Service — logiciel prêt à l'emploi, tout est géré par le fournisseur |
| **Scalability** | Capacité à augmenter/réduire les ressources |
| **Serverless** | Modèle où l'infrastructure sous-jacente est totalement abstraite pour le développeur |
| **Shared Responsibility Model** | Répartition des responsabilités de sécurité entre Microsoft et le client |
| **SLA (Service Level Agreement)** | Engagement contractuel sur un niveau de service garanti |
| **Subnet** | Subdivision d'un réseau virtuel (VNet) |
| **Subscription** | Unité de facturation et de gestion des accès Azure |
| **Tags** | Métadonnées clé-valeur attachées à une ressource |
| **Tenant** | Instance dédiée de Microsoft Entra ID pour une organisation |
| **TCO (Total Cost of Ownership)** | Comparaison du coût total on-premises vs cloud |
| **VM (Virtual Machine)** | Serveur virtuel en IaaS |
| **VMSS (Virtual Machine Scale Set)** | Groupe de VM identiques avec mise à l'échelle automatique |
| **VNet (Virtual Network)** | Réseau privé virtuel dans Azure |
| **ZRS (Zone-Redundant Storage)** | Réplication du stockage sur plusieurs zones de disponibilité |
| **API (Application Programming Interface)** | Ensemble de règles permettant à un programme d'interroger/piloter un service directement depuis du code, sans interface graphique |
| **CLI (Command-Line Interface)** | Interface en ligne de commande — piloter Azure en tapant des commandes texte plutôt qu'en cliquant, pour scripter et automatiser |
| **Endpoint** | Adresse (URL) à laquelle un service est joignable — celle qu'une application appelle pour utiliser une API ou accéder à une ressource |
| **IaC (Infrastructure as Code)** | Décrire son infrastructure dans un fichier texte versionnable plutôt que de la créer à la main, pour la déployer de façon reproductible (ex. ARM Templates, Bicep, Terraform) |
| **Provisionnement** | Action de créer et configurer une ressource pour la rendre prête à l'emploi |
| **SDK (Software Development Kit)** | Bibliothèques fournies par Azure pour appeler ses API depuis un langage de programmation sans écrire les requêtes HTTP à la main |

---

## 6. Pour aller plus loin

AZ-900 valide les bases ; la suite dépend du métier visé :

| Certification | Pour qui |
|---|---|
| **AZ-104** | Administrateur Azure — exploitation quotidienne des ressources |
| **AZ-204** | Développeur Azure — conception et code d'applications cloud |
| **AZ-500** | Ingénieur sécurité Azure — durcissement et défense de l'environnement |
| **DP-900** | Fondamentaux des données Microsoft — le pendant "data" de l'AZ-900 |
| **SC-900** | Fondamentaux sécurité, conformité et identité Microsoft |

Contrairement aux autres certifications Azure, **AZ-900 ne périme jamais** et ne demande pas de renouvellement annuel — c'est une base, pas un titre à maintenir.


- Documentation officielle Microsoft Learn (gratuite, modules interactifs alignés sur l'examen)
- Le guide officiel des compétences mesurées (*Skills measured*) est mis à jour régulièrement — vérifier la version en vigueur avant de passer l'examen
- Format de l'examen : questions à choix multiple, glisser-déposer, études de cas — 40-60 questions environ, score de passage 700/1000
