#!/usr/bin/env bash

apt-get update -y

#Desinstalo el apache ya que ahora estará dentro del Docker
if [ -x "$(command -v apache2)" ];then
	sudo apt-get remove --purge apache2 -y
	sudo apt-gets autoremove -y
fi

# Directorio para los archivos de la base de datos MySQL. El servidor de la base de datos
# es instalado mediante una imagen de Docker. Esto está definido en el archivo
# docker-compose.yml
if [ ! -d "/var/db/mysql" ]; then
	sudo mkdir -p /var/db/mysql
fi

# Muevo el archivo de configuración de firewall al lugar correspondiente
if [ -f "/tmp/ufw" ]; then
	sudo mv -f /tmp/ufw /etc/default/ufw
fi

##Genero una partición swap. Previene errores de falta de memoria
if [ ! -f "/swapdir/swapfile" ]; then
	sudo mkdir /swapdir
	cd /swapdir
	sudo dd if=/dev/zero of=/swapdir/swapfile bs=1024 count=2000000
	sudo mkswap -f  /swapdir/swapfile
	sudo chmod 600 /swapdir/swapfile
	sudo swapon swapfile
	echo "/swapdir/swapfile       none    swap    sw      0       0" | sudo tee -a /etc/fstab /etc/fstab
	sudo sysctl vm.swappiness=10
	echo vm.swappiness = 10 | sudo tee -a /etc/sysctl.conf
fi

## configuración servidor web
#copio el archivo de configuración del repositorio en la configuración del servidor web
#if [ -f "/tmp/devops.site.conf" ]; then
#	echo "Copio el archivo de configuracion de apache"
#	sudo mv /tmp/devops.site.conf /etc/apache2/sites-available
#	#activo el nuevo sitio web
#	sudo a2ensite devops.site.conf
#	#desactivo el default
#	sudo a2dissite 000-default.conf
#	#refresco el servicio del servidor web para que tome la nueva configuración
#	sudo service apache2 reload
#fi

# ruta raíz del servidor web
APACHE_ROOT="/var/www"
# ruta de la aplicación
APP_PATH="$APACHE_ROOT/utn-apps/"

if [ ! -d "$APP_PATH" ]; then
	echo "clono el repositorio"
	cd $APACHE_ROOT
	sudo git clone https://github.com/gabogosp/utn-apps.git
	cd $APP_PATH
	sudo git checkout unidad-2
else
	echo "actualizo el repositorio"
	cd $APACHE_ROOT
	cd $APP_PATH
	sudo git checkout unidad-2
	sudo git pull
fi

#sudo apt-get update
#sudo apt-get install -y php7.2
#php -v

#Desinstalo el php ya que ahora estará dentro del Docker
if [ -x "$(command -v php7.2)" ];then
	sudo apt-get remove --purge php7.2 -y
	sudo apt-get autoremove -y
fi

######## Instalacion de DOCKER ########
if [ ! -x "$(command -v docker)" ]; then
	sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

	##Configuramos el repositorio
	curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" > /tmp/docker_gpg
	sudo apt-key add < /tmp/docker_gpg && sudo rm -f /tmp/docker_gpg
	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

	#Actualizo los paquetes con los nuevos repositorios
	sudo apt-get update -y

	#Instalo docker desde el repositorio oficial
	sudo apt-get install -y docker-ce docker-compose

	#Lo configuro para que inicie en el arranque
	sudo systemctl enable docker
fi

echo "Levanto el docker"
	cd /vagrant/docker/
	sudo docker-compose up -d
