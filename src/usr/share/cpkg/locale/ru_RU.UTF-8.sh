#!/bin/bash
#
# CPkg - an automated packaging tool fog Calmira Linux
# Copyright (C) 2021 Michail Krasnov
#
# Project Page: http://github.com/Linuxoid85/cpkg
# Michail Krasnov <michail383krasnov@mail.ru>
#

# cpkg
CPKG_ABOUT="CPkg - пакетный менеджер для Calmira GNU/Linux"
CPKG_VER="Версия ПМ:"
CPKG_DISTRO_VER="Версия дистрибутива:"

# errors
ERROR="ОШИБКА:"
ERROR_NO_FUNC="\e[1;31mОШИБКА: файл /usr/lib/cpkg/$FUNC не существует! \e[0m"
ERROR_PACKAGE_NOT_INSTALLED="\e[1;31mОШИБКА: пакет \e[1;35m$PACKAGE\e[0m\e[1;31m не установлен! \e[0m"
ERROR_NO_OPTION="\e[1;31mОШИБКА: опция(и) '$@' не существуют! \e[0m\n"
ERROR_UNPACK_PKG_NOT_FOUND="\e[1;31mПакет\e[0m\e[35m $PKG\e[0m\e[1;31m не распакован! \e[0m"
CRITICAL_ERROR="\e[1;31mКритическая ошибка! Работа cpkg более не возможна.\e[0m"

# actions
ACTION_INSTALL="Установка пакета"
ACTION_REMOVE="Удаление пакета"
ACTION_DOWNLOAD="Установка пакета"
ACTION_UPDATE_LIST="Обновление списка пакетов"
ACTION_LIST="Просмотр списка пакетов"
ACTION_SEARCH="Поиск пакета"
ACTION_INFO="Просмотр информации о пакете"
ACTION_CLEAN="Очистка кеша"
ACTION_SOURCE="Редактирование списка пакетов"
ACTION_UKNOWN_OPTION="Запуск 'cpkg' с опцией(ями), которая(ые) неизвестна(ы) ПМ: "

# other
DONE="Завершено"
RETRY="повторение..."
FAIL="\e[1;31mОШИБКА\e[0m"
PKGLIST_DOWNLOAD="\e[1;32mСкачивание списка пакетов...\e[0m"
FILE="Файл"
DOESNT_EXISTS="не существует!"
DOESNT_INSTALLED="не установлен!"
PACKAGE="Пакет"
CONTINUE="Продолжить?"
CANSELLED="Прервано!"

# depends
REQUIRED_DEP="Необходимые:"
TESTING_DEP="Для тестирования:"
OPTIONAL_DEP="Опциональные:"
BEFORE_DEP="Установлен перед ними:"
DEP_INSTALL="Установите эти зависимости перед установкой пакета, если иное не сказано в пункте $BEFORE_DEP!\e[0m"
DEP_REMOVE="Удалите эти зависимости перед удалением пакета, если иное не сказано в пунктах выше!"
DEP_INFO="При удалении или переустановке пакета убедитесь, что зависимости удовлетворены!"


###########################
##                       ##
##   core-functions.sh   ##
##                       ##
###########################

# check_priority
CHECK_PRIORITY_START="\e[1;32mЗапуск проверки приоритета пакета...\e[0m"
PRIORITY_NOT_FOUND="\e[31mПеременная приоритета \e[0m\e[35m\$PRIORITY\e[0m\e[31m не найдена в \e[0m\e[35m$(pwd)/config.sh\e[0m\e[31m!\e[0m"
PRIORITY_NOT_FOUND_ANSWER="\e[1mДействительно удалить пакет? Помните, что удаление пакета с неизвестным приоритетом НЕ РЕКОМЕНДУЕТСЯ! (y/n) \e[0m"
SYSTEM_PRIORITY_REMOVE_BLOCKED="ВНИМАНИЕ! Приоритет пакета: 'системный'. Это значит, что пакет необходим для
корректной работы системы, поэтому его удаление запрещено. Выход."
PRIORITY_DONE="\e[32mТест на приоритет прошёл успешно - это не системный пакет;
удалять можно.\e[0m"
PRIOTITY_MSG="Приоритет"

# search_pkg and file_search
SEARCH_PACKAGE="\e[1;32mПоиск пакета\e[0m \e[35m$PKG\e[0m\e[1;32m...\e[0m"
SEARCH1="\e[32mПакет\e[0m"
SEARCH2="\e[32mсуществует в \e[0m"
SEARCH_RESULT="Результаты поиска:"

# unpack_pkg
UNPACK1="\e[1;32mРаспаковка пакета\e[0m"
UNPACK_COMPLETE1="\e[32mПакет\e[0m"
UNPACK_COMPLETE2="\e[32mраспакован\e[0m\n"
UNPACK_FAIL1="\e[1;31mПакет\e[0m"
UNPACK_FAIL2="\e[1;31mне был распакован! \e[0m"

# arch_test
ARCH_TEST="\e[1;32mТест архитектуры пакета...\e[0m"
ARCH_VARIABLE_NOT_FOUND="\e[31m[ Указатель архитектуры не существует ]\e[0m"
MULTIARCH_DONE="\e[32m [ Мультиархитектурный тест прошёл успешно! ] \e[0m"
ARCH_DONE="\e[32m[ Архитектурный тест прошёл успешно! ]\e[0m"

# install_pkg
DEPEND_LIST_INSTALL=">> \e[1;32mСписок зависимостей\e[0m"
EXECUTE_PREINSTALL=">> \e[32mЗапуск предустановочного скрипта...\e[0m"
EXECUTE_POSTINSTALL=">> \e[32mЗапуск послеустановочного скрипта...\e[0m"
SETTING_UP_POSTINSTALL=">> \e[32mНастройка послеустановочного скрипта...\e[0m"
INSTALL_PORT=">> \e[1;32mУстановка port-пакета...\e[0m"
COPY_PKG_DATA=">> \e[1;32mКопирование данных пакета...\e[0m"
WARN_NO_PKG_DIR="\e[33mПРЕДУПРЕЖДЕНИЕ: директория 'pkg' отсутствует\e[0m"
SETTING_UP_PACKAGE=">> \e[1;32mНастройка пакета...\e[0m"
ADD_IN_DB="\e[32mДобавление пакета в базу данных\e[0m"

# remove_pkg
PACKAGE_NOT_INSTALLED_OR_NAME_INCORRECTLY="не установлен, либо имя введено неправильно."
REMOVE_PKG=">> \e[1;34mУдаление пакета\e[0m"
REMOVE_PKG_FAIL="не был удалён успешно!"
REMOVE_PKG_OK="удалён успешно."

# download_pkg
FOUND_PKG="Существует"
NOT_FOUND_PKG="не существует в"
DOWNLOAD_PKG=">> \e[1;32mСкачивание пакета...\e[0m"
DOWNLOAD_PKG_FAIL="не был скачан успешно!"

# package_info
PACKAGE_INFO="Информация о пакете"
PACKAGE_NAME="Имя:"
PACKAGE_RELEASE="Версия:"
PACKAGE_DESCRIPTION="Описание:"
PACKAGE_MAINTAINER="Сборщик пакета:"
PACKAGE_FILES="Установленные файлы:"

# cache_clean
CACHE_CLEAN="Очистка кеша..."

# help_pkg
HELP_CPKG="\e[1;32mБазовые опции\e[0m
\e[1minstall\e[0m        - установка пакета
\e[1mremove\e[0m         - удаление пакета
\e[1mlist\e[0m           - просмотр всех установленных пакетов
\e[1msearch\e[0m         - поиск пакета
\e[1mdownload\e[0m       - скачивание пакета

---------------------------------------------------
\e[1;32mКлючи\e[0m
\e[1m-i\e[0m             - установка пакета
\e[1m-r\e[0m             - удаление пакета
\e[1m-I\e[0m             - информация о пакете
\e[1m-s\e[0m             - поиск установленного пакета
\e[1m--quiet=true\e[0m   - тихий режим с минимумом сообщений на экране
\e[1m--debug-mode=true\e[0m   - debug-режим с большим кол-вом сообщений для отладки
---------------------------------------------------
(C) 2021 Михаил Краснов \e[4m<michail383krasnov@mail.ru>\e[0m
Для Calmira GNU/Linux"
