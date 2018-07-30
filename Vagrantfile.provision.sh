#filename: Vagrantfile.provision.sh
#!/usr/bin/env bash

# ---------------------------------------------------------------------------------------------------------------------
# Variables & Functions
# ---------------------------------------------------------------------------------------------------------------------
APP_DATABASE_NAME='database'

echoTitle () {
    echo -e "\033[0;30m\033[42m -- $1 -- \033[0m"
}

# ---------------------------------------------------------------------------------------------------------------------
echoTitle 'Virtual Machine Setup Ubuntu 14.04'
# ---------------------------------------------------------------------------------------------------------------------
# Update packages
apt-get update -qq
apt-get -y install git curl vim

# ---------------------------------------------------------------------------------------------------------------------
echoTitle 'Installing and Setting: Apache'
# ---------------------------------------------------------------------------------------------------------------------
# Install packages
apt-get install -y apache2 libapache2-mod-fastcgi apache2-mpm-worker

# Add ServerName to httpd.conf
echo "ServerName localhost" > /etc/apache2/httpd.conf

# Setup hosts file
VHOST=$(cat <<EOF
    <VirtualHost *:80>
      DocumentRoot "/var/www"
      ServerName app.dev
      ServerAlias app.dev
      <Directory "/var/www">
        AllowOverride All
        Require all granted
      </Directory>
    </VirtualHost>
EOF
)
echo "${VHOST}" > /etc/apache2/sites-enabled/000-default.conf

# Loading needed modules to make apache work
a2enmod actions fastcgi rewrite
sudo service apache2 restart

# ---------------------------------------------------------------------------------------------------------------------
# echoTitle 'MYSQL-Database'
# ---------------------------------------------------------------------------------------------------------------------
# Setting MySQL (username: root) ~ (password: password)
sudo debconf-set-selections <<< 'mysql-server-5.6 mysql-server/root_password password password'
sudo debconf-set-selections <<< 'mysql-server-5.6 mysql-server/root_password_again password password'

# Installing packages
apt-get install -y mysql-server-5.6 mysql-client-5.6 mysql-common-5.6

# Setup database
mysql -uroot -ppassword -e "CREATE DATABASE IF NOT EXISTS $APP_DATABASE_NAME;";
mysql -uroot -ppassword -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'password';"
mysql -uroot -ppassword -e "GRANT ALL PRIVILEGES ON *.* TO 'database'@'%' IDENTIFIED BY 'password';"

sudo service mysql restart

# Import SQL file
mysql -uroot -ppassword $APP_DATABASE_NAME < /vagrant/db/database.sql

# ---------------------------------------------------------------------------------------------------------------------
echoTitle 'Installing: PHP'
# ---------------------------------------------------------------------------------------------------------------------
# Remove PHP5
sudo apt-get remove php5-common -y
apt-get purge php5-fpm -y
apt-get --purge autoremove -y

# Install packages
sudo apt-get install -y php5-fpm php5-mysql php5 libapache2-mod-php5
sudo apt-get install -y php5-cli php5-common php5-mbstring php5-gd php5-intl php5-xml php5-mysql php5-mcrypt php5-zip

# ---------------------------------------------------------------------------------------------------------------------
echoTitle 'Setting: PHP with Apache'
# ---------------------------------------------------------------------------------------------------------------------
apt-get install -y libapache2-mod-php

# Trigger changes in apache
a2enconf php-fpm
sudo service apache2 reload

# ---------------------------------------------------------------------------------------------------------------------
# Others
# ---------------------------------------------------------------------------------------------------------------------
# Output success message
echoTitle "Your machine has been provisioned"
echo "-------------------------------------------"
echo "MySQL is available on port 3306 with username 'root' and password 'password'"
echo "(you have to use 127.0.0.1 as opposed to 'localhost')"
echo "Apache is available on port 80"
echo -e "Head over to http://192.168.33.101 to get started"