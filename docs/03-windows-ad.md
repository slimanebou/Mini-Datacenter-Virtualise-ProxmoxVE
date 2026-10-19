# 03 · Windows Server 2022 · AD DS, DNS, DHCP

[⬅ Virtualisation](02-virtualisation.md) · [README](../README.md) · [Docker ➡](04-docker-dmz.md)

Serveur `192.168.10.10` (statique) · VLAN 10 · Le pilier de la zone Admin.

## Rôles installés

| Rôle | Fonction |
|---|---|
| **AD DS** | Domaine `datacenter.lan` : utilisateurs, machines et GPO centralisés |
| **DNS** | Résolution de noms, zone intégrée à Active Directory |
| **DHCP** | Attribution automatique des adresses du VLAN Admin |

## Étendue DHCP

| Paramètre | Valeur |
|---|---|
| Plage | 192.168.10.50 → 192.168.10.100 |
| Passerelle | 192.168.10.1 (pfSense) |
| DNS | 192.168.10.10 |
| Domaine | datacenter.lan |

## Intégration DNS / DHCP

Quand un client reçoit un bail, son **nom d'hôte est enregistré automatiquement dans le DNS**. On peut joindre une machine par son nom sans gérer d'enregistrements à la main.

## Réservation pour la base de données

L'adresse `192.168.10.99` est associée à l'adresse MAC de la VM MariaDB dans la console DHCP.

| Avantage | Détail |
|---|---|
| Stabilité | IP toujours identique, indispensable car pfSense la cible dans ses règles |
| Centralisation | Un changement d'option (DNS, passerelle) se fait une seule fois, sur le serveur |

## Isolation du DHCP

Le trafic broadcast DHCP reste confiné au LAN Segment Admin :
- pas de conflit avec le réseau physique de l'hôte
- pas de fuite vers la DMZ ou les Invités

## Services rendus aux autres zones

Le DNS est aussi utilisé par la DMZ et les Invités, via une règle pfSense dédiée (port 53 vers `192.168.10.10` uniquement). C'est le seul accès autorisé depuis ces zones vers le contrôleur de domaine.

Fichier associé : [`configs/windows-server/dhcp-dns-ad.md`](../configs/windows-server/dhcp-dns-ad.md)

[⬅ Virtualisation](02-virtualisation.md) · [README](../README.md) · [Docker ➡](04-docker-dmz.md)
