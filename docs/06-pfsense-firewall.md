# 06 · Pare-feu pfSense · Filtrage et NAT

[⬅ MariaDB](05-mariadb.md) · [README](../README.md) · [Tests ➡](07-tests-validation.md)

## Stratégie

| Principe | Application |
|---|---|
| **Stateful inspection** | pfSense suit l'état des connexions : les réponses aux flux autorisés repassent sans règle supplémentaire |
| **Default Deny** | Tout flux non explicitement autorisé est bloqué |
| **Premier match** | Les règles sont lues de haut en bas, la première qui correspond s'applique |
| **Segmentation** | Une compromission en DMZ ne permet pas de rebondir vers l'Admin |

## Matrice de flux

| Source ↓ · Destination → | Admin | DMZ | Invités | Internet |
|---|:---:|:---:|:---:|:---:|
| **Admin** | ✅ | SSH 22 | SSH 22 | ✅ (BDD : ❌) |
| **DMZ** | SQL 3306 + DNS 53 | — | ✅ | ✅ |
| **Invités** | DNS 53 | HTTP 80 | — | ✅ |
| **WAN** | ❌ | HTTP 80 (port forwarding) | ❌ | — |

## Règles par interface

### LAN · VLAN 10

| # | Action | Proto | Source | Destination | Port | Rôle |
|:---:|:---:|---|---|---|:---:|---|
| 1 | PASS | TCP | * | LAN address | 80, 443 | Anti-lockout |
| 2 | BLOCK | ANY | 192.168.10.99 | * | * | Aucune sortie pour la BDD |
| 3 | PASS | TCP | VLAN 10 | * | 22 | Administration SSH |
| 4 | BLOCK | ANY | VLAN 10 | VLAN 20/30 | * | Pas d'autres flux vers les zones moins sûres |
| 5 | PASS | ANY | VLAN 10 | * | * | Accès Internet |

**Ordre :** la règle 2 doit précéder la 5, sinon la BDD aurait accès à Internet. La règle 3 précède la 4 pour que le SSH passe avant le blocage général.

### DMZ · VLAN 20

| # | Action | Proto | Source | Destination | Port | Rôle |
|:---:|:---:|---|---|---|:---:|---|
| 1 | PASS | TCP | 192.168.20.10 | 192.168.10.99 | 3306 | Accès à la base |
| 2 | PASS | TCP/UDP | 192.168.20.10 | 192.168.10.10 | 53 | DNS |
| 3 | BLOCK | ANY | VLAN 20 | VLAN 10 | * | Étanchéité DMZ → Admin |
| 4 | PASS | ANY | VLAN 20 | * | * | Mises à jour, docker pull |

**Ordre :** les exceptions (1, 2) sont placées avant le blocage (3).

### GUEST · VLAN 30

| # | Action | Proto | Source | Destination | Port | Rôle |
|:---:|:---:|---|---|---|:---:|---|
| 1 | PASS | TCP | VLAN 30 | 192.168.20.10 | 80 | Site web |
| 2 | PASS | TCP/UDP | VLAN 30 | 192.168.10.10 | 53 | DNS |
| 3 | BLOCK | ANY | VLAN 30 | VLAN 10/20 | * | Isolation |
| 4 | PASS | ANY | VLAN 30 | * | * | Internet |

### WAN

| # | Action | Proto | Source | Destination | Rôle |
|:---:|:---:|---|---|---|---|
| 1 | BLOCK | ANY | Bogons / réservées | * | Anti-spoofing |
| 2 | BLOCK | IPv4 | * | * | Aucune connexion entrante non sollicitée |

## NAT

| Type | Règle | Rôle |
|---|---|---|
| **Outbound NAT** | Toutes les zones → IP WAN de pfSense | Navigation sans exposer l'adressage interne |
| **Port forwarding** | WAN:80 → 192.168.20.10:80 | Seul point d'entrée depuis l'extérieur |

## Point d'amélioration

La règle 4 de la DMZ (`VLAN 20 → *`) autorise aussi DMZ → Invités. Correction : ajouter `BLOCK VLAN 20 → VLAN 30` avant elle.

Fichier associé : [`configs/pfsense/firewall-rules.md`](../configs/pfsense/firewall-rules.md)

[⬅ MariaDB](05-mariadb.md) · [README](../README.md) · [Tests ➡](07-tests-validation.md)
