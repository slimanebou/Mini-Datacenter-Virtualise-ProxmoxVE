# Windows Server 2022 · AD DS · DNS · DHCP

Serveur `192.168.10.10` (statique) · VLAN 10 · Administration

## Active Directory

| Paramètre | Valeur |
|---|---|
| Domaine | `datacenter.lan` |
| Rôle | Contrôleur de domaine |
| Usage | Utilisateurs, machines, GPO centralisés |

## DNS

| Paramètre | Valeur |
|---|---|
| Zone | `datacenter.lan` intégrée à Active Directory |
| Clients autorisés | VLAN 10 (local), DMZ et Invités via pfSense (port 53) |
| Mise à jour | Dynamique : chaque bail DHCP enregistre le nom du client |

## DHCP

| Paramètre | Valeur |
|---|---|
| Étendue | `192.168.10.50` → `192.168.10.100` |
| Masque | `255.255.255.0` |
| Passerelle (option 003) | `192.168.10.1` (pfSense) |
| DNS (option 006) | `192.168.10.10` |
| Nom de domaine (option 015) | `datacenter.lan` |

### Réservation

| Machine | Adresse MAC | IP réservée |
|---|---|---|
| Serveur MariaDB (Ubuntu) | MAC de la VM | `192.168.10.99` |

Pourquoi : IP fixe pour les règles pfSense, tout en gardant une gestion centralisée des options réseau.

> Le broadcast DHCP reste confiné au LAN Segment Admin : aucun conflit avec le réseau de l'hôte ni avec les autres zones.
