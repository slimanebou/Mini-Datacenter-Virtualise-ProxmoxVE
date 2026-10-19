# 04 · Serveur web conteneurisé · DMZ

[⬅ Windows Server](03-windows-ad.md) · [README](../README.md) · [MariaDB ➡](05-mariadb.md)

Serveur Ubuntu `192.168.20.10` (statique) · VLAN 20 · Docker + Nginx Alpine.

## Pourquoi Docker plutôt qu'une installation classique

| | Machine virtuelle | Conteneur Docker |
|---|---|---|
| Noyau | Embarque son propre OS complet | Partage le noyau de l'hôte |
| Taille | Plusieurs Go | Quelques Mo |
| Démarrage | Plusieurs minutes (boot) | Quelques secondes |
| Ressources | Élevées | Faibles, densification possible |

## Les 3 briques Docker

| Brique | Rôle |
|---|---|
| **Dockerfile** | La recette de construction |
| **Image** | Le résultat figé, prêt à déployer |
| **Conteneur** | L'instance en cours d'exécution |

## Intérêt pour la DMZ

- **Sandboxing** : un attaquant qui compromet Nginx reste enfermé dans le conteneur et ne voit pas le système hôte
- **Surface d'attaque réduite** : l'image Alpine ne contient ni SSH, ni compilateur, ni outils superflus

## Déploiement

**Dockerfile**
```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
```

**Construction de l'image**
```bash
docker build -t mon-image-web .
```

**Lancement du conteneur**
```bash
docker run -d --name serveur-dmz --restart always -p 80:80 mon-image-web
```

| Option | Effet |
|---|---|
| `-d` | Exécution en arrière-plan |
| `--name serveur-dmz` | Nom du conteneur |
| `--restart always` | Redémarrage automatique (crash ou reboot) |
| `-p 80:80` | Port 80 de l'hôte → port 80 du conteneur |

## Accès au site

| Depuis | Comment |
|---|---|
| VLAN Invités | Règle pfSense : TCP 80 vers 192.168.20.10 |
| Extérieur (PC hôte) | Port forwarding pfSense : WAN:80 → 192.168.20.10:80 |

Fichiers associés : [`configs/docker/`](../configs/docker/)

[⬅ Windows Server](03-windows-ad.md) · [README](../README.md) · [MariaDB ➡](05-mariadb.md)
