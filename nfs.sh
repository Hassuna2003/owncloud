# Actualizo la lista de paquetes disponibles
sudo apt-get update -y

# Instalo NFS, PHP 7.4 y los módulos necesarios para OwnCloud
sudo apt-get install -y nfs-kernel-server php7.4 php7.4-fpm php7.4-mysql php7.4-gd php7.4-xml php7.4-mbstring php7.4-curl php7.4-zip php7.4-intl php7.4-ldap unzip curl

# Creo la carpeta compartida para OwnCloud y configuro los permisos
mkdir -p /var/nfs/general
sudo chown -R www-data:www-data /var/nfs/general  # Cambio el propietario a www-data
sudo chmod -R 755 /var/nfs/general               # Permisos de lectura, escritura y ejecución adecuados

# Configuro NFS para compartir la carpeta con los servidores backend
sudo echo "/var/nfs/general 192.168.10.30(rw,sync,no_subtree_check)" >> /etc/exports
sudo echo "/var/nfs/general 192.168.10.31(rw,sync,no_subtree_check)" >> /etc/exports

# Aplico los cambios en NFS y reinicio el servicio
sudo exportfs -a
sudo systemctl restart nfs-kernel-server

# Descargo y descomprimo OwnCloud en la carpeta compartida
cd /tmp
sudo wget https://download.owncloud.com/server/stable/owncloud-10.9.1.zip
sudo unzip owncloud-10.9.1.zip
sudo mv owncloud /var/nfs/general/

# Configuro permisos correctos para OwnCloud
sudo chown -R www-data:www-data /var/nfs/general/owncloud  # Asigno propietario
sudo chmod -R 755 /var/nfs/general/owncloud               # Permisos adecuados

# Creo un archivo de configuración automática para OwnCloud
cat <<EOF > /var/nfs/general/owncloud/config/autoconfig.php
<?php
\$AUTOCONFIG = array(
  "dbtype" => "mysql",
  "dbname" => "owncloud_db",
  "dbuser" => "owncloud_user",
  "dbpassword" => "2024",
  "dbhost" => "192.168.20.40",
  "directory" => "/var/nfs/general/owncloud/data",
  "adminlogin" => "admin",
  "adminpass" => "2024"
);
EOF

# Configuro PHP-FPM para que escuche en la IP del servidor NFS en el puerto 9000
sudo sed -i 's/^listen = .*/listen = 192.168.10.20:9000/' /etc/php/7.4/fpm/pool.d/www.conf

# Modifico el estilo de OwnCloud cambiando el color de fondo (ejemplo simple)
sudo sed -i 's/background-color: .*/background-color: #ff0000;/' /var/nfs/general/owncloud/core/css/styles.css

# Reinicio PHP-FPM para aplicar los cambios
sudo systemctl restart php7.4-fpm

# Elimino la ruta por defecto del sistema
sudo ip route del default