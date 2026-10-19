# Fichiers de configuration

| Dossier | Fichier | Machine cible | Contenu |
|---|---|---|---|
| `docker/` | `Dockerfile` | Serveur Web · 192.168.20.10 | Image Nginx Alpine |
| `docker/` | `index.html` | Serveur Web · 192.168.20.10 | Page « Mon Lab DMZ » |
| `docker/` | `deploy.sh` | Serveur Web · 192.168.20.10 | Build + lancement du conteneur |
| `mariadb/` | `50-server.cnf` | Serveur BDD · 192.168.10.99 | Écoute réseau (`bind-address`) |
| `mariadb/` | `init.sql` | Serveur BDD · 192.168.10.99 | Base, utilisateur restreint, droits |
| `pfsense/` | `firewall-rules.md` | pfSense | Interfaces, 15 règles, NAT |
| `windows-server/` | `dhcp-dns-ad.md` | Windows Server · 192.168.10.10 | Domaine, DNS, étendue DHCP, réservation |

## Déploiement rapide

**Serveur web (DMZ)**
```bash
cd configs/docker
chmod +x deploy.sh && ./deploy.sh
```

**Base de données (Admin)**
```bash
sudo cp configs/mariadb/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
sudo systemctl restart mariadb
sudo mariadb < configs/mariadb/init.sql
```

**Test de la chaîne complète** (depuis 192.168.20.10)
```bash
mariadb -h 192.168.10.99 -u web_user -p
```

> ⚠️ Environnement de laboratoire : `<CHANGE_ME>` est à remplacer, aucun secret réel n'est versionné.
