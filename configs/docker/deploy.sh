#!/usr/bin/env bash
# Construction et lancement du serveur web de la DMZ
# À exécuter sur le serveur Ubuntu 192.168.20.10, dans le dossier configs/docker/

set -e

docker build -t mon-image-web .

docker rm -f serveur-dmz 2>/dev/null || true
docker run -d --name serveur-dmz --restart always -p 80:80 mon-image-web

docker ps --filter name=serveur-dmz
