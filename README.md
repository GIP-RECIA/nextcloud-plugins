# recia-nextcloud

##Installation

###Installation de LAMP

Nextcloud fonctionne avec MariaDB/Mysql, Apache, et PHP. Vous devez donc installer ces programmes sur votre système.

Tout d’abord, mettez à jour votre système:

```
apt-get update -y && apt-get upgrade -y
```

Puis, procédez à l’installation de d’Apache, de PHP et autres programmes requis pour l’installation de Nextcloud.

```
apt-get install apache2 libapache2-mod-php7.0 -y
apt-get install php7.0-gd php7.0-json php7.0-mysql php7.0-curl php7.0-mbstring -y
apt-get install php7.0-intl php7.0-mcrypt php-imagick php7.0-xml php7.0-zip zip -y
```

Enfin, il faut créer la BDD MySQL/MariaDB pour nextcloud.

### Installation de Nextcloud

Cloner le projet dans ```/var/www/html/``` (ou faites un lien symbolique)

Modifier le propriétaire de dossier:
```
chown -R www-data:www-data /var/www/html/recia-nextcloud
```

