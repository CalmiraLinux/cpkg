NAME=cpkg
VERSION=v1.1a1
DESCRIPTION="CPkg - пакетный менеджер для Calmira GNU/Linux. Название cpkg происходит от двух слов:
* Calmira - c
* Package - pkg

На данный момент, ПМ в разработке. Он может быть нестабильным, медленным, могут отсутствовать некоторые функции.

---------------------------------------------------------
(С) 2021 Михаил Linuxoid85 Краснов <linuxoid85@gmail.com>"
REQ_DEPS="bash tar"
OPT_DEPS="dialog"
PRIORITY=system
MAINTAINER=Linuxoid85
FILES="/usr/bin/{cpkg,cpkg_log,cpkg_log_read} /usr/include/calmira-core-functions.h /usr/share/cpkg /usr/share/doc/cpkg /etc/cpkg /var/cache/cpkg"
