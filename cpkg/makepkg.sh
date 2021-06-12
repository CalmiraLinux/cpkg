#!/bin/bash
#
# CPkg - an automated packaging tool fog Calmira Linux
# Cooyright (C) 2021 Michail Krasnov
#
# Project Page: http://github.com/Linuxoid85/cpkg
# Michail Krasnov linuxoid85@gmail.com
#

source config.sh
PACKAGE="$NAME-$VERSION.txz"

echo -e "\e[1mDIRS:\e[0m"
for FILE in "usr" "usr/bin" "usr/lib" "usr/lib/cpkg" "etc" "etc/cpkg"; do
    if test -d $FILE; then
        echo "$FILE is found"
    else
        echo "$FILE doesn't find in $PWD !"
        exit 0
    fi
done

echo -e "\n\e[1mFILES:\e[0m"
for FILE in "usr/bin/cpkg" "usr/lib/cpkg/core-functions.sh" "usr/lib/cpkg/other-functions.sh" "etc/cpkg/settings"; do
    if test -f $FILE; then
        echo "$FILE is found"
    else
        echo "$FILE doesn't find in $PWD !"
        exit 0
    fi
done

echo -e "\nMake dirs and copy package data..."
mkdir -pv PKG/pkg > log
cp -rv {usr,etc} PKG/pkg/ >> log

echo -e "Write package information..."
echo "$(cat config.sh)" > PKG/config.sh

for FILE in "port.sh" "preinst.sh" "postinst.sh"; do
    if test -f $FILE; then
        echo "$FILE is found"
        echo "$(cat $FILE)" > PKG/$FILE
    else
        echo "$FILE doesn't find in $PWD !"
    fi
done

if test -f changelog; then
    echo "changolog is found"
    echo "$(cat changelog)" > PKG/changelog
else
    echo "changelog doesn't find in $PWD !"
fi

echo -e "\nBuild package..."
tar -cf $PACKAGE PKG -J

echo "Test package..."
if test -f "cpkg-1.0pa3.txz"; then
    echo "Build package done"
    read -p "Show the package data? (Y/n) " run
    if [ $run = Y ]; then
        tar -listf $PACKAGE
    fi
    rm -rf PKG
else
    echo "Build package FAIL"
fi

exit 0
