#!/bin/bash
#
# CPkg - an automated packaging tool fog Calmira Linux
# Cooyright (C) 2021 Michail Krasnov
#
# Project Page: http://github.com/Linuxoid85/cpkg
# Michail Krasnov linuxoid85@gmail.com
#

for FILE in "usr" "usr/bin" "usr/lib" "usr/lib/cpkg" "etc" "etc/cpkg"; do
    if test -d $FILE; then
        echo "$FILE is found"
    else
        echo "$FILE doesn't find in $PWD !"
        exit 0
    fi
done

for FILE in "usr/bin/cpkg" "usr/lib/cpkg/core-functions.sh" "usr/lib/cpkg/other-functions.sh" "etc/cpkg/settings"; do
    if test -f $FILE; then
        echo "$FILE is found"
    else
        echo "$FILE doesn't find in $PWD !"
        exit 0
    fi
done

mkdir -pv PKG/pkg
cp -rv {usr,etc} PKG/pkg/

cat > PKG/config.sh << "EOF"
NAME=cpkg
VERSION=1.0pa3
DESCRIPTION="CPkg - an automated packaging tool fog Calmira Linux"
MAINTAINER=Linuxoid85
FILES="/usr/bin/cpkg /usr/lib/cpkg /etc/cpkg/{pkg.list,settings}"
EOF

cat > PKG/changelog << "EOF"
** version 1.0pa3 ** 12.05.2021
Prealpha 3.
 * Повышение стабильности пакетного менеджера
 * Исправлен баг с ошибкой занесения port-пакета в базу данных `cpkg`
 * Другие незначительные фиксы

** version 1.0pa2 ** 12.05.2021
Prealpha 2.
 * улучшен алгоритм скачивания пакетов
 * исправлен баг с выходом из cpkg при автоматическом скачивании пакета в процедуре установки
 * исправлено два бага с port-пакетами (#3 и #1)
 * добавлены опции для скачивания как одного пакета, так и всех пакетов в репозитории в целом
 * всяческие незначительные фиксы и исправления

** version 1.0pa1 **  10.05.2021
Prealpha 1. Initial Release
EOF

tar -cvf cpkg-1.0pa3.txz PKG -J

if test -f "cpkg-1.0pa3.txz"; then
    echo "Build package done"
else
    echo "Build package FAIL"
fi

exit 0
