# Serveur web de la DMZ (VLAN 20 · 192.168.20.10)
# Image Alpine : pas de shell SSH, pas de compilateur, surface d'attaque minimale

FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80
