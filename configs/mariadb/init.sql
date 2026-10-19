-- Initialisation de la base · Serveur MariaDB 192.168.10.99
-- Exécution : sudo mariadb < init.sql
-- Remplacer <CHANGE_ME> par un mot de passe robuste avant exécution.

CREATE DATABASE labo_db;

-- Utilisateur applicatif utilisable UNIQUEMENT depuis le serveur web de la DMZ
CREATE USER 'web_user'@'192.168.20.10' IDENTIFIED BY '<CHANGE_ME>';

-- Droits limités à la seule base labo_db
GRANT ALL PRIVILEGES ON labo_db.* TO 'web_user'@'192.168.20.10';

FLUSH PRIVILEGES;

-- Vérification
SHOW GRANTS FOR 'web_user'@'192.168.20.10';
