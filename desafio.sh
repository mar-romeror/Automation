#!/bin/bash

# Variables
REPO="bootcamp-devops-2023"
BRANCH="clase2-linux-bash"
CARPETA="app-295devops-travel"
instalables=("apache2" "php" "libapache2-mod-php" "jq" "php-mysql" "php-mbstring" "php-zip" "php-gd" "php-json" "php-curl" "mariadb-server")
rutaDirectory="/etc/apache2/mods-enabled/dir.conf"
nuevo_orden="DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm"

# Colores
COLOR_ROJO='\033[0;31m'
COLOR_VERDE='\033[0;32m'
COLOR_AZUL='\033[0;34m'
COLOR_RESET='\033[0m'

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${COLOR_ROJO} El script debe ser ejecutado por Administrador${COLOR_RESET}"
else
    echo -e "${COLOR_VERDE}Iniciando el Stage #1${COLOR_RESET}"
    sudo apt-get update
    echo -e "${COLOR_VERDE} SO Actualizado${COLOR_RESET}"
    for instalar in "${instalables[@]}"; do
        if ! dpkg -l "$instalar" > /dev/null 2>&1; then
            echo -e "${COLOR_VERDE}Instalando el paquete $instalar${COLOR_RESET}"
            apt install -y $instalar
            if [ $? -eq 0 ]; then
                echo -e "${COLOR_VERDE}Se instalo correctamente el paquete $instalar${COLOR_RESET}"
            else
                echo -e "${COLOR_ROJO}Error instalando el paquete $instalar${COLOR_RESET}"
            fi
        else
            echo -e "${COLOR_ROJO}El paquete $instalar ya fue instalado${COLOR_RESET}"
        fi
    done
    sudo systemctl enable apache2
    sudo systemctl start apache2
    sudo systemctl status apache2 
    echo -e "${COLOR_VERDE}Stage #1 Finalizado${COLOR_RESET}"

    echo -e "${COLOR_AZUL}Iniciando el Stage #2${COLOR_RESET}"
    if [ -d "$REPO" ]; then
        echo -e "${COLOR_ROJO}El Repositorio ya existe${COLOR_RESET}"
        echo -e "${COLOR_VERDE}Haciendo pull para traer los ultimos cambios${COLOR_RESET}"
        cd $REPO
        ls
        git pull
        git checkout $BRANCH
        cd ..
        sudo cp -r $REPO/* /var/www/html
        echo -e "${COLOR_VERDE}Pull realizado con exito${COLOR_RESET}"
    else
        echo -e "${COLOR_VERDE}El Repositorio NO existe${COLOR_RESET}"
        echo -e "${COLOR_VERDE}clonando el Repositorio${COLOR_RESET}"
        git clone https://github.com/roxsross/$REPO.git
        cd $REPO
        git pull
        git checkout $BRANCH
        cd ..
        sudo cp -r $REPO/* /var/www/html
        echo -e "${COLOR_VERDE}Repositorio clonando${COLOR_RESET}"
    fi
    
    echo -e "${COLOR_VERDE}Testeando la version de PHP${COLOR_RESET}"
    php -v
    chmod 777 $rutaDirectory
    sudo sed -i "s/DirectoryIndex.*/$nuevo_orden/" "$rutaDirectory"
    sudo systemctl reload apache2
    
    
    sudo mysql -e "SHOW DATABASES LIKE '$bdd';" | grep devopstravel > /dev/null;

    if [ $? -eq 0 ];then
        echo "La Base de datos ya EXISTE"
    else
        echo "Creando la Base de Datos"
        sudo mysql -e "
        CREATE DATABASE devopstravel;
        CREATE USER 'codeuser'@'localhost' IDENTIFIED BY 'codepass';
        GRANT ALL PRIVILEGES ON *.* TO 'codeuser'@'localhost';
        FLUSH PRIVILEGES;"
        sudo mysql < $CARPETA/database/devopstravel.sql
    fi
    pwd
    cd $REPO/$CARPETA
    sudo sed -i 's/""/"codepass";/g' config.php
    if  [ $? -eq 0 ];then 
        echo "Conexion ejecutada"
    else
       echo "No se pudo realizar la conexion"
    fi


    sudo systemctl enable mariadb
    sudo systemctl start mariadb
    sudo systemctl status mariadb 
    cd --
    sudo cp -r $REPO/* /var/www/html

    sudo systemctl reload apache2

    echo -e "${COLOR_AZUL}Stage #2 Finalizado${COLOR_RESET}"
fi
