#!/bin/bash


hname=""

rootdbpasswd=""

dbpasswd=""

webserver=""


if [ "$hname" = "" ]; then
echo -e "Missing domain name. Check \$hname. \n"
stop_var=1
fi

if [ "$rootdbpasswd" = "" ]; then
echo -e "Missing database administrator passwd. Check \$rootdbpasswd. \n"
stop_var=1
fi

if [ "$dbpasswd" = "" ]; then
echo -e "Missing database user passwd. Check \$dbpasswd. \n"
stop_var=1
fi

if [ "$webserver" = "" ]; then
echo -e "Missing webserver specification. Check \$dbpasswd. \n"
stop_var=1
fi

if [ $# -ne 2 ]; then
echo -e 'Two parameters are required to start\n
 \n
./newstudent groupName studentName \n'
stop_var=1
fi

if [ $stop_var ]; then
echo -e "The script is stopped \n"
exit
fi

group_home="/home/$1"
www="/home/$1/$2/www"
wordpress="/home/$1/$2/www/wordpress"

sudo -v

grp=`grep "^$1:" /etc/group`
if [[ $grp == '' ]]; then
echo 'Creating group '$2
sudo addgroup $1
else
echo 'The group '$1' exists'
fi
echo ''

echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
echo "*"
echo "*  Creating student " $2 " in group "$1
echo "*"
echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
echo ""

if ! [ -d $group_home ]; then
echo 'Creating directory '$group_home
sudo mkdir $group_home
else
echo 'Group directory '$1' exists'
fi
echo ''

usr=`grep "^$2:" /etc/passwd`
if [[ $usr == '' ]]; then
echo 'Creating user '$2
sudo useradd -b /home/$1 -g $1 -m -s /bin/bash $2
else
echo 'The user '$2' exists'
exit
fi
echo ''

if ! [ -d $www ]; then
echo 'Creating directory '$www
sudo mkdir $www
else
echo 'Directory '$www' exists'
fi
echo ''

if ! [ -d $wordpress ]; then
echo 'Creating directory '$wordpress
sudo mkdir /home/$1/$2/www/wordpress
else
echo 'Directory '$wordpress' exists'
fi
echo ''

echo "Setting owners for the directory "$www" - "$2":"$1
sudo chown $2:$1 $www
echo ''

echo "Setting owners for the directory "$wordpress" - "$2":"$1
sudo chown $2:$1 $wordpress
echo ''

echo -e "Setting passwd for "$2"\n"

echo -e "$dbpasswd\n$dbpasswd\n" | sudo passwd $2

echo -n "Coping WordPress directory...  "

sudo cp -r /home/teacher/.wsb2/wordpress/* /home/$1/$2/www/wordpress

echo -e "Successfully done\n"



sudo find /home/$1/$2/www -type d -exec chmod 755 {} \;

sudo find /home/$1/$2/www -type f -exec chmod 644 {} \;

sudo chmod 775 /home/$1/$2/www/wordpress

sudo chown $2:www-data -R /home/$1/$2/www/wordpress

sudo mkdir /home/$1/$2/www/wordpress/wp-content/uploads

sudo chown $2:www-data /home/$1/$2/www/wordpress/wp-content/uploads -R

sudo chmod g+w /home/$1/$2/www/wordpress/wp-content/uploads -R

echo -n "Creating MySQL user and its database...  "
mysql -u root -p$rootdbpasswd <<EOF
CREATE USER $2@'localhost' IDENTIFIED BY '$dbpasswd';
create database $2;
grant usage on *.* to $2@localhost identified by '$dbpasswd';
grant all privileges on $2.* to $2@localhost;
FLUSH PRIVILEGES;
EOF
echo "Completed"
echo ""

sudo mkdir /home/$1/$2/.log

sudo chown $2:www-data /home/$1/$2/.log

sudo chmod g+w /home/$1/$2/.log

sudo sh -c "echo \"<?php phpinfo(); ?>\" > /home/$1/$2/www/phpinfo.php"

sudo sh -c "echo  \"
define('FS_CHMOD_FILE', 0755);
define('FS_CHMOD_DIR', 0755);
define('FS_METHOD', 'ftpext');
define('FTP_BASE', '/home/$1/$2/www/wordpress/');
define('FTP_CONTENT_DIR', '/home/$1/$2/www/wordpress/wp-content/');
define('FTP_PLUGIN_DIR ', '/home/$1/$2/www/wordpress/wp-content/plugins/');
define('FTP_USER', '$2');
define('FTP_PASS', '$dbpasswd');
define('FTP_HOST', '$hname:21');
define('FTP_SSL', false); \" >> /home/$1/$2/www/wordpress/wp-config.php
"


case $webserver in
      1)

      sudo sh -c "echo \"server {
        listen 80;
        listen [::]:80;

        root /home/$1/$2/www/;

        index index.php index.html index.htm;

        server_name $2.$hname;

        location ~* ^.+.(xml|ogg|ogv|svg|svgz|eot|otf|woff|mp4|ttf|css|rss|atom|js|jpg|jpeg|gif|png|ico|zip|tgz|gz|rar|bz2|doc|xls|exe|ppt|tar|mid|midi|wav|bmp|rtf)$ {
          expires max;
        }

        location = /favicon.ico {
          log_not_found off;
          access_log off;
        }

        location = /robots.txt {
          allow all;
          log_not_found off;
          access_log off;
        }

        location ~ \.php$ {
          include fastcgi.conf;
          try_files \\\$uri \\\$uri/ =404;
          fastcgi_index index.php;
          fastcgi_pass unix:/var/run/php/php7.3-fpm.sock;
        }

        location / {
          try_files \\\$uri \\\$uri/ /wordpress/index.php?q=\\\$uri\\\$args;
        }

        rewrite /wp-admin\$ \\\$scheme://\\\$host\\\$uri/ permanent;

        error_log /home/$1/$2/.log/error.log;
        access_log /home/$1/$2/.log/access.log;

    }\" > /etc/nginx/sites-available/$2.conf"

      sudo ln -s /etc/nginx/sites-available/$2.conf /etc/nginx/sites-enabled/

      sudo systemctl restart nginx
      ;;

      2)

      apache_vhosts="/etc/apache2/sites-available"




      echo -e "\nFile for Apache2\n"
      echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
      echo ""

      sudo echo "<VirtualHost $2.$hname:80>

      DocumentRoot /home/$1/$2/www

      <Directory /home/$1/$2/www>
              Options Indexes FollowSymLinks
              AllowOverride All
              Require all granted
      </Directory>
      ErrorLog ${APACHE_LOG_DIR}/error.log
          CustomLog ${APACHE_LOG_DIR}/access.log combined
      </VirtualHost>
      " | sudo tee $apache_vhosts/$2.conf

      echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
      echo ""



      echo -n "Turning on the site "$1" on apache2 server...  "
      sudo a2ensite -q $2
      echo ''

      echo -n "Restarting apache2...  "
      sudo systemctl reload apache2
      echo "Completed"
      echo ""


;;

esac

echo "Creating user account for "$2" completed!"
echo -e "\n"
