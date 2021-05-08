#!/bin/bash

#####
# Здесь можно менять параметры (пробелы вокруг знака равно будут ошибкой)
#

# ваш домен
hname="bmd2019.ru"

# пароль администратора базы данных. Мы его задавали, когда устнанавливали MariaDB/MySQL
rootdbpasswd="koo1975"

# пароль, который мы установим студентам на доступ к базе данных.
# Его надо сейчас придуамть, запомнить и сообщить студентам, когда они будут установливать WordPRess
dbpasswd="1234"

webserver="1"

# Дальше править не нужно, если вы не понимаете, что делаете



if [ "$hname" = "" ]; then
echo -e "Не указано доменное имя в переменной \$hname. \n"
stop_var=1
fi

if [ "$rootdbpasswd" = "" ]; then
echo -e "Не указан пароль администратора базы данных \$rootdbpasswd. \n"
stop_var=1
fi

if [ "$dbpasswd" = "" ]; then
echo -e "Не указан пароль пользователя базы данных \$dbpasswd. \n"
stop_var=1
fi

if [ $# -ne 2 ]; then
echo -e 'Для работы программы требуется два параметра\n
Формат команды \n
./newstudent groupName studentName \n'
stop_var=1
fi

if [ $stop_var ]; then
echo -e "Скрипт остановлен \n"
exit
fi

group_home="/home/$1"
www="/home/$1/$2/www"
wordpress="/home/$1/$2/www/wordpress"

sudo -v

grp=`grep "^$1:" /etc/group`
if [[ $grp == '' ]]; then
echo 'Создаем группу '$2
sudo addgroup $1
else
echo 'Группа '$1' уже существует'
fi
echo ''

echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
echo "*"
echo "*  Создаем студента " $2 " в группе "$1
echo "*"
echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
echo ""

if ! [ -d $group_home ]; then
echo 'Создаем директорию '$group_home
sudo mkdir $group_home
else
echo 'Директория группы '$1' уже создана'
fi
echo ''

usr=`grep "^$2:" /etc/passwd`
if [[ $usr == '' ]]; then
echo 'Создаем пользователя '$2
sudo useradd -b /home/$1 -g $1 -m -s /bin/bash $2
else
echo 'Пользователь '$2' уже существует'
exit
fi
echo ''

if ! [ -d $www ]; then
echo 'Создаем директорию '$www
sudo mkdir $www
else
echo 'Директория '$www' существует'
fi
echo ''

if ! [ -d $wordpress ]; then
echo 'Создаем директорию '$wordpress
sudo mkdir /home/$1/$2/www/wordpress
else
echo 'Директория '$wordpress' существует'
fi
echo ''

echo "Устанавливаем владельцев директории "$www" - "$2":"$1
sudo chown $2:$1 $www
echo ''

echo "Устанавливаем владельцев директории "$wordpress" - "$2":"$1
sudo chown $2:$1 $wordpress
echo ''

echo -e "Устанавливаем пароль для "$2"\n"

echo -e "$dbpasswd\n$dbpasswd\n" | sudo passwd $2

echo -n "Копируем папку WordPress...  "

sudo cp -r /home/teacher/.wsb2/wordpress/* /home/$1/$2/www/wordpress

echo -e "Завершили\n"



sudo find /home/$1/$2/www -type d -exec chmod 755 {} \;

sudo find /home/$1/$2/www -type f -exec chmod 644 {} \;

sudo chmod 775 /home/$1/$2/www/wordpress

sudo chown $2:www-data -R /home/$1/$2/www/wordpress

sudo mkdir /home/$1/$2/www/wordpress/wp-content/uploads

sudo chown $2:www-data /home/$1/$2/www/wordpress/wp-content/uploads -R

sudo chmod g+w /home/$1/$2/www/wordpress/wp-content/uploads -R

echo -n "Создание пользователя MySQL и базы данных...  "
mysql -u root -p$rootdbpasswd <<EOF
CREATE USER $2@'localhost' IDENTIFIED BY '$dbpasswd';
create database $2;
grant usage on *.* to $2@localhost identified by '$dbpasswd';
grant all privileges on $2.* to $2@localhost;
FLUSH PRIVILEGES;
EOF
echo "Завершено"
echo ""

sudo mkdir /home/$1/$2/.log

sudo chown $2:www-data /home/$1/$2/.log

sudo chmod g+w /home/$1/$2/.log


case $webserver in
      1)

      sudo sh -c "echo \"server {
      listen 80;
      listen [::]:80;

      root /home/$1/$2/www/;

      index index.php index.html index.htm;

      server_name $2.$hname;

      location ~ \.php$ {
      include fastcgi.conf;
      try_files \\\$uri \\\$uri/ =404;
      fastcgi_index index.php;
      fastcgi_pass unix:/var/run/php/php7.3-fpm.sock;

      }

      location / {
try_files \\\$uri \\\$uri/ /wordpress/index.php?q=\\\$uri\\\$args;
}

error_log /home/$1/$2/.log/error.log;
access_log /home/$1/$2/.log/access.log;

    }\" > /etc/nginx/sites-available/$2.conf"

      sudo ln -s /etc/nginx/sites-available/$2.conf /etc/nginx/sites-enabled/

      sudo systemctl restart nginx
      ;;

      2)

      apache_vhosts="/etc/apache2/sites-available"




      echo -e "\nФАЙЛ ДЛЯ АПАЧА\n"
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



      echo -n "Включение сайта "$1" на сервере apache2...  "
      sudo a2ensite -q $2
      echo ''

      echo -n "Перезапуск apache2...  "
      sudo systemctl reload apache2
      echo "Завершено"
      echo ""




;;

esac

echo "Создание аккаунта пользователя "$2" завершено!"
echo -e "\n"
