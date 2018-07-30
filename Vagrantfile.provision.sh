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
echoTitle 'Virtual Machine Setup Ubuntu 14.04 LTS'
# ---------------------------------------------------------------------------------------------------------------------
# Update packages
apt-get update -qq
apt-get -y install git curl vim

# ---------------------------------------------------------------------------------------------------------------------
echoTitle 'Installing and Setting: Apache'
# ---------------------------------------------------------------------------------------------------------------------
# Install packages
apt-get install -y apache2 libapache2-mod-fastcgi apache2-mpm-worker

# Add ServerName to apache2.conf and delete tag of default document root
sudo sed -i -e "70i\ServerName localhost" /etc/apache2/apache2.conf
sudo sed -i -e "/<Directory \/var\/www\//,/\/Directory>/d" /etc/apache2/apache2.conf

# Setup hosts file
VHOST=$(cat <<EOF
<VirtualHost *:80>
    DocumentRoot "/var/www"
    ServerName localhost
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

# Install packages(first adding repository)
sudo add-apt-repository -y ppa:ondrej/apache2
sudo add-apt-repository -y ppa:ondrej/php
sudo apt-get update
sudo apt-get upgrade

sudo apt-get install php5.6  
sudo apt-get -y install php5.6 php5.6-cgi libapache2-mod-php5.6 php5.6-common php-pear

# ---------------------------------------------------------------------------------------------------------------------
echoTitle 'Setting: PHP with Apache'
# ---------------------------------------------------------------------------------------------------------------------
# Trigger changes in apache
sudo a2enconf php5.6-cgi.conf
sudo a2enconf php-fpm
sudo service apache2 restart

# ---------------------------------------------------------------------------------------------------------------------
# Others
# ---------------------------------------------------------------------------------------------------------------------
# Output success message
echoTitle "Your machine has been provisioned"
echo "-------------------------------------------"
echo "MySQL is available on port 3306 with username 'root' and password 'password'"
echo "Apache is available on port 80"
echo -e "Head over to http://192.168.33.101 to get started"