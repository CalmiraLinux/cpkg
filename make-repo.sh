#!/bin/bash
#
# make-repo.sh
#
# Скрипт для настройки локального репозитория перед
# отправкой на git
#

for FILE in "BUGS.md" "INSTALL.md" "LICENSE" "README.md" "ROADMAP.md" "TODO.md" "USAGE"; do
	if [ -f "$FILE" ]; then
		echo "file $FILE is found"
		echo -e "Копирование файлов в /docs...\n" >> ../log
		cp -v $FILE docs/ >> ../log
		
		echo -e "\n\nКопирование файлов в /src/usr/share/doc/cpkg/...\n" >> ../log
		cp -v $FILE src/usr/share/doc/cpkg >> ../log
	fi
done

git add .
git commit -m "Копирование документации в нужные директории"
git push
