#!/bin/bash

# Отключает сайт студента без удаления аккаунта и данных.
# Использование: wsb2-offsite.sh <студент>

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
webserver=$(grep '^webserver=' "$SCRIPT_DIR/wsb2-newstudent.sh" | cut -d'"' -f2)

if [ -z "$webserver" ]; then
    echo "Не удалось определить тип веб-сервера из wsb2-newstudent.sh"
    exit 1
fi

if [ $# -ne 1 ]; then
    echo "Использование: wsb2-offsite.sh <студент>"
    exit 1
fi

STUDENT="$1"

if ! grep -q "^$STUDENT:" /etc/passwd; then
    echo "Пользователь '$STUDENT' не найден"
    exit 1
fi

case $webserver in
    1)
        if [ ! -L /etc/nginx/sites-enabled/$STUDENT.conf ]; then
            echo "Сайт '$STUDENT' уже выключен"
            exit 0
        fi
        sudo rm -f /etc/nginx/sites-enabled/$STUDENT.conf
        sudo systemctl reload nginx
        ;;
    2)
        if [ ! -f /etc/apache2/sites-enabled/$STUDENT.conf ]; then
            echo "Сайт '$STUDENT' уже выключен"
            exit 0
        fi
        sudo a2dissite -q $STUDENT
        sudo systemctl reload apache2
        ;;
    *)
        echo "Неизвестный тип веб-сервера: $webserver"
        exit 1
        ;;
esac

echo "Сайт '$STUDENT' выключен. Данные и аккаунт сохранены."
echo "Для включения: wsb2-onsite.sh $STUDENT"
