# 02 · Virtualisation

[⬅ Architecture](01-architecture.md) · [README](../README.md) · [Windows Server ➡](03-windows-ad.md)

## Hyperviseur : type 1 ou type 2

| | Type 1 · Bare metal | Type 2 · Hébergé |
|---|---|---|
| Installation | Directement sur le matériel | Comme un logiciel sur un OS hôte |
| Exemples | Proxmox VE, VMware ESXi | VMware Workstation Pro, VirtualBox |
| Usage | Production : performances, stabilité | Tests et développement : flexibilité |

## De Proxmox VE à VMware Workstation Pro

Le projet a été **conçu pour Proxmox VE** (voir le [cahier des charges initial](cahier-des-charges-initial-proxmox.pdf)).

**Problème rencontré :** la machine hôte ne suivait pas.
- Virtualisation imbriquée mal supportée
- RAM et CPU insuffisants pour faire tourner les 6 VMs de façon stable

**Décision :** basculer sur VMware Workstation Pro en conservant **toute l'architecture logique** : mêmes zones, même adressage, mêmes règles de filtrage. Seule la technologie d'isolation change.

| | Prévu (Proxmox VE) | Réalisé (VMware Workstation) |
|---|---|---|
| Hyperviseur | Type 1 | Type 2 |
| Isolation | Bridges + VLAN | LAN Segments |
| Snapshots | Proxmox | VMware |
| Architecture logique | — | Identique |

## Modes réseau VMware

| Mode | Comportement | Retenu ? |
|---|---|:---:|
| Bridged | La VM apparaît sur le réseau physique, IP fournie par la box | ❌ |
| NAT | VM cachée derrière l'hôte, DHCP et passerelle fournis par VMware | ✅ WAN de pfSense uniquement |
| Host-Only | Réseau privé entre les VMs et l'hôte | ❌ |
| **LAN Segment** | Commutateur virtuel totalement isolé | ✅ Les 3 zones |

**Pourquoi les LAN Segments :**
- Aucun DHCP VMware : le DHCP de Windows Server est le seul à répondre
- Aucune passerelle vers l'hôte ou Internet
- Seule sortie possible : pfSense

## Interfaces réseau

| VM | Cartes | Rattachement |
|---|:---:|---|
| pfSense | 4 | 1 NAT (WAN) + 3 LAN Segments (Admin, DMZ, Invités) |
| Toutes les autres | 1 | Le LAN Segment de leur zone uniquement |

## Dimensionnement (capacity planning)

| VM | OS | RAM | vCores | Disque |
|---|---|:---:|:---:|:---:|
| pfSense | FreeBSD | 2 Go | 2 (2×1) | 10 Go |
| Contrôleur de domaine | Windows Server 2022 | 8 Go | 4 (2×2) | 60 Go |
| Poste d'administration | Windows 11 | 4 Go | 4 (2×2) | 64 Go |
| Serveur BDD | Ubuntu Server | 4 Go | 2 (2×1) | 20 Go |
| Serveur Web | Ubuntu Server | 4 Go | 2 (2×1) | 20 Go |
| Client Invités | Debian GUI | 4 Go | 2 (2×1) | 20 Go |
| **Total** | | **26 Go** | **16** | **194 Go** |

**Justifications :**
- **Windows Server 8 Go** : AD, DNS et DHCP simultanés sans ralentissement
- **4 vCores pour Windows** : réactivité de l'interface graphique
- **4 Go pour Linux** : suffisant pour Docker ou une interface graphique légère, avec marge pour le cache
- **pfSense 2 Go** : noyau FreeBSD optimisé réseau, largement suffisant pour le filtrage

[⬅ Architecture](01-architecture.md) · [README](../README.md) · [Windows Server ➡](03-windows-ad.md)
