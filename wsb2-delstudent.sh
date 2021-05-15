#!/bin/bash

#
# Here you can change parameters (spaces around equal sign will give error)
#

# db root passwd
rootdbpasswd=""

# chosen configuration
webserver=""

# don't make changes below this line if you don't understan what you're doing

if [ "$rootdbpasswd" = "" ]; then
echo -e "Missing database root password \$rootdbpasswd. \n"
stop_var=1
fi

if [ "$webserver" != "1" ] || [ "$webserver" != "2" ]; then
echo -e "Unexisting webserver configuration. Only 1 and 2 are available. \n"
stop_var=1
fi


if [ "$#" -eq 0 ]; then
echo -e 'One parameter is expected\n
./wsb2-delstudent.sh studentName \n'
stop_var=1
fi




grep "$1:" /etc/passwd >/dev/null
if [ $? -ne 0 ]; then
echo -e "There's no such a user: $1\n"
stop_var=1
fi

if [ $stop_var ]; then
echo -e "Stopped! \n"
exit
fi

case $webserver in
      1)
        echo -n "Removing configuration "$1".conf on nginx...  "
        sudo rm -f /etc/nginx/sites-available/$1.conf

        sudo rm -f /etc/nginx/sites-enabled/$1.conf
        echo "Completed"
        
        
        echo -n "Restarting nginx...  "
        sudo systemctl reload nginx
        echo "Completed"


      ;;

      2)

        apache_vhosts="/etc/apache2/sites-available"

        echo -n "Turning off site "$1" on apache2...  "
        sudo a2dissite -q $1
        echo ""

        echo -n "Removing configuration "$1".conf on apache2...  "
        sudo rm -f $apache_vhosts"/"$1.conf
        echo "Completed"
        echo ""


        echo -n "Restarting apache2...  "
        sudo systemctl reload apache2
        echo "Completed"
        echo ""


      ;;
  esac


echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
echo "*"
echo "*  Deleting student " $1
echo "*"
echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
echo ""

echo -n "Deleting user "$1"...  "
sudo deluser  --remove-home $1
echo "Completed"
echo ""

echo -n "Deleting MySQL uesr and the database...  "
mysql -u root -p$rootdbpasswd <<EOF
DROP USER $1@'localhost';
DROP DATABASE $1;
FLUSH PRIVILEGES;
EOF
echo "Completed"
echo ""

echo "Removing "$1"'s account is completed!"
echo ""
