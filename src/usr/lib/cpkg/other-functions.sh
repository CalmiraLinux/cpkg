#!/bin/bash
#
# CPkg - an automated packaging tool for Calmira Linux
# Copyright (C) 2021 Michail Krasnov
#
# other-functions.sh
#
# Project Page: http://github.com/Linuxoid85/cpkg
# Michail Krasnov <michail383krasnov@mail.ru>
#

#==================================================================#
#
# BASE VARIABLES
#
BACKTITLE="Calmira package manager"		# Backtitle for `print_ps_msg`
TITLE="cpkg"					# Title for `print_ps_msg`
NAME_FILE="other-functions.sh"			# File name for log_msg

#==================================================================#
#
# BASE FUNCTIONS
#

# Function for print a messages on screen
function print_msg() {
	if [[ $QUIET = "true" ]]; then
		echo "$@" > /dev/null
	else
		echo -e $@
	fi
}

function print_ps_msg() {
	dialog --backtitle "$BACKTITLE" --title " $TITLE " --msgbox "$1" 0 0
}

function print_document_dial() {
	dialog  --backtitle "Система портов Calmira LX4 Linux" --title " ASK " \
		--yesno "Для пакета $1 предусмотрена установка дополнительной документации. Установить её?" 0 0
	
	case $? in
		1)
			dialog  --backtitle "Система портов Calmira LX4 Linux" --title " CANSEL " \
				--msgbox "Установка документации прервана" 0 0
			exit 0
		;;
		
		0)
			if [ -f "install_doc.sh" ]; then
				chmod +x install_doc.sh
				./install_doc.sh
			else
				echo -e "\e[1;31mОШИБКА: скрипт для установки документации не найден! \e[0m"
				exit 1
			fi
		;;
		
		255)
			dialog  --backtitle "Система портов Calmira LX4 Linux" --title " CANSEL " \
				--msgbox "Была нажата клавиша для отмены установки." 0 0
			exit 1
		;;
	esac
}

# Function for print a debug messages on screen
function print_dbg_msg() {
	if [[ $DBG = "false" ]]; then
		echo "[ $(date) ] $@" > /var/log/cpkg_dbg.log
	else
		echo -e $@
	fi
}

function dialog_msg() {
	read -p "$CONTINUE (y/n): " run
	if [ $run = "y" ] && [ $run = "Y" ]; then
		print_dbg_msg "Continue"
	else
		echo "$CANSELLED"
		exit 1
	fi
}

function test_root() {
	if [[ $(whoami) -ne "root" ]]; then
		echo -e "\e[1;31mERROR\e[0m: only root can run this program!"
		exit 0
	fi
}

# Function for a print error message on screen
# $1 - error type
function error() {
	if [ $1 = "no_pkg" ]; then
		echo -e "\e[1;31mERROR\e[0m: package $PKG doesn't exists!"
	elif [ $1 = "no_config" ]; then
		echo -e "\e[1;31mERROR\e[0m: configurition file doesn't exists!"
	elif [ $1 = "no_pkg_data" ]; then
		echo -e "\e[1;31mERROR\e[0m: package data doesn't exists!"
	elif [ $1 = "no_arch" ]; then
		echo -e "\e[1;31mERROR\e[0m: package architecture $2 doesn't support on this host!"
	elif [ $1 = "not_found_arch" ]; then
		echo -e "\e[1;31mERROR\e[0m: doesn't find ARCHITECTURE variable on config.sh!"
		dialog_msg
	fi
}

# Function to check for the presence of the
# required files and directories
function check_file() {
    for DIR in "/var/{cache,db}/cpkg/packages" "/etc/cpkg"; do
        # Test the cache dir
        print_dbg_msg -n "check dir '$DIR' ... "
        if test -d "$DIR"; then
            print_dbg_msg "done"
        else
            print_dbg_msg "fail"
            print_msg -n "\e[1;31mERROR\e[0m: dir ($DIR) doesn't exists! Create it?"
            if [[ $QUIET -eq "true" ]]; then
                mkdir -p $DIR
            else
                dialog_msg
                mkdir -pv $DIR
            fi
        fi
    done
}

# Function for write logs in log file
## Options:
# $1 - message
# $2 - status
# $3 - log file (optional)
## Statuses:
# Notice
# Error
# Emerg
# OK
## Variables:
# NAME_FUNCTION - function name
# NAME_FILE     - file name (e.g. 'core-functions.sh', 'other-functions.sh', etc.)
function log_msg() {
	# $1 - msg
	# $2 - result

	if [ -z $3 ]; then
		LOG=/var/log/cpkg.log
	else
		LOG=$3
	fi
	
	if [ -z $NAME_FUNCTION ]; then
		NAME_FUNCTION="Uknown"
	fi

	echo -e "[ $(date) ] Function $NAME_FUNCTION from $NAME_FILE: $1 [ $2 ]" >> $LOG
	         # DATE      MESSAGE INFO                             # MESSAGE # STATUS
}

function GetCalmiraVersion() {
	if [ -f "/etc/lsb-release" ]; then
		source /etc/lsb-release
		echo "$DISTRIB_RELEASE"
	else
		echo "Uknown version of Calmira"
	fi
}

function about_sys() {
	source /etc/lsb-release
	echo -e "           \e[36m#######\e[0m\e[1;96m*.*.\e[0m
       \e[1;36m=#DD-D####DDD#\e[0m
      \e[1;36m#----#\e[0m      \e[1;94m#-#\e[0m
     \e[1;36m#---#\e[0m         \e[1;94m##\e[0m
    \e[96m#---#\e[0m                 \e[33m'\e[0m
    \e[96m#@@@#\e[0m                  \e[1;93m*\e[0m
    \e[1;34m#=@=#\e[0m        \e[34m##\e[0m         \e[33m'\e[0m
     \e[1;34m#===#\e[0m    \e[34m##=#\e[0m           \e[93m'\e[0m
       \e[1;34m##===\e[0m\e[34m==\e[0m\e[1;34m##=\e[0m


\e[1;36m---=== О системе ===---\e[0m
\e[1;36mИмя:\e[0m		$DISTRIB_ID
\e[1;36mВерсия:\e[0m		$DISTRIB_RELEASE
\e[1;36mКодовое имя:\e[0m  	$DISTRIB_CODENAME
\e[1;36mПользователь:\e[0m 	$(whoami)
\e[1;36mПоложение:\e[0m	$PWD
"
}

log_msg "Date other-functions started: $(date)" "OK"
