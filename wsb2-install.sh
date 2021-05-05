#!/bin/bash


if [[ `cat /etc/issue.net` != 'Debian GNU/Linux 10' ]]
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

   This script allows to choose language (en, ru), platform (Apache2, Nginx)

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
You can choose a languge. English is default language.
If you would like to install your own language pack, now choose English.
en. English
ru. Russian
"

until [[ $language == 'en' || $language == 'ru' ]]

do
  read -p "Choose your language [en],ru: " language
  language=${language:-en}
  echo
done

echo "2.
Now you have to choose a webserver:
1. Nginx + Apache2
2. Apache2
"
until [[ $webserver == '1' || $webserver == '2' ]]

do
  read -p "Choose a webserver ([1]/2): " webserver
  webserver=${webserver:-1}
  echo
done



echo "3.
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
  read -p "Укажите базовый домен вашего сервера, например, ya.ru: " domain

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

php_version=`php -i | grep "Loaded Configuration File" | awk -F "=>" '{print $2}' | awk -F "/" '{print $4}'`




######################################################################

#                          EXECUTING BLOCK

######################################################################

echo -e "ADDING NEW MAIN USER $curuser\n"

adduser --quiet --gecos "" $curuser

usermod -a -G sudo $curuser

echo -e "\nUSER $curuser IS ADDED AND PROVIDED WITH SUDO PRIVILEGES\n\n"

echo -e "STARTING SOFTWARE PACKAGES INSTALLATION. IT TAKES SOME TIME...\n"

cd

mkdir -p `eval echo ~$curuser/.wsb2`

mkdir -p `eval echo ~$curuser/.wsb2/bin`

mkdir -p `eval echo ~$curuser/.wsb2/src`

mkdir -p `eval echo ~$curuser/.wsb2/www/main`

mkdir -p `eval echo ~$curuser/.wsb2/www/teacher`

chown -R  $curuser:$curuser `eval echo ~$curuser/.wsb2`

chmod -R 660 `eval echo ~$curuser/.wsb2`

apt-get -qq -y update

apt-get -qq -y upgrade

###  MAIN PACKAGES INSTALLATION

apt-get -qq -y install locales

localedef -i ru_RU -f UTF-8 ru_RU.UTF-8

apt-get -qq -y install sudo ssh

apt-get -qq -y install mc lynx man proftpd htop zip unzip bash-completion whois

apt-get -qq -y install php-gd php-mysql php-curl php-json php-mbstring php-xml php-opcache

case $webserver in
  1)
    echo "Nginx + Apache2"

    apt-get -y install nginx php-fpm

    echo -e "<?php\nphpinfo();\n?>\n" > /var/www/html/phpinfo.php

    echo -e "<h1>DEFAUT SITE</h1>" > /var/www/html/index.php

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

}" > /etc/nginx/sites-available/default

    ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

    systemctl restart nginx

    systemctl start php$php_version-fpm

    ;;
  2)
    echo "Apache2"
    apt-get -qq -y install apache2 libapache2-mod-php

    cp /etc/apache2/conf-available/charset.conf{,.bak}

    sh -c "sed -e 's/#AddDefaultCharset UTF-8/AddDefaultCharset UTF-8/' /etc/apache2/conf-available/charset.conf > /etc/apache2/conf-available/charset.conf.new"

    mv /etc/apache2/conf-available/charset.conf{.new,}

    cp /etc/apache2/sites-available/000-default.conf{,.bak}

    sh -c "sed -e 's/VirtualHost \*:80/VirtualHost $domain:80/' /etc/apache2/sites-available/000-default.conf > /etc/apache2/sites-available/000-default.conf.new"

    mv /etc/apache2/sites-available/000-default.conf{.new,}

    a2enmod proxy_fcgi setenvif rewrite


    a2enmod php$php_version
    ;;
esac

exit

apt-get -qq -y install mariadb-client mariadb-server

apt-get -qq -y install  memcached php-memcache

cd ~$curuser

wget $new_wordpress_url

unzip latest-ru_RU.zip

rm -f latest-ru_RU.zip

wget https://raw.githubusercontent.com/koo2018/websitebuilding/master/newstudent

wget https://raw.githubusercontent.com/koo2018/websitebuilding/master/delstudent

wget https://raw.githubusercontent.com/koo2018/websitebuilding/master/tarbkp

wget https://raw.githubusercontent.com/koo2018/websitebuilding/master/zipbkp

echo "Настраиваем скрипт newstudent"

sh -c "sed -e 's/hname=\"\"/hname=\"$domain\"/' newstudent > newstudent.new"

mv newstudent{.new,}

sh -c "sed -e 's/rootdbpasswd=\"\"/rootdbpasswd=\"$dbrootpassword\"/' newstudent > newstudent.new"

mv newstudent{.new,}

sh -c "sed -e 's/dbpasswd=\"\"/dbpasswd=\"$dbuserpassword\"/' newstudent > newstudent.new"

mv newstudent{.new,}

chown $curuser:$curuser newstudent

chmod 700 ./newstudent

echo "Настраиваем скрипт delstudent"

sh -c "sed -e 's/rootdbpasswd=\"\"/rootdbpasswd=\"$dbrootpassword\"/' delstudent > delstudent.new"

mv delstudent{.new,}

chown $curuser:$curuser delstudent

chmod 700 ./delstudent

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

chown $curuser:$curuser zipbkp

chmod 700 ./zipbkp

echo -e "\ny\n$dbrootpassword\n$dbrootpassword\ny\ny\ny\ny" | sudo /usr/bin/mysql_secure_installation

echo -e "use mysql; update user set plugin='' where User='root'; flush privileges;" | sudo mysql

cp /etc/ssh/sshd_config{,.bak}

sh -c "sed -e 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config > /etc/ssh/sshd_config.new"

mv /etc/ssh/sshd_config{.new,}

cp  /etc/mysql/mariadb.conf.d/50-server.cnf{,.bak}

sh -c "sed -e 's/#max_connections/max_connections/' /etc/mysql/mariadb.conf.d/50-server.cnf > /etc/mysql/mariadb.conf.d/50-server.cnf.new"

mv /etc/mysql/mariadb.conf.d/50-server.cnf{.new,}

sh -c "sed -e 's/max_connections        = 100/max_connections        = 200/' /etc/mysql/mariadb.conf.d/50-server.cnf > /etc/mysql/mariadb.conf.d/50-server.cnf.new"

mv /etc/mysql/mariadb.conf.d/50-server.cnf{.new,}

php_path=`php -i | grep "Loaded Configuration File" | awk -F "=>" '{print $2}'`

php_path=`echo "${php_path/cli/fpm}"`

cp  $php_path{,.bak}

sh -c "sed -e 's/upload_max_filesize = 2M/upload_max_filesize = 50M/' $php_path > $php_path.new"

mv $php_path{.new,}

echo -e ' # Generated by NOT /usr/bin/select-editor\nSELECTED_EDITOR="/usr/bin/mcedit"' > .selected_editor

echo -e '\n\n EVERYTHING IS DONE. REBOOTING . . . \n\n DO NOT FOREGET TO DROP IN AGAIN \n\n JUST TYPE TWO EXCLAMATION MARKS\n\n !!\n\n'
