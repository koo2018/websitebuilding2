#!/bin/bash

#
# Here you can change parameters (spaces around equal sign will give error)
#

# db root passwd
rootdbpasswd=""

# chosen configuration
webserver=""

# don't make changes below this line if you don't understand what you're doing

if [ "$rootdbpasswd" = "" ]; then
echo -e "Missing database root password \$rootdbpasswd. \n"
stop_var=1
fi

if [ "$webserver" != "1" ] && [ "$webserver" != "2" ]; then
echo -e "Unexisting webserver configuration. Only 1 and 2 are available. \n"
stop_var=1
fi

if [ "$#" -eq 0 ]; then
echo -e 'One parameter is expected\n
./wsb2-delgroup.sh groupName \n'
stop_var=1
fi

if [ "$stop_var" = "1" ]; then
echo -e "Stopped! \n"
exit
fi

GROUP="$1"
group_home="/home/$GROUP"

if [ ! -d "$group_home" ]; then
echo -e "There's no such group directory: $group_home\n"
exit 1
fi

grep "^$GROUP:" /etc/group > /dev/null
if [ $? -ne 0 ]; then
echo -e "There's no such Unix group: $GROUP\n"
exit 1
fi

STUDENTS=$(ls "$group_home")

if [ -z "$STUDENTS" ]; then
echo "Group directory is empty, no students to delete."
else

echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
echo "*"
echo "*  Deleting all students in group: $GROUP"
echo "*"
echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
echo ""

for STUDENT in $STUDENTS; do

    echo "--- Deleting student: $STUDENT ---"

    case $webserver in
        1)
            echo -n "  Removing nginx config $STUDENT.conf...  "
            sudo rm -f /etc/nginx/sites-available/$STUDENT.conf
            sudo rm -f /etc/nginx/sites-enabled/$STUDENT.conf
            echo "Done"
        ;;
        2)
            echo -n "  Disabling apache2 site $STUDENT...  "
            sudo a2dissite -q $STUDENT
            echo ""
            echo -n "  Removing apache2 config $STUDENT.conf...  "
            sudo rm -f /etc/apache2/sites-available/$STUDENT.conf
            echo "Done"
        ;;
    esac

    echo -n "  Dropping MySQL user and database $STUDENT...  "
    sudo mysql -u root -p$rootdbpasswd <<EOF
DROP USER IF EXISTS '$STUDENT'@'localhost';
DROP DATABASE IF EXISTS \`$STUDENT\`;
FLUSH PRIVILEGES;
EOF
    echo "Done"

    echo -n "  Deleting Unix user $STUDENT...  "
    sudo userdel -r $STUDENT
    echo "Done"

done

fi

echo -n "Reloading webserver...  "
case $webserver in
    1) sudo systemctl reload nginx ;;
    2) sudo systemctl reload apache2 ;;
esac
echo "Done"
echo ""

echo -n "Removing group home directory $group_home...  "
sudo rm -rf "$group_home"
echo "Done"

echo -n "Removing Unix group $GROUP...  "
sudo delgroup "$GROUP"
echo ""

echo "Group $GROUP and all its students have been deleted."
echo ""
