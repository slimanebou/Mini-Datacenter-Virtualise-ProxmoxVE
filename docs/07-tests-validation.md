# 07 · Tests de validation

[⬅ pfSense](06-pfsense-firewall.md) · [README](../README.md) · [Maintenance ➡](08-maintenance.md)

Chaque test vérifie qu'un flux attendu **passe** ou qu'un flux interdit est **bloqué**.

## Flux autorisés

| # | Depuis | Commande | Résultat attendu | Valide |
|:---:|---|---|---|---|
| 1 | Serveur Web (20.10) | `mariadb -h 192.168.10.99 -u web_user -p` | Invite MariaDB | Routage inter-VLAN, réservation DHCP, règle 3306, privilèges SQL |
| 2 | Client Invités (30.10) | `curl http://192.168.20.10` | Page « Mon Lab DMZ » | Règle HTTP 80 Invités → DMZ |
| 3 | Serveur Web (20.10) | `nslookup datacenter.lan 192.168.10.10` | Réponse DNS | Règle DNS 53 DMZ → Admin |
| 4 | Client Invités (30.10) | `ping 8.8.8.8` | Réponses | Outbound NAT |
| 5 | Windows 11 | `ipconfig /all` | IP entre .50 et .100, DNS 10.10 | DHCP Windows |
| 6 | Windows 11 | `nslookup <nom-du-poste>` | Nom résolu | Mise à jour DNS dynamique |
| 7 | PC hôte | `http://192.168.11.133` | Page « Mon Lab DMZ » | Port forwarding WAN:80 |

## Flux bloqués

| # | Depuis | Commande | Résultat attendu | Valide |
|:---:|---|---|---|---|
| 8 | Serveur Web (20.10) | `ping 192.168.10.10` | Délai dépassé | Étanchéité DMZ → Admin |
| 9 | Serveur Web (20.10) | `ssh 192.168.10.10` | Délai dépassé | Étanchéité DMZ → Admin |
| 10 | Client Invités (30.10) | `ping 192.168.10.99` | Délai dépassé | Isolation Invités → Admin |
| 11 | Client Invités (30.10) | `ssh 192.168.20.10` | Délai dépassé | Seul le port 80 est ouvert vers la DMZ |
| 12 | Serveur BDD (10.99) | `ping 8.8.8.8` | Délai dépassé | Aucune sortie pour la BDD |
| 13 | Autre VM | `mariadb -h 192.168.10.99 -u web_user -p` | Refus | Restriction par IP source |

## Vérifier un blocage dans pfSense

*Status → System Logs → Firewall* : chaque paquet bloqué apparaît avec l'interface, la source, la destination et la règle appliquée.

## Méthode

Après chaque modification des règles, cette série de tests est rejouée. En cas d'échec, retour au snapshot précédent (voir [Maintenance](08-maintenance.md)).

[⬅ pfSense](06-pfsense-firewall.md) · [README](../README.md) · [Maintenance ➡](08-maintenance.md)
