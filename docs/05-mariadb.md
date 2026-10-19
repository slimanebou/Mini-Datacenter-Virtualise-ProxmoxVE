# 05 · Base de données MariaDB

[⬅ Docker](04-docker-dmz.md) · [README](../README.md) · [pfSense ➡](06-pfsense-firewall.md)

Serveur Ubuntu `192.168.10.99` (réservation DHCP) · VLAN 10 · La donnée la plus critique du datacenter.

## Principe de cloisonnement

| Mesure | Niveau | Effet |
|---|---|---|
| Placée dans le VLAN Admin | Réseau | Zone de confiance la plus élevée |
| Aucune sortie autorisée | pfSense | La BDD ne peut initier aucune connexion, même vers Internet |
| Port 3306 ouvert pour 192.168.20.10 uniquement | pfSense | Seul le serveur web peut l'interroger |
| `web_user` lié à l'hôte 192.168.20.10 | MariaDB | Même avec le mot de passe, une autre IP est refusée |
| Droits limités à `labo_db` | MariaDB | Aucun accès aux autres bases |

**Défense en profondeur :** il faut franchir pfSense **et** les contrôles MariaDB pour atteindre les données.

## Configuration réseau

Fichier `/etc/mysql/mariadb.conf.d/50-server.cnf` :

```ini
bind-address = 0.0.0.0
```

Par défaut MariaDB n'écoute qu'en local (`127.0.0.1`). Ce changement autorise l'écoute réseau, le filtrage étant assuré par pfSense et par les comptes SQL.

```bash
sudo systemctl restart mariadb
```

## Comptes et privilèges

```sql
CREATE DATABASE labo_db;
CREATE USER 'web_user'@'192.168.20.10' IDENTIFIED BY '<CHANGE_ME>';
GRANT ALL PRIVILEGES ON labo_db.* TO 'web_user'@'192.168.20.10';
FLUSH PRIVILEGES;
```

## Validation

Depuis le serveur web (192.168.20.10) :

```bash
mariadb -h 192.168.10.99 -u web_user -p
```

Ce test valide en une seule commande : le **routage inter-VLAN**, la **réservation DHCP**, la **règle pfSense** et les **privilèges SQL**.

Fichiers associés : [`configs/mariadb/`](../configs/mariadb/)

[⬅ Docker](04-docker-dmz.md) · [README](../README.md) · [pfSense ➡](06-pfsense-firewall.md)
