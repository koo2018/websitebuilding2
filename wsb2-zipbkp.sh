#!/bin/bash

#
# Здесь можно менять параметры (пробелы вокруг знака равно будут ошибкой)
#

# аккаунт учителя. нужен чтобы исключить из бэкапа
# тк cron, автоматическое определение лучше не использовать
TEACHER_NAME=""

# директория, где будет храниться бэкап
BACKUPS_DIR=""

# Дальше править не нужно, если вы не понимаете, что делаете


DATE_PREF=$(date +%F)


# создаем директорию для бэкапа, если еще нет
if ! [ -d "$BACKUPS_DIR" ]; then
    mkdir -p "$BACKUPS_DIR"
fi


# создаем дампы баз данных MySQL
mysqldump -q -u root -p1234 -h localhost -A > "$BACKUPS_DIR/$DATE_PREF.sql"


cd "$BACKUPS_DIR"

# создаем zip-архив /home/ без директории учителя
zip -rD -9 "$BACKUPS_DIR/$DATE_PREF.zip" "$DATE_PREF.sql" /home/ -x "/home/$TEACHER_NAME/*"


rm -f "$DATE_PREF.sql"

# ищем файлы старше 14 суток и удаляем их, дабы не засорять жесткий диск
find ./ -mindepth 1 -mtime +14 -delete > /dev/null 2>&1
