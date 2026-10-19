# 01 · Architecture

[⬅ README](../README.md) · [Virtualisation ➡](02-virtualisation.md)

## Objectif

Simuler, sur une seule machine physique, les services réseau et les mécanismes de sécurité d'un datacenter de production : virtualisation, segmentation, pare-feu, annuaire, conteneurs et base de données.

**Problématique :** comment concevoir une infrastructure virtualisée résiliente et sécurisée, capable de fournir des services hétérogènes, tout en respectant les bonnes pratiques de segmentation réseau ?

## Vue d'ensemble

![Architecture](../diagrams/topologie.png)

pfSense est placé au centre : il possède **une interface par zone** et une interface WAN. Toutes les autres VMs n'ont **qu'une seule carte réseau**, branchée sur le segment de leur zone. Aucun flux inter-zones ne peut donc contourner le pare-feu.

## Zones de sécurité

| Zone | Réseau | Niveau de confiance | Contenu | Principe |
|---|---|:---:|---|---|
| VLAN 10 · Admin | 192.168.10.0/24 | Élevé | AD/DNS/DHCP, MariaDB, poste d'admin | Accès strictement restreint |
| VLAN 20 · DMZ | 192.168.20.0/24 | Moyen | Serveur web Docker | Exposée, mais isolée de l'Admin |
| VLAN 30 · Invités | 192.168.30.0/24 | Faible | Client utilisateur | Internet + site web uniquement |

**Scénario de compromission :** si le serveur web est attaqué, l'attaquant est d'abord enfermé dans le conteneur, puis bloqué en DMZ par pfSense. Il ne peut joindre la base que sur le port 3306, avec un compte SQL limité à une seule base.

## Plan d'adressage

Convention : **3ᵉ octet = numéro de VLAN**.

| Zone | Équipement | IP | Attribution |
|---|---|---|---|
| WAN | pfSense | 192.168.11.133 | DHCP VMware (NAT) |
| Admin | pfSense (passerelle) | 192.168.10.1 | Statique |
| Admin | Windows Server 2022 | 192.168.10.10 | Statique |
| Admin | Serveur MariaDB | 192.168.10.99 | Réservation DHCP |
| Admin | Client Windows 11 | 192.168.10.50 – 100 | DHCP Windows |
| DMZ | pfSense (passerelle) | 192.168.20.1 | Statique |
| DMZ | Serveur Web Docker | 192.168.20.10 | Statique |
| Invités | pfSense (passerelle) | 192.168.30.1 | Statique |
| Invités | Client Debian | 192.168.30.10 | Statique |

## Choix d'attribution

| Mode | Utilisé pour | Pourquoi |
|---|---|---|
| **Statique** | pfSense, Windows Server, serveur web | Services piliers toujours joignables à la même adresse, règles pare-feu stables |
| **DHCP** | Clients Windows du VLAN Admin | Tester l'intégration Microsoft : chaque bail met à jour le DNS automatiquement |
| **Réservation DHCP** | Serveur MariaDB | IP fixe pour les règles pfSense + options réseau gérées de façon centralisée |

## Étapes de réalisation

1. Installation de l'hyperviseur (Proxmox VE prévu, VMware Workstation Pro retenu)
2. Création des VMs (Windows Server, Windows 11, Ubuntu x2, Debian, pfSense)
3. Segmentation en 3 zones et définition des plages IP
4. Déploiement des services : AD, DNS, DHCP, serveur web Docker, MariaDB
5. Configuration de pfSense : ACL, routage inter-VLAN, NAT
6. Stockage et continuité : allocation disque, snapshots

[⬅ README](../README.md) · [Virtualisation ➡](02-virtualisation.md)
