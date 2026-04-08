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


# создаем архив /home/ без директории учителя
tar cpf "$BACKUPS_DIR/$DATE_PREF.tar" --exclude="home/$TEACHER_NAME" /home/


# упаковываем дамп и архив в один .tgz
tar -czf "$BACKUPS_DIR/$DATE_PREF.tgz" -C "$BACKUPS_DIR" "$DATE_PREF.tar" "$DATE_PREF.sql"

cd "$BACKUPS_DIR"

rm -f "$DATE_PREF.sql" "$DATE_PREF.tar"


# ищем файлы старше 14 суток и удаляем их
find ./ -mindepth 1 -mtime +14 -delete > /dev/null 2>&1
