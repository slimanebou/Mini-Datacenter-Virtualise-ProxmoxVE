# 🧠 Cheatsheet · Mini Datacenter Virtualisé

> Tout le projet sur une page : à relire 10 minutes avant un entretien.

**Sommaire :** [Pitch](#1--le-pitch) · [Chiffres](#2--chiffres-clés) · [Carte mémoire](#3-️-carte-mémoire) · [Étapes](#4-️-le-projet-étape-par-étape) · [Règles pfSense](#5--règles-pfsense-à-connaître) · [Commandes](#6--commandes-clés) · [Questions](#7--questions-dentretien) · [Scénarios](#8--scénarios) · [Limites](#9-️-limites-assumées) · [Glossaire](#10--glossaire)

---

## 1. 🎤 Le pitch

**En 30 secondes**
> J'ai conçu en trinôme un mini datacenter virtualisé : 6 machines réparties en 3 zones de sécurité (Administration, DMZ, Invités), toutes reliées par un pare-feu pfSense en politique *Default Deny*. On y trouve un Active Directory avec DNS et DHCP, un serveur web Docker en DMZ et une base MariaDB que seul le serveur web peut joindre. Le projet était prévu sur Proxmox, mais face aux limites matérielles on a basculé sur VMware en gardant toute l'architecture.

**En 2 minutes, dérouler dans cet ordre**
1. **Le besoin** : reproduire un datacenter de production sur un seul poste
2. **L'architecture** : pfSense au centre, 3 zones, une seule carte réseau par VM
3. **La sécurité** : Default Deny, exceptions minimales (SQL 3306, DNS 53, HTTP 80)
4. **Les services** : AD/DNS/DHCP, Docker Nginx en DMZ, MariaDB cloisonnée
5. **La difficulté** : Proxmox → VMware, architecture conservée
6. **La suite** : HA CARP, Zabbix, sauvegardes automatisées

---

## 2. 📊 Chiffres clés

| 6 VMs | 3 zones | 4 interfaces pfSense | 15 règles | 26 Go RAM | 16 vCores | 1 seul point d'entrée |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|

**Contexte :** TER Master 1 Informatique IRS · UVSQ / Paris-Saclay · 2025-2026 · trinôme · encadrant M. Gueroui

---

## 3. 🗺️ Carte mémoire

### Adresses à connaître par cœur

> Astuce : **3ᵉ octet = numéro de VLAN** · **.1 = pfSense** · **.10 = serveur principal de la zone**

| Zone | Réseau | Passerelle | Machines |
|---|---|---|---|
| WAN | NAT VMware | — | pfSense `192.168.11.133` |
| 🔵 Admin (10) | `192.168.10.0/24` | `.10.1` | Windows Server `.10.10` · MariaDB `.10.99` · Windows 11 `.50 → .100` |
| 🟡 DMZ (20) | `192.168.20.0/24` | `.20.1` | Serveur web Docker `.20.10` |
| 🟣 Invités (30) | `192.168.30.0/24` | `.30.1` | Client Debian `.30.10` |

### Ports à connaître

| Port | Service | Qui → qui |
|:---:|---|---|
| 22 | SSH | Admin → toutes les zones |
| 53 | DNS | DMZ et Invités → `192.168.10.10` |
| 80 | HTTP | Invités → serveur web · WAN → serveur web (port forwarding) |
| 443 | HTTPS | Admin → interface pfSense (anti-lockout) |
| 3306 | MariaDB | Serveur web `.20.10` → BDD `.10.99` uniquement |

### Matrice de flux en une phrase par zone

- 🔵 **Admin** : peut tout faire, sauf la BDD qui ne sort jamais
- 🟡 **DMZ** : Internet oui, Admin non (sauf SQL et DNS)
- 🟣 **Invités** : Internet + site web + DNS, rien d'autre
- 🌐 **WAN** : rien n'entre, sauf HTTP 80 vers le serveur web

### Ressources des VMs

| VM | RAM | vCPU | Disque | Pourquoi |
|---|:---:|:---:|:---:|---|
| pfSense | 2 Go | 2 | 10 Go | FreeBSD léger, optimisé réseau |
| Windows Server 2022 | 8 Go | 4 | 60 Go | 3 rôles simultanés (AD, DNS, DHCP) |
| Windows 11 | 4 Go | 4 | 64 Go | Interface graphique réactive |
| Ubuntu MariaDB | 4 Go | 2 | 20 Go | Base légère |
| Ubuntu Docker | 4 Go | 2 | 20 Go | Conteneurs + marge cache |
| Debian GUI | 4 Go | 2 | 20 Go | Interface graphique légère |

---

## 4. 🛠️ Le projet étape par étape

### Étape 1 · Hyperviseur

| Quoi | Comment | Pourquoi |
|---|---|---|
| Proxmox VE prévu | Hyperviseur type 1 | Standard en entreprise |
| **VMware Workstation Pro retenu** | Hyperviseur type 2 | Virtualisation imbriquée et RAM/CPU insuffisantes pour Proxmox |
| Réseaux isolés | **LAN Segments** | Commutateurs virtuels sans DHCP ni passerelle VMware : pfSense est la seule sortie |

### Étape 2 · Machines virtuelles

- 6 VMs créées et dimensionnées (voir tableau ci-dessus)
- **Une seule carte réseau par VM**, sur le segment de sa zone
- pfSense : **4 cartes** = 1 NAT (WAN) + 3 LAN Segments

### Étape 3 · Segmentation et adressage

- 3 zones = 3 LAN Segments = 3 sous-réseaux /24
- **Statique** pour les piliers (pfSense, Windows Server, serveur web)
- **DHCP** pour les clients du VLAN Admin
- **Réservation DHCP** pour la BDD : IP fixe + gestion centralisée

### Étape 4 · Services

**Windows Server 2022 (`.10.10`)**
1. Installation des rôles AD DS, DNS, DHCP
2. Promotion en contrôleur de domaine `datacenter.lan`
3. Étendue DHCP `.50 → .100`, passerelle `.10.1`, DNS `.10.10`
4. Réservation `.10.99` sur l'adresse MAC de la VM MariaDB
5. Mise à jour DNS dynamique : chaque bail crée l'enregistrement du client

**Serveur web Docker (`.20.10`)**
1. Dockerfile : `FROM nginx:alpine` + copie de `index.html` + `EXPOSE 80`
2. `docker build -t mon-image-web .`
3. `docker run -d --name serveur-dmz --restart always -p 80:80 mon-image-web`

**MariaDB (`.10.99`)**
1. `bind-address = 0.0.0.0` dans `50-server.cnf` (écoute réseau)
2. Base `labo_db`
3. Utilisateur `web_user@'192.168.20.10'` : lié à l'IP du serveur web
4. Droits limités à `labo_db.*`

### Étape 5 · pfSense

1. Affectation des 4 interfaces (WAN, LAN, DMZ, GUEST) et de leurs IP `.1`
2. Règles par interface, **exceptions avant blocages**
3. Outbound NAT : toutes les zones sortent avec l'IP WAN
4. Port forwarding : `WAN:80 → 192.168.20.10:80`

### Étape 6 · Continuité

- Snapshot de pfSense **avant chaque modification**
- Tests après chaque modification
- Rollback si échec

---

## 5. 🧱 Règles pfSense à connaître

**3 principes :**
1. **Default Deny** : ce qui n'est pas autorisé est bloqué
2. **Premier match** : lecture de haut en bas, la première règle qui correspond s'applique
3. **Stateful** : les réponses d'une connexion autorisée repassent automatiquement

**Le schéma de chaque interface est toujours le même :**

```
1. PASS  exceptions précises (port + IP)
2. BLOCK zones internes protégées
3. PASS  tout le reste (= Internet)
```

| Interface | Exceptions | Blocage | Reste |
|---|---|---|---|
| **LAN** | Anti-lockout 80/443 · SSH 22 | BDD → * · Admin → DMZ/Invités | Internet |
| **DMZ** | SQL 3306 → `.10.99` · DNS 53 → `.10.10` | DMZ → Admin | Internet |
| **GUEST** | HTTP 80 → `.20.10` · DNS 53 → `.10.10` | Invités → Admin/DMZ | Internet |
| **WAN** | — | Bogons · tout IPv4 entrant | — |

**À savoir expliquer :** pourquoi la BDD peut répondre au serveur web alors qu'une règle bloque tout ce qui sort d'elle ? → **Stateful** : la connexion est initiée par le serveur web et autorisée par la règle DMZ. La réponse appartient à une connexion déjà établie, elle n'est pas réévaluée par la règle de blocage.

---

## 6. 💻 Commandes clés

| Action | Commande | Machine |
|---|---|---|
| Construire l'image | `docker build -t mon-image-web .` | Web |
| Lancer le conteneur | `docker run -d --name serveur-dmz --restart always -p 80:80 mon-image-web` | Web |
| Vérifier le conteneur | `docker ps` · `docker logs serveur-dmz` | Web |
| Tester le site | `curl http://192.168.20.10` | Invités |
| Redémarrer MariaDB | `sudo systemctl restart mariadb` | BDD |
| Vérifier l'écoute 3306 | `ss -tlnp \| grep 3306` | BDD |
| Voir les droits SQL | `SHOW GRANTS FOR 'web_user'@'192.168.20.10';` | BDD |
| Tester la chaîne complète | `mariadb -h 192.168.10.99 -u web_user -p` | Web |
| Tester le DNS | `nslookup datacenter.lan 192.168.10.10` | Toutes |
| Voir son IP / bail | `ipconfig /all` · `ipconfig /renew` | Windows |
| Voir son IP | `ip a` · `ip route` | Linux |
| Logs du pare-feu | *Status → System Logs → Firewall* | pfSense |
| Table d'états | *Diagnostics → States* | pfSense |
| Sauvegarde config | *Diagnostics → Backup & Restore* | pfSense |

---

## 7. ❓ Questions d'entretien

### Projet et choix

<details><summary><b>Pourquoi ce projet ?</b></summary>

Pour manipuler, dans un environnement maîtrisé, toutes les briques d'un datacenter réel : virtualisation, segmentation, pare-feu, annuaire, conteneurs, base de données, et surtout les faire fonctionner ensemble de façon sécurisée.
</details>

<details><summary><b>Pourquoi être passé de Proxmox à VMware ?</b></summary>

La machine hôte ne supportait pas correctement la virtualisation imbriquée, et la RAM/CPU ne suffisait pas pour faire tourner les 6 VMs de façon stable. On a basculé sur VMware Workstation en gardant exactement la même architecture logique : mêmes zones, même adressage, mêmes règles. **Message à faire passer :** une bonne architecture ne dépend pas de l'hyperviseur.
</details>

<details><summary><b>Type 1 vs type 2 ?</b></summary>

Type 1 (Proxmox, ESXi) : installé directement sur le matériel, utilisé en production pour les performances. Type 2 (VMware Workstation, VirtualBox) : installé sur un OS, idéal pour les labs et les tests.
</details>

<details><summary><b>Quel a été ton rôle dans le trinôme ?</b></summary>

*À personnaliser avec ce que tu as réellement fait.* Être précis : « j'ai pris en charge X et Y, et j'ai participé à Z ».
</details>

### Réseau

<details><summary><b>Ce sont de vrais VLANs ?</b></summary>

Pas au sens 802.1Q : il n'y a pas de tag. Chaque **LAN Segment VMware** est un domaine de niveau 2 séparé, ce qui donne la même isolation logique qu'un VLAN. En production, on aurait un switch avec un **trunk 802.1Q** vers pfSense, et des **interfaces VLAN** sur pfSense (une par tag).
</details>

<details><summary><b>Pourquoi des LAN Segments plutôt que NAT ou Host-Only ?</b></summary>

NAT et Host-Only fournissent un DHCP VMware et/ou un accès à l'hôte. Les LAN Segments sont totalement isolés : pas de DHCP VMware (donc pas de conflit avec Windows Server), pas de passerelle. La seule sortie est pfSense.
</details>

<details><summary><b>Qu'est-ce qu'une DMZ ?</b></summary>

Une zone intermédiaire qui héberge les services exposés (web). Si un serveur de la DMZ est compromis, l'attaquant ne peut pas atteindre le réseau interne, car le pare-feu bloque la DMZ vers l'Admin.
</details>

<details><summary><b>Statique, DHCP ou réservation : comment tu choisis ?</b></summary>

Statique pour les piliers (pfSense, contrôleur de domaine, serveur web) qui doivent être toujours joignables et ciblés par des règles. DHCP pour les postes clients. Réservation quand on veut une IP fixe **et** une gestion centralisée : c'est le cas de la BDD.
</details>

<details><summary><b>Différence entre NAT sortant et port forwarding ?</b></summary>

**Outbound NAT** : les machines internes sortent avec l'IP WAN de pfSense, leurs IP privées sont masquées. **Port forwarding** (NAT entrant) : un port de l'IP WAN est redirigé vers une machine interne, ici `WAN:80 → 192.168.20.10:80`.
</details>

### pfSense et sécurité

<details><summary><b>Qu'est-ce que le Default Deny ?</b></summary>

Tout est interdit par défaut, on n'ouvre que le strict nécessaire. C'est l'inverse d'une liste noire : on ne bloque pas ce qui est dangereux, on autorise uniquement ce qui est utile.
</details>

<details><summary><b>Pourquoi l'ordre des règles est important ?</b></summary>

pfSense applique la **première règle qui correspond**. Si le blocage DMZ → Admin était placé avant l'autorisation 3306, le serveur web ne pourrait plus joindre la base. Les exceptions vont toujours en haut.
</details>

<details><summary><b>C'est quoi un pare-feu stateful ?</b></summary>

Il garde une table des connexions en cours. Quand une connexion est autorisée, ses paquets de réponse sont acceptés automatiquement, sans règle de retour. Résultat : on n'écrit les règles que dans le sens d'initiation.
</details>

<details><summary><b>À quoi sert l'anti-lockout ?</b></summary>

C'est une règle qui garantit l'accès à l'interface web de pfSense depuis le LAN, même si on écrit une règle de blocage trop large. Sans elle, on peut se couper soi-même l'accès à l'administration.
</details>

<details><summary><b>Que sont les bogons ?</b></summary>

Des adresses IP qui ne devraient jamais apparaître sur Internet (réservées ou non attribuées). Les bloquer sur le WAN protège contre l'usurpation d'adresse (*spoofing*).
</details>

<details><summary><b>Comment la base de données est-elle protégée ?</b></summary>

Défense en profondeur, 4 barrières :
1. Placée dans la zone la plus sûre (Admin)
2. pfSense : seul `.20.10` peut joindre le port 3306
3. pfSense : la BDD ne peut initier aucune connexion
4. MariaDB : `web_user` n'existe que pour l'IP `.20.10`, avec des droits sur `labo_db` uniquement
</details>

### Services

<details><summary><b>Pourquoi le DHCP sur Windows Server et pas sur pfSense ?</b></summary>

Pour profiter de l'intégration Microsoft : chaque bail DHCP met à jour le DNS d'Active Directory automatiquement. pfSense aurait pu le faire, mais sans ce lien avec AD.
</details>

<details><summary><b>Pourquoi Docker plutôt qu'une installation classique de Nginx ?</b></summary>

Isolation (l'attaquant reste dans le conteneur), légèreté, démarrage en secondes, déploiement reproductible avec un Dockerfile. L'image Alpine réduit encore la surface d'attaque.
</details>

<details><summary><b>Différence entre VM et conteneur ?</b></summary>

Une VM embarque un OS complet avec son noyau (lourd, boot de plusieurs minutes). Un conteneur partage le noyau de l'hôte (léger, démarre en secondes). Contrepartie : l'isolation d'un conteneur est moins forte que celle d'une VM.
</details>

<details><summary><b>Dockerfile, image, conteneur ?</b></summary>

Le **Dockerfile** est la recette, l'**image** est le résultat figé, le **conteneur** est l'image en cours d'exécution.
</details>

<details><summary><b>bind-address = 0.0.0.0, ce n'est pas dangereux ?</b></summary>

Seul, si. MariaDB écoute alors sur toutes ses interfaces. C'est acceptable ici parce que pfSense ne laisse passer le port 3306 que depuis `.20.10`, et que le compte SQL est lié à cette IP. En amélioration, on mettrait l'IP précise du serveur (`192.168.10.99`).
</details>

### Ouverture

<details><summary><b>Comment tu passerais ça en production ?</b></summary>

Hyperviseur type 1 en cluster (Proxmox), vrais VLANs 802.1Q, pfSense en haute disponibilité (CARP), supervision Zabbix, sauvegardes automatisées hors site, HTTPS sur le serveur web, et déploiement automatisé (Ansible, Terraform).
</details>

<details><summary><b>Qu'est-ce que tu ferais différemment ?</b></summary>

Bloquer explicitement DMZ → Invités, mettre l'IP précise dans `bind-address`, ajouter HTTPS, automatiser les sauvegardes, et documenter plus de tests avec des captures.
</details>

---

## 8. 🎬 Scénarios

### 🔴 Le serveur web est compromis

1. L'attaquant est d'abord **enfermé dans le conteneur** Alpine (pas de SSH, pas d'outils)
2. S'il en sort, il est sur l'hôte Ubuntu en DMZ
3. Il tente d'atteindre le contrôleur de domaine → **bloqué** par la règle DMZ → Admin
4. Il tente la BDD → seul le port 3306 passe, avec un compte limité à `labo_db`
5. Il ne peut pas aller plus loin dans le réseau interne

**Réponse :** isoler la VM (snapshot pour l'analyse), restaurer un état sain, changer le mot de passe de `web_user`, analyser les logs pfSense.

### 🟠 Le serveur web n'arrive plus à joindre la base

Diagnostic de bas en haut :
1. **Réseau** : `ping 192.168.20.1` depuis le web (passerelle OK ?)
2. **IP de la BDD** : est-elle toujours en `.10.99` ? (réservation DHCP)
3. **pfSense** : logs firewall, la règle 3306 est-elle avant le blocage DMZ → Admin ?
4. **Service** : `systemctl status mariadb` et `ss -tlnp | grep 3306`
5. **Écoute** : `bind-address` toujours à `0.0.0.0` ?
6. **SQL** : `SHOW GRANTS` pour `web_user@'192.168.20.10'`

### 🟠 Un poste Windows n'obtient pas d'IP

1. Carte réseau bien sur le **LAN Segment Admin** ?
2. Service DHCP démarré sur Windows Server ? Serveur **autorisé dans AD** ?
3. Étendue active et non pleine (`.50 → .100`) ?
4. Sur le client : `ipconfig /release` puis `ipconfig /renew`
5. IP en `169.254.x.x` = aucun serveur DHCP n'a répondu

### 🟠 Le client invité ne résout pas les noms

1. DNS configuré sur `192.168.10.10` ?
2. Règle GUEST n°2 (TCP/UDP 53) présente et **avant** le blocage Invités → Admin ?
3. Test : `nslookup google.com 192.168.10.10`
4. Le serveur DNS Windows a-t-il des redirecteurs vers Internet ?

### 🟠 Je me suis bloqué l'accès à pfSense

1. Console de la VM pfSense dans VMware (accès direct, sans réseau)
2. Option du menu console pour réinitialiser l'IP de l'interface LAN ou restaurer une configuration
3. Ou **restauration du dernier snapshot** : c'est exactement pour ça qu'on en prenait avant chaque modification

### 🟡 pfSense tombe en panne

Plus aucun routage entre zones ni accès Internet : c'est le **SPOF** de l'architecture.
**Solution :** cluster de 2 pfSense en **CARP** avec une IP virtuelle partagée, basculement automatique.

### 🟡 Le site n'est pas accessible depuis le PC hôte

1. Conteneur actif ? `docker ps`
2. Site accessible depuis les Invités ? (`curl http://192.168.20.10`)
3. Règle de port forwarding `WAN:80 → .20.10:80` présente, avec sa règle WAN associée ?
4. Sur le WAN, l'option de blocage des réseaux privés bloquerait l'hôte, car le WAN VMware est lui-même en IP privée

---

## 9. ⚠️ Limites assumées

Toujours les présenter avec la solution : ça montre du recul.

| Limite | Solution |
|---|---|
| Hyperviseur type 2 | Proxmox ou ESXi sur un hôte dédié |
| Pas de vrai tag 802.1Q | Switch + trunk + interfaces VLAN sur pfSense |
| pfSense = SPOF | Cluster CARP |
| Pas de supervision | Zabbix + SNMP |
| Sauvegardes manuelles sur l'hôte | Sauvegardes automatisées hors site + PRA |
| DMZ → Invités autorisé par la règle générale | Règle BLOCK dédiée |
| HTTP seulement | HTTPS avec certificat |
| `bind-address = 0.0.0.0` | IP précise du serveur |

---

## 10. 📖 Glossaire

| Terme | Définition courte |
|---|---|
| **ACL** | Liste de règles qui autorisent ou bloquent des flux |
| **AD DS** | Annuaire Microsoft : utilisateurs, machines, GPO |
| **Anti-lockout** | Règle qui protège l'accès à l'interface pfSense |
| **Bogons** | IP invalides qui ne devraient jamais venir d'Internet |
| **CARP** | Protocole de redondance de pfSense (IP virtuelle partagée) |
| **Default Deny** | Tout est bloqué sauf ce qui est explicitement autorisé |
| **DMZ** | Zone exposée, isolée du réseau interne |
| **GPO** | Stratégie de groupe appliquée aux machines du domaine |
| **LAN Segment** | Commutateur virtuel VMware totalement isolé |
| **NAT** | Traduction d'adresses (masquage en sortie, redirection en entrée) |
| **PRA** | Plan de reprise d'activité après sinistre |
| **Réservation DHCP** | IP toujours attribuée à la même adresse MAC |
| **Snapshot** | État figé d'une VM, restaurable en quelques secondes |
| **SPOF** | Point de défaillance unique |
| **Stateful** | Pare-feu qui suit l'état des connexions |
| **VLAN** | Réseau logique isolé au niveau 2 |