#!/bin/bash


if [[ `cat /etc/issue.net` != 'Debian GNU/Linux 12' ]]
then
  echo -e "\nThis script requires Debian GNU/Linux 10.\nThis issue is: "
  echo -e `cat /etc/issue.net`
  echo -e "\nStoped.\n"
  exit
fi

if [ "$EUID" -ne 0 ]
  then echo -e "\nThis script requires root privileges.\n\nStoped.\n"
  exit
fi

clear

echo "Web Site Building 2.0

#################################################################################

   Dear friends!

   This script is going to install a set of free software for making it
   easier to hold seminars on web site buildings and internet technologies.
   It's a deeply managable hosting for any large number of students.

   This script allows to choose platform (Apache2, Nginx)

   It helps to create and manage students accounts and its groups. These
   accounts have everything for traing in web: personal directory for
   html files, wordpress downloaded and ready to be installed, ssh and ftp
   access etc.

   All manipulations could be done both in command line and web interfaces.

#################################################################################
"

read  -n 1 -s -p "Please press any key to continue or ctrl-c for abort..."

clear

echo "Firstly, we have to ask you 7 questions:
"

echo "1.
Firstly you have to choose a webserver:
1. Nginx
2. Apache2
"
until [[ $webserver == '1' || $webserver == '2' ]]

do
  read -p "Choose a webserver ([1]/2): " webserver
  webserver=${webserver:-1}
  echo
done



echo "2.
Please choose username for a main user or lecturer or teacher:
"
userexists=1

until [[ $userexists == 0 ]]
do
  read -p "Choose a main user name ([teacher]): " curuser
  curuser=${curuser:-teacher}
  echo
  userexists=`grep -c "^$curuser:" /etc/passwd`
  if [[ $userexists -eq  1 ]]
  then
    echo "Name exists. You have to choose another one."
  fi
  echo
done

echo "3."
domain=''
until [[ $domain != '' ]]
do
  read -p "Enter base your server's domain (ya.ru, for example): " domain

  if [[ $domain == '' ]]
  then
    echo "Domain name should not be an empty string.
You have to enter something existing."
  fi
  echo $domain
done

until [[ $passwd_ok == 'ok' && $dbrootpassword != '' ]]

do

	echo -ne "\n4.\nEnter the root password for databases: "

	while IFS= read -p "$prompt" -r -s -n 1 char

	do
    	# Enter - accept password
    	if [[ $char == $'\0' ]] ; then
        	break
    	fi
    	# Backspace
    	if [[ $char == $'\177' ]] ; then
        	prompt=$'\b \b'
        	dbrootpassword="${dbrootpassword%?}"
    	else
        	prompt='*'
        	dbrootpassword+="$char"
    	fi
	done

	prompt=''

	echo -ne "\nEnter the password once again: "

	while IFS= read -p "$prompt" -r -s -n 1 char

	do
    	# Enter - accept password
    	if [[ $char == $'\0' ]] ; then
        	break
    	fi
    	# Backspace
    	if [[ $char == $'\177' ]] ; then
        	prompt=$'\b \b'
        	dbrootpassword1="${dbrootpassword1%?}"
    	else
        	prompt='*'
        	dbrootpassword1+="$char"
    	fi
	done

	if [[ $dbrootpassword == $dbrootpassword1 && $dbrootpassword != '' ]] ; then

    	echo -e "\nThe password successfully set"

    	passwd_ok="ok"

	elif [[ $dbrootpassword == '' ]] ; then

    	echo -e "\nThe password can not be empty"

    	passwd_ok='ok'

    	prompt=''

	else

    	echo -e "\nThe passwords do not match. Try again"

    	ok=''

    	prompt=''

    	dbrootpassword=''

    	dbrootpassword1=''

	fi

done


passwd_ok=''
prompt=''

until [[ $passwd_ok == 'ok' && $dbuserpassword != '' ]]

do

	echo -ne "\n5.\nEnter a common password for user's databases: "

	while IFS= read -p "$prompt" -r -s -n 1 char

	do
    	# Enter - accept password
    	if [[ $char == $'\0' ]] ; then
        	break
    	fi
    	# Backspace
    	if [[ $char == $'\177' ]] ; then
        	prompt=$'\b \b'
        	dbuserpassword="${dbuserpassword%?}"
    	else
        	prompt='*'
        	dbuserpassword+="$char"
    	fi
	done

	prompt=''

	echo -ne "\nEnter user's password once again: "

	while IFS= read -p "$prompt" -r -s -n 1 char

	do
    	# Enter - accept password
    	if [[ $char == $'\0' ]] ; then
        	break
    	fi
    	# Backspace
    	if [[ $char == $'\177' ]] ; then
        	prompt=$'\b \b'
        	dbuserpassword1="${dbuserpassword1%?}"
    	else
        	prompt='*'
        	dbuserpassword1+="$char"
    	fi
	done

	if [[ $dbuserpassword == $dbuserpassword1 && $dbuserpassword != '' ]] ; then

    	echo -e "\nThe user's password successfully set"

    	passwd_ok="ok"

	elif [[ $dbuserpassword == '' ]] ; then

    	echo -e "\nThe password can not be empty"

    	passwd_ok='ok'

    	prompt=''

	else

    	echo -e "\nThe passwords do not match. Try again"

    	ok=''

    	prompt=''

    	dbuserpassword=''

    	dbuserpassword1=''

	fi

done

apt-get -qq -y install locales

localedef -i ru_RU -f UTF-8 ru_RU.UTF-8

export LC_ALL="ru_RU.UTF-8"

clear

echo "So... the configuration we have:"

echo -e "\nThe main user at the project:\t\t\t$curuser"

echo -e "\nThe site address for the project:\t\thttps://$domain"

echo -e "\nThe site address for the $curuser:\t\t\thttps://$curuser.$domain"

echo -e "\nOther sites are on\t\t\t\thttps://<username>.$domain"

echo

read  -n 1 -s -p "Please press any key to continue or ctrl-c for abort..."

clear



new_wordpress_url="https://ru.wordpress.org/latest-ru_RU.zip"

curhom=`echo $HOME | sed -e 's/\//\\\\\//g'`



######################################################################

#                          EXECUTING BLOCK

######################################################################

echo -e "ADDING NEW MAIN USER $curuser\n"

adduser --quiet --gecos "" $curuser

usermod -a -G sudo $curuser

echo -e "\nUSER $curuser IS ADDED AND PROVIDED WITH SUDO PRIVILEGES\n\n"

echo -e "STARTING SOFTWARE PACKAGES INSTALLATION. IT TAKES SOME TIME...\n"

cd

curuser_home=`eval echo ~$curuser`

mkdir -p $curuser_home/.wsb2

mkdir -p $curuser_home/.log

mkdir -p $curuser_home/.wsb2/bin

mkdir -p $curuser_home/.wsb2/src

mkdir -p $curuser_home/.wsb2/www

chown -R  $curuser:www-data $curuser_home/.wsb2

chown -R  $curuser:www-data $curuser_home/.log

chmod -R 750 $curuser_home/.wsb2

chmod -R 750 $curuser_home/.log

chmod 640 $curuser_home/.wsb2/www/

chmod 700 $curuser_home/.wsb2/bin

apt-get -qq -y update

apt-get -qq -y upgrade

###  MAIN PACKAGES INSTALLATION



apt-get -qq -y install sudo ssh

apt-get -qq -y install mc lynx man proftpd htop zip unzip bash-completion whois

apt-get -qq -y install php-gd php-mysql php-curl php-json php-mbstring php-xml php-opcache


case $webserver in
  1)
    echo "Nginx + Apache2"

    apt-get -y -qq install nginx php-fpm

    php_version=`php -i | grep "Loaded Configuration File" | awk -F "=>" '{print $2}' | awk -F "/" '{print $4}'`

    php_path=`php -i | grep "Loaded Configuration File" | awk -F "=>" '{print $2}'`

    php_path=`echo "${php_path/cli/fpm}"`

    cp  $php_path{,.bak}

    sh -c "sed -e 's/upload_max_filesize = 2M/upload_max_filesize = 50M/' $php_path > $php_path.new"

    mv $php_path{.new,}



    rm -f /etc/nginx/sites-available/default

    rm -f /etc/nginx/sites-enabled/default

    echo "server {
	listen 80 default_server;
	listen [::]:80 default_server;

	root /var/www/html;

	index index.php index.html index.htm;

	server_name _;

	location ~ \.php$ {
		include fastcgi.conf;
		try_files \$uri \$uri/ =404;
    fastcgi_pass unix:/var/run/php/php7.3-fpm.sock;
	}

  error_log $curuser_home/.log/$domain-error.log;
  access_log $curuser_home/.log/$domain-access.log;

}" > /etc/nginx/sites-available/default

echo "server {
listen 80;
listen [::]:80;

root $curuser_home/.wsb2/www/;

index index.php index.html index.htm;

server_name $curuser.$domain;

location ~ \.php$ {
include fastcgi.conf;
try_files \$uri \$uri/ =404;
fastcgi_pass unix:/var/run/php/php7.3-fpm.sock;
}

error_log $curuser_home/.log/$curuser-error.log;
access_log $curuser_home/.log/$curuser-access.log;

}" > /etc/nginx/sites-available/$curuser.conf

    ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/
    ln -s /etc/nginx/sites-available/$curuser.conf /etc/nginx/sites-enabled/

    systemctl restart nginx

    systemctl start php$php_version-fpm

    ;;
  2)
    echo "Apache2"
    apt-get -qq -y install apache2 libapache2-mod-php

    php_version=`php -i | grep "Loaded Configuration File" | awk -F "=>" '{print $2}' | awk -F "/" '{print $4}'`


    cp /etc/apache2/conf-available/charset.conf{,.bak}

    sh -c "sed -e 's/#AddDefaultCharset UTF-8/AddDefaultCharset UTF-8/' /etc/apache2/conf-available/charset.conf > /etc/apache2/conf-available/charset.conf.new"

    mv /etc/apache2/conf-available/charset.conf{.new,}

    cp /etc/apache2/sites-available/000-default.conf{,.bak}

    sh -c "sed -e 's/VirtualHost \*:80/VirtualHost $domain:80/' /etc/apache2/sites-available/000-default.conf > /etc/apache2/sites-available/000-default.conf.new"

    mv /etc/apache2/sites-available/000-default.conf{.new,}

    echo "<VirtualHost $domain:80>

    DocumentRoot /var/www/html

    <Directory /var/www/html>
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
    </Directory>
    ErrorLog $curuser_home/.log/$domain-error.log
        CustomLog $curuser_home/.log/$domain-access.log combined
    </VirtualHost>
    " > /etc/apache2/sites-available/000-default.conf

    a2enmod proxy_fcgi setenvif rewrite


    a2enmod php$php_version

    echo "<VirtualHost $curuser.$domain:80>

    DocumentRoot /home/$curuser/.wsb2/www

    <Directory /home/$curuser/.wsb2/www>
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
    </Directory>
    ErrorLog $curuser_home/.log/$curuser-error.log
        CustomLog $curuser_home/.log/$curuser-access.log combined
    </VirtualHost>
    " > /etc/apache2/sites-available/$curuser.conf

    a2ensite $curuser

    systemctl reload apache2
    ;;
esac

echo -e "<?php\nphpinfo();\n?>\n" > /var/www/html/phpinfo.php

echo -e "<h1>DEFAULT SITE</h1>" > /var/www/html/index.php

echo -e "<?php\nphpinfo();\n?>\n" > $curuser_home/.wsb2/www/phpinfo.php

echo -e "<h1>$curuser'S SITE</h1>" > $curuser_home/.wsb2/www/index.php

apt-get -qq -y install mariadb-client mariadb-server

apt-get -qq -y install  memcached php-memcache

cd $curuser_home/.wsb2/

wget $new_wordpress_url

unzip latest-ru_RU.zip

rm -f latest-ru_RU.zip

wget -P $curuser_home/.wsb2/bin/ https://raw.githubusercontent.com/koo2018/websitebuilding2/master/wsb2-newstudent.sh

wget -P $curuser_home/.wsb2/bin/ https://raw.githubusercontent.com/koo2018/websitebuilding2/master/wsb2-delstudent.sh

wget -P $curuser_home/.wsb2/bin/ https://raw.githubusercontent.com/koo2018/websitebuilding2/master/wsb2-tarbkp.sh

wget -P $curuser_home/.wbs2/bin/ https://raw.githubusercontent.com/koo2018/websitebuilding2/master/wsb2-zipbkp.sh

chown -R $curuser:$curuser $curuser_home/.wsb2/bin/*

chmod u+x $curuser_home/.wsb2/bin/*

echo -e "\nPATH=\$PATH:$curuser_home/.wsb2/bin\n" >> $curuser_home/.bashrc

echo -e "\nexport LC_ALL="ru_RU.UTF-8"\n" >> $curuser_home/.bashrc

echo "Настраиваем скрипт newstudent"

cd $curuser_home/.wsb2/bin

sh -c "sed -e 's/hname=\"\"/hname=\"$domain\"/' wsb2-newstudent.sh > wsb2-newstudent.new"

echo `pwd`

mv wsb2-newstudent{.new,.sh}

sh -c "sed -e 's/rootdbpasswd=\"\"/rootdbpasswd=\"$dbrootpassword\"/' wsb2-newstudent.sh > wsb2-newstudent.new"

mv wsb2-newstudent{.new,.sh}

sh -c "sed -e 's/dbpasswd=\"\"/dbpasswd=\"$dbuserpassword\"/' wsb2-newstudent.sh > wsb2-newstudent.new"

mv wsb2-newstudent{.new,.sh}

sh -c "sed -e 's/webserver=\"\"/webserver=\"$webserver\"/' wsb2-newstudent.sh > wsb2-newstudent.new"

mv wsb2-newstudent{.new,.sh}

echo "Настраиваем скрипт delstudent"

sh -c "sed -e 's/rootdbpasswd=\"\"/rootdbpasswd=\"$dbrootpassword\"/' wsb2-delstudent.sh > wsb2-delstudent.new"

mv wsb2-delstudent{.new,.sh}

echo "Настраиваем скрипт tarbkp"

sh -c "sed -e 's/TEACHER_NAME=\"\"/TEACHER_NAME=\"$curuser\"/' tarbkp > tarbkp.new"

mv tarbkp{.new,}

sh -c "sed -e 's/BACKUPS_DIR=\"\"/BACKUPS_DIR=\"$curhom\/backups\"/' tarbkp > tarbkp.new"

mv tarbkp{.new,}

sh -c "sed -e 's/root -p1234/root -p$dbrootpassword/' tarbkp > tarbkp.new"

mv tarbkp{.new,}


chown $curuser:$curuser tarbkp

chmod 700 ./tarbkp

echo "Настраиваем скрипт zipbkp"

sh -c "sed -e 's/TEACHER_NAME=\"\"/TEACHER_NAME=\"$curuser\"/' zipbkp > zipbkp.new"

mv zipbkp{.new,}

sh -c "sed -e 's/BACKUPS_DIR=\"\"/BACKUPS_DIR=\"$curhom\/backups\"/' zipbkp > zipbkp.new"

mv zipbkp{.new,}

sh -c "sed -e 's/root -p1234/root -p$dbrootpassword/' zipbkp > zipbkp.new"

mv zipbkp{.new,}

chown $curuser:$curuser *

chmod 700 *

echo -e "\ny\n$dbrootpassword\n$dbrootpassword\ny\ny\ny\ny" | /usr/bin/mysql_secure_installation

echo -e "use mysql; update user set plugin='' where User='root'; flush privileges;" | sudo mysql -uroot -p$dbrootpassword

systemctl restart mysql.service

#cp /etc/ssh/sshd_config{,.bak}

#sh -c "sed -e 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config > /etc/ssh/sshd_config.new"

#mv /etc/ssh/sshd_config{.new,}

cp  /etc/mysql/mariadb.conf.d/50-server.cnf{,.bak}

sh -c "sed -e 's/#max_connections/max_connections/' /etc/mysql/mariadb.conf.d/50-server.cnf > /etc/mysql/mariadb.conf.d/50-server.cnf.new"

mv /etc/mysql/mariadb.conf.d/50-server.cnf{.new,}

sh -c "sed -e 's/max_connections        = 100/max_connections        = 200/' /etc/mysql/mariadb.conf.d/50-server.cnf > /etc/mysql/mariadb.conf.d/50-server.cnf.new"

mv /etc/mysql/mariadb.conf.d/50-server.cnf{.new,}

cd $curuser_home

echo -e ' # Generated by NOT /usr/bin/select-editor\nSELECTED_EDITOR="/usr/bin/mcedit"' > .selected_editor

echo -e '\n\n EVERYTHING IS DONE. REBOOTING . . . \n\n DO NOT FOREGET TO DROP IN AGAIN \n\n JUST TYPE TWO EXCLAMATION MARKS\n\n !!\n\n'
