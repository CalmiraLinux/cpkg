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
	if [ $run = "y" ]; then
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

function send_signal() {
	if [ $1 = "quiet" ]; then
		export QUIET=true
	elif [ $1 = "debug" ]; then
		export DBG=true
	elif [ $1 = "clean" ]; then
		export CLEAN=true
	else
		print_msg "\e;1;31mERROR: uknown option '$1'"
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


# Function to check if a package is installed
## Options
# $1 - package name
# $2 - function mode
## Mode
# blacklist - for 'blacklist_pkg' function
function check_instaled() {
	PKG=$2
	OPTION=$1
	
	# Test package dir
	if [ -f "$VARDIR/packages/$PKG" ]; then
		log_msg "Directory '$VARDIR/packages/$PKG' is found." "OK"
		if [ $OPTION = "blacklist" ]; then
			BLACK_FILE="$VARDIR/packages/$PKG/black"
		else
			print_msg "\e[1;31m$ERROR $ERROR_NO_OPTION ('check_installed' function)\e[0m"
			exit 1
		fi
	else
		print_msg "\e[1;31m$ERROR $PACKAGE \e[0m\e[35m'$PKG'\e[0m\e[1;31m $PACKAGE_NOT_INSTALLED_OR_NAME_INCORRECTLY\e[0m"
		exit 1
	fi
}

function log_msg() {
	# $1 - msg
	# $2 - result

	if [ -z $3 ]; then
		LOG=/var/log/cpkg.log
	else
		LOG=$3
	fi

	echo -e "[ $(date) ] [ $1 ] [ $2 ]" >> $LOG
}

GetCalmiraVersion() {
	if [ -f "/etc/lsb-release" ]; then
		source /etc/lsb-release
		echo "$DISTRIB_RELEASE"
	else
		echo "Uknown version of Calmira"
	fi
}
