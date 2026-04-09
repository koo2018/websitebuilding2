#!/bin/bash

# Включает ранее отключённый сайт студента.
# Использование: wsb2-onsite.sh <студент>

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
webserver=$(grep '^webserver=' "$SCRIPT_DIR/wsb2-newstudent.sh" | cut -d'"' -f2)

if [ -z "$webserver" ]; then
    echo "Не удалось определить тип веб-сервера из wsb2-newstudent.sh"
    exit 1
fi

if [ $# -ne 1 ]; then
    echo "Использование: wsb2-onsite.sh <студент>"
    exit 1
fi

STUDENT="$1"

if ! grep -q "^$STUDENT:" /etc/passwd; then
    echo "Пользователь '$STUDENT' не найден"
    exit 1
fi

case $webserver in
    1)
        if [ ! -f /etc/nginx/sites-available/$STUDENT.conf ]; then
            echo "Конфиг сайта '$STUDENT' не найден: /etc/nginx/sites-available/$STUDENT.conf"
            exit 1
        fi
        if [ -L /etc/nginx/sites-enabled/$STUDENT.conf ]; then
            echo "Сайт '$STUDENT' уже включён"
            exit 0
        fi
        sudo ln -s /etc/nginx/sites-available/$STUDENT.conf /etc/nginx/sites-enabled/
        sudo systemctl reload nginx
        ;;
    2)
        if [ ! -f /etc/apache2/sites-available/$STUDENT.conf ]; then
            echo "Конфиг сайта '$STUDENT' не найден: /etc/apache2/sites-available/$STUDENT.conf"
            exit 1
        fi
        if [ -f /etc/apache2/sites-enabled/$STUDENT.conf ]; then
            echo "Сайт '$STUDENT' уже включён"
            exit 0
        fi
        sudo a2ensite -q $STUDENT
        sudo systemctl reload apache2
        ;;
    *)
        echo "Неизвестный тип веб-сервера: $webserver"
        exit 1
        ;;
esac

echo "Сайт '$STUDENT' включён."
