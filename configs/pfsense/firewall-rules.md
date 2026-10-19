# Règles pfSense

Politique **Default Deny** : tout flux non autorisé explicitement est bloqué.
Les règles sont évaluées **de haut en bas**, la première qui correspond s'applique. pfSense étant **stateful**, les réponses aux connexions autorisées repassent automatiquement.

## Interfaces

| Interface | Réseau VMware | Adresse | Zone |
|---|---|---|---|
| WAN | NAT | 192.168.11.133 (DHCP VMware) | Internet |
| LAN | LAN Segment | 192.168.10.1/24 | VLAN 10 · Administration |
| DMZ | LAN Segment | 192.168.20.1/24 | VLAN 20 · DMZ |
| GUEST | LAN Segment | 192.168.30.1/24 | VLAN 30 · Invités |

## LAN · VLAN 10 · Administration

| # | Action | Proto | Source | Destination | Port | Rôle |
|:---:|:---:|---|---|---|:---:|---|
| 1 | PASS | TCP | * | LAN address | 80, 443 | Anti-lockout : accès à l'interface pfSense |
| 2 | BLOCK | ANY | 192.168.10.99 | * | * | La base de données n'initie aucune connexion |
| 3 | PASS | TCP | VLAN 10 net | * | 22 | Administration des VMs en SSH |
| 4 | BLOCK | ANY | VLAN 10 net | VLAN 20 / 30 | * | Aucun autre flux vers les zones moins sûres |
| 5 | PASS | ANY | VLAN 10 net | * | * | Accès Internet pour l'administration |

## DMZ · VLAN 20

| # | Action | Proto | Source | Destination | Port | Rôle |
|:---:|:---:|---|---|---|:---:|---|
| 1 | PASS | TCP | 192.168.20.10 | 192.168.10.99 | 3306 | Le serveur web interroge la base |
| 2 | PASS | TCP/UDP | 192.168.20.10 | 192.168.10.10 | 53 | Résolution DNS via le contrôleur de domaine |
| 3 | BLOCK | ANY | VLAN 20 net | VLAN 10 net | * | Étanchéité : la DMZ n'atteint pas l'Admin |
| 4 | PASS | ANY | VLAN 20 net | * | * | Mises à jour système et pull d'images Docker |

## GUEST · VLAN 30 · Invités

| # | Action | Proto | Source | Destination | Port | Rôle |
|:---:|:---:|---|---|---|:---:|---|
| 1 | PASS | TCP | VLAN 30 net | 192.168.20.10 | 80 | Consultation du site web |
| 2 | PASS | TCP/UDP | VLAN 30 net | 192.168.10.10 | 53 | Résolution de noms |
| 3 | BLOCK | ANY | VLAN 30 net | VLAN 10 / 20 | * | Isolation des infrastructures critiques |
| 4 | PASS | ANY | VLAN 30 net | * | * | Accès Internet |

## WAN · Périmètre externe

| # | Action | Proto | Source | Destination | Port | Rôle |
|:---:|:---:|---|---|---|:---:|---|
| 1 | BLOCK | ANY | Bogons / réservées | * | * | Anti-spoofing |
| 2 | BLOCK | IPv4 | * | * | * | Aucune connexion entrante non sollicitée |

## NAT

| Type | Règle | Rôle |
|---|---|---|
| Outbound | VLAN 10 / 20 / 30 → IP WAN | Masquer l'adressage interne |
| Port forwarding | WAN:80 → 192.168.20.10:80 | Seul point d'entrée depuis l'extérieur |

## Point d'amélioration identifié

La règle 4 de la DMZ (`VLAN 20 → *`) autorise aussi les flux **DMZ → Invités**. Une règle `BLOCK VLAN 20 → VLAN 30` placée avant elle fermerait ce chemin.
