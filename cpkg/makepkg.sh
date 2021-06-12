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

tar -cvf cpkg-1.0pa3.txz PKG -J

if test -f "cpkg-1.0pa3.txz"; then
    echo "Build package done"
else
    echo "Build package FAIL"
fi

exit 0
