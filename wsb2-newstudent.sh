#!/bin/bash


hname=""

rootdbpasswd=""

dbpasswd=""

webserver=""

phpver=""


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
echo -e "Missing webserver specification. Check \$webserver. \n"
stop_var=1
fi

if [ $# -ne 2 ]; then
echo -e 'Two parameters are required to start\n
 \n
./newstudent groupName studentName \n'
stop_var=1
fi

if [ "$stop_var" = "1" ]; then
echo -e "The script is stopped \n"
exit
fi

STUDENT="$2"
GROUP="$1"
CREATED_USER=0
CREATED_DB=0
CREATED_VHOST=0

rollback() {
    echo -e "\nПроизошла ошибка. Выполняем откат изменений...\n"
    if [ "$CREATED_VHOST" = "1" ]; then
        case $webserver in
            1) sudo rm -f /etc/nginx/sites-available/$STUDENT.conf
               sudo rm -f /etc/nginx/sites-enabled/$STUDENT.conf
               sudo systemctl reload nginx 2>/dev/null ;;
            2) sudo a2dissite -q $STUDENT 2>/dev/null
               sudo rm -f /etc/apache2/sites-available/$STUDENT.conf
               sudo systemctl reload apache2 2>/dev/null ;;
        esac
    fi
    if [ "$CREATED_DB" = "1" ]; then
        sudo mysql -u root -p$rootdbpasswd -e "DROP DATABASE IF EXISTS $STUDENT; DROP USER IF EXISTS '$STUDENT'@'localhost'; FLUSH PRIVILEGES;" 2>/dev/null
    fi
    if [ "$CREATED_USER" = "1" ]; then
        sudo deluser --remove-home $STUDENT 2>/dev/null
    fi
}

trap 'EC=$?; [ $EC -ne 0 ] && rollback' EXIT

group_home="/home/$1"
www="/home/$1/$2/www"

sudo -v

grp=`grep "^$1:" /etc/group`
if [[ $grp == '' ]]; then
echo 'Creating group '$1
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
sudo useradd -b /home/$1 -g $1 -m -s /bin/bash $2 || exit 1
CREATED_USER=1
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

echo "Setting owners for the directory "$www" - "$2":"$1
sudo chown $2:$1 $www
echo ''

echo -e "Setting passwd for "$2"\n"

echo -e "$dbpasswd\n$dbpasswd\n" | sudo passwd $2

echo -n "Coping WordPress directory...  "

sudo cp -r /home/teacher/.wsb2/wordpress/* /home/$1/$2/www/ || exit 1

echo -e "Successfully done\n"



sudo chmod 711 /home/$1/$2

sudo find /home/$1/$2/www -type d -exec chmod 755 {} \;

sudo find /home/$1/$2/www -type f -exec chmod 644 {} \;

sudo chown $2:www-data -R /home/$1/$2/www

sudo mkdir -p /home/$1/$2/www/wp-content/uploads

sudo chown $2:www-data /home/$1/$2/www/wp-content/uploads -R

sudo chmod g+w /home/$1/$2/www/wp-content/uploads -R


sudo mkdir -p /home/$1/$2/www/wp-content/upgrade

sudo chown $2:www-data /home/$1/$2/www/wp-content/upgrade -R

sudo chmod g+w /home/$1/$2/www/wp-content/upgrade -R


echo -n "Creating MySQL user and its database...  "
sudo mysql -u root -p$rootdbpasswd <<EOF || exit 1
CREATE USER $2@'localhost' IDENTIFIED BY '$dbpasswd';
create database $2;
grant usage on *.* to $2@localhost identified by '$dbpasswd';
grant all privileges on $2.* to $2@localhost;
FLUSH PRIVILEGES;
EOF
CREATED_DB=1
echo "Completed"
echo ""

sudo mkdir /home/$1/$2/.log

sudo chown $2:www-data /home/$1/$2/.log

sudo chmod g+w /home/$1/$2/.log

sudo sh -c "echo \"<?php phpinfo(); ?>\" > /home/$1/$2/www/phpinfo.php"



echo "
if grep \"FTP_\" ../wp-config.php >/dev/null; then
echo \"<yes>\"
else
echo \"<no>\"

echo \"
define('FS_CHMOD_FILE', 0755);
define('FS_CHMOD_DIR', 0755);
define('FS_METHOD', 'direct');
define('FTP_BASE', '/home/$1/$2/www/');
define('FTP_CONTENT_DIR', '/home/$1/$2/www/wp-content/');
define('FTP_PLUGIN_DIR ', '/home/$1/$2/www/wp-content/plugins/');
define('FTP_USER', '$2');
define('FTP_PASS', '$dbpasswd');
define('FTP_HOST', '$2.$hname:21');
define('FTP_SSL', false);
\" |  tee -a  ../wp-config.php > /dev/null

fi
" |  sudo tee /home/$1/$2/www/wp-admin/add_ftp.sh > /dev/null

# sed -i '1s/^/if (!defined('"'"'FS_METHOD'"'"')) define('"'"'FS_METHOD'"'"', '"'"'direct'"'"');\n/' /home/$1/$2/www/wordpress/wp-admin/wp-config.php



cat /home/$1/$2/www/wp-admin/install.php |
awk '{sub(/<\/body>/,"<?php $output = shell_exec(\"bash add_ftp.sh\"); echo \"<pre>$output</pre>\";?><\/body>" )}1' |
sudo tee /home/$1/$2/www/wp-admin/install.php > /dev/null

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
          fastcgi_pass unix:/var/run/php/php${phpver}-fpm.sock;
        }

        location / {
          try_files \\\$uri \\\$uri/ /index.php?\\\$args;
        }

        rewrite /wp-admin\$ \\\$scheme://\\\$host\\\$uri/ permanent;

        error_log /home/$1/$2/.log/error.log;
        access_log /home/$1/$2/.log/access.log;

    }\" > /etc/nginx/sites-available/$2.conf"

      sudo ln -s /etc/nginx/sites-available/$2.conf /etc/nginx/sites-enabled/

      CREATED_VHOST=1
      sudo systemctl restart nginx || exit 1
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
      CREATED_VHOST=1
      sudo systemctl reload apache2 || exit 1
      echo "Completed"
      echo ""


;;

esac

echo "Creating user account for "$2" completed!"
echo -e "\n"
