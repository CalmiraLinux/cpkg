#!/bin/bash
#
# CPkg - an automated packaging tool fog Calmira Linux
# Copyright (C) 2021 Michail Krasnov
#
# core-functions.sh
#
# Project Page: http://github.com/Linuxoid85/cpkg
# Michail Krasnov <michail383krasnov@mail.ru>
#

#==================================================================#
#
# BASE VARIABLES
#
VERSION=v1.0pa4
GetArch=$(uname -m)
GetDate=$(date)
GetPkgLocation=$(pwd)
PACKAGE_CACHE=/var/cache/cpkg/archives/PKG
PORT=false

#==================================================================#
#
# BASE FUNCTIONS
#

# Function for list depends
# REQ_DEPS - required depends
# TEST_DEPS - deps for test suite (only for port-packages)
# OPT_DEPS - optional deps
# BEF_DEPS - package may be installed before packages
# from $BEF_DEPS variable
function list_depends() {
	echo -e "$DEPEND_LIST_INSTALL
\e[1m$REQUIRED_DEP\e[0m		$REQ_DEPS
\e[1m$TESTING_DEP\e[0m		$TEST_DEPS
\e[1m$OPTIONAL_DEP\e[0m		$OPT_DEPS
\e[1m$BEFORE_DEP\e[0m		$BEF_DEPS"
}

# Function for check priority of package
# If priority = system, then package doesn't
# can remove from Calmira GNU/Linux
## Priority:
# 'system' and 'user'
function check_priority() {
	print_msg "$CHECK_PRIORITY_START"
	if [ -z $PRIORITY ]; then
		echo -e "$PRIORITY_NOT_FOUND"
		echo -e -n "$PRIORITY_NOT_FOUND_ANSWER"
		dialog_msg
	else
		print_dbg_msg "Priority variable is found"
		if [ $PRIORITY = "system" ]; then
			echo -e "\e[1;31m$SYSTEM_PRIORITY_REMOVE_BLOCKED\e[0m"
			exit 999
		else
			echo -e "\e[1m$PRIORITY_MSG:\e[0m	$PRIORITY\n\e[32m$SYSTEM_PRIORITY_REMOVE_OK\e[0m"
		fi
	fi
}

# Function for search a package
# $1 - package
function search_pkg() {
	PKG=$1
	print_msg "$SEARCH_PACKAGE"
	if test -f "$PKG"; then
		print_msg "$SEARCH1 \e[35m$PKG\e[0m $SEARCH2 \e[35m$GetPkgLocation\e[0m"
	else
		download_pkg $PKG
	fi
}

# Function for unpack a package
# $1 - package
function unpack_pkg() {
	PKG=$1
	print_dbg_msg "Copy $PKG in /var/cache/cpkg/archives..."
	cp $PKG /var/cache/cpkg/archives/

	if test -f "/var/cache/cpkg/archives/$PKG"; then
		print_msg "$UNPACK1 \e[35m$PKG\e[0m\e[1;32m...\e[0m"
	else
		echo "$ERROR_UNPACK_PKG_NOT_FOUND"
		exit 0
	fi

	print_dbg_msg "Change dir..."
	cd /var/cache/cpkg/archives

	if test -d "PKG"; then
		rm -rf PKG
	fi

	tar -xf $PKG

	if test -d "PKG"; then
		print_msg "$UNPACK_COMPLETE1 \e[35m$PKG\e[0m $UNPACK_COMPLETE2"
	else
		print_msg "$UNPACK_FAIL1 \e[35m$PKG\e[0m $UNPACK_FAIL2!\n"
		exit 0
	fi
}

# Arch test
function arch_test_pkg() {
	print_msg -n "$ARCH_TEST"
	if [ -d $ARCHITECTURE ]; then
		print_msg " $ARCH_VARIABLE_NOT_FOUND"
	fi

	if [[ $ARCHITECTURE -ne $GetArch ]]; then
		if [[ $ARCHITECTURE -ne "multiarch" ]]; then
			error no_arch
			dialog_msg
		else
			print_msg "$MULTIARCH_DONE "
		fi
	else
		print_msg "$ARCH_DONE"
	fi
}

# Function to install a package
## VARIABLES:
# $1 - package
function install_pkg() {
	PKG=$1
	cd $PACKAGE_CACHE
	DIR=$(pwd)
	if test -f "config.sh"; then
		source config.sh
	else
		error no_config
	fi

	arch_test_pkg
	
	echo -e "\n\e[1mУстановите эти зависимости перед тем, как устанавливать этот пакет!\e[0m\n"
	list_depends
	dialog_msg

	if test -f "preinst.sh"; then
		print_msg "$EXECUTE_PREINSTALL"
		chmod +x preinst.sh
		./preinst.sh
	fi

	if test -f "postinst.sh"; then
		print_msg "$SETTING_UP_POSTINSTALL \n"
		chmod +x postinst.sh
		POSTINST=$DIR/postinst.sh
	fi

	if test -f "port.sh"; then
		print_msg "$INSTALL_PORT"
		PORT=true
		chmod +x port.sh
		./port.sh
		cd $DIR
	fi

	if test -d "pkg"; then
		print_msg "$COPY_PKG_DATA"
		cd pkg
		cp -r * /
	else
		if [[ $PORT = "true" ]]; then
			echo "$WARN_NO_PKG_DIR"
		else
			error no_pkg_data
			exit 0
		fi
	fi
	
	if [ $PORT = "true" ]; then
	    CONF_DIR=$DIR
	else
	    CONF_DIR=..
	fi

	print_msg "$SETTING_UP_PACKAGE\n"
	print_msg "$ADD_IN_DB"
	echo "$NAME $VERSION $DESCRIPTION $FILES" >> $DATABASE/all_db

	if test -d $DATABASE/packages/$NAME; then
		rm -rvf $DATABASE/packages/$NAME
	fi
	
	mkdir $DATABASE/packages/$NAME			# Creating a directory with information about the package
	cp $CONF_DIR/config.sh $DATABASE/packages/$NAME	# Copyng config file in database

	for FILE in "changelog" "postinst.sh" "preinst.sh" "port.sh"; do
    	if test -f "$CONF_DIR/$FILE"; then
	    	cp $CONF_DIR/$FILE $DATABASE/packages/$NAME/	# Copyng changelog and other files in database
	    fi
	done

	if [ -f $DIR/postinst.sh ]; then
		print_msg "$EXECUTE_POSTINSTALL"
		cd $DIR
		./postinst.sh
	fi

	print_msg "$DONE"
	exit 0
}

# Function for remove package
# $1 - package
function remove_pkg() {
	PKG=$1
	log_msg "Search package $PKG" "Process"
	if test -d "$DATABASE/packages/$PKG"; then
		log_msg "Search package $PKG: $PWD" "OK" && log_msg "Read package information" "Process"
		if test -f "$DATABASE/packages/$PKG/config.sh"; then
			cd $DATABASE/packages/$PKG
			log_msg "Read package information:" "OK"
			source config.sh
		else
			log_msg "Read package information:
test '$PWD/config.sh' fail, because this config file (config.sh) doesn't find" "FAIL"
			print_msg "\e[1;31m$FILE\e[0m \e[35m$(pwd)/config.sh\e[0m \e[1;31m$DOESNT_EXISTS $ERROR \e[0m"
			exit 0
		fi
	else
		log_msg "Package $PKG isn't installed or it's name was entered incorrectly" "FAIL"
		print_msg "\e[1;31m$PACKAGE\e[0m \e[35m$PKG\e[0m \e[1;31m$PACKAGE_NOT_INSTALLED_OR_NAME_INCORRECTLY\e[0m"
		exit 0
	fi

	log_msg "Remove package $PKG" "Process"
	check_priority
	
	echo -e "\n\e[1mУдалите эти зависимости перед тем, как удалять этот пакет!\e[0m\n"
	list_depends
	dialog_msg
	
	print_msg "$REMOVE_PKG \e[35m$PKG\e[0m\e[1;34m...\e[0m"

	rm -rf $FILES

	rm -rf $DATABASE/packages/$PKG
	if test -d $DATABASE/packages/$PKG; then
		log_msg "Removed unsucessfull" "FAIL"
		print_msg "\e[31m$PACKAGE $PKG $REMOVE_PKG_FAIL \e[0m"
	else
		log_msg "Removed sucessfull!" "OK"
		print_msg "\e[32m$PACKAGE $PKG $REMOVE_PKG_OK \e[0m"
	fi
}

# Function for download a package
# $1 - package
function download_pkg() {
	if grep "$1" $SOURCE; then
		print_msg "$FOUND_PKG '$1'"
	else
		print_msg "$PACKAGE '$1' $NOT_FOUND_PKG $SOURCE"
		exit 0
	fi
	
	PKG=$(grep "$1" $SOURCE)
	#alias wget='wget --no-check-certificate' # For Calmira 2021.1-2021.2
	print_msg "$DOWNLOAD_PKG"
	wget $PKG

	print_dbg_msg -n "test package... "
	if test -f "$1"; then
		print_dbg_msg "done"
	else
	    if test -f "$1*.txz"; then
	        print_dbg_msg "done"
	    else
    		print_dbg_msg "FAIL"
	    	print_msg "\e[1;31m$ERROR: $PACKAGE '$1' $DOWNLOAD_PKG_FAIL \e[0m"
	    	exit 0
	    fi
	fi
}

# Function to read package info
# $1 - package
function package_info() {
	PKG=$1
	if test -d "$DATABASE/packages/$PKG"; then
		cd $DATABASE/packages/$PKG
		if test -f "config.sh"; then
			log_msg "Read package information:" "OK"
			source config.sh
		else
			log_msg "Read package information:
test '$PWD/config.sh' fail, because this config file (config.sh) doesn't find" "FAIL"
			print_msg "\e[1;31m$ERROR\e[0m: $PWD/config.sh $DOESNT_EXISTS"
			exit 0
		fi
	else
		log_msg "Print info about package $PKG:
test '/etc/cpkg/database/packages/$PKG' fail, because this directory doesn't find" "FAIL"
		print_msg "\e[1;31m$ERROR: $PACKAGE \e[10m\e[1;35m$PKG\e[0m\e[1;31m $DOESNT_INSTALLED \e[0m"
		exit 0
	fi

	echo -e "\e[1;32m$PACKAGE_INFO ($PKG):\e[0m
\e[1;34m$PACKAGE_NAME\e[0m		$NAME
\e[1;34m$PACKAGE_DESCRIPTION\e[0m	$DESCRIPTION
\e[1;34m$PACKAGE_MAINTAINER\e[0m	$MAINTAINER
\e[1;34m$PACKAGE_FILES\e[0m		$FILES"
	list_depends
}

# Function for a list packages in file system
function file_list() {
	cd $DATABASE/packages/
	exa --tree
}

# Function for search a package in file system (do not for install/remove package!!!)
# $1 - package
function file_search() {
	if [ -z $1 ]; then
		error no_pkg
		exit 0
	fi

	PKG=$1
	print_msg ">> \e[1;32m$SEARCH_PACKAGE\e[0m \e[35m$PKG\e[0m\e[1;32m...\e[0m"

	exa $DATABASE/packages |grep $PKG
}

# Function for clean cache
function cache_clean() {
	print_msg "[ $GetDate ] \e[1;32m$CACHE_CLEAN\e[0m"
	log_msg "Clearing cpkg cache..." "Process"
	rm -rf /var/cache/cpkg/archives/*
}

# Function for clean source dir
function source_clean() {
	print_msg "[ $GetDate ] \e[1;32m$SRC_CLEAN\e[0m"
	log_msg "Clearing source directory..." "Process"
	rm -rf /usr/src/*
}

# Function for edit sources
function edit_src() {
	if test -f "/etc/cpkg/pkg.list"; then
		if [ -z $EDITOR ]; then
			export EDITOR="$(which vim)"
		fi
		$EDITOR /etc/cpkg/pkg.list
	else
		print_msg "\e[1;31mERROR: file\e[0m \e[35m/etc/cpkg/pkg.list\e[0m\e[1;31mdoesn't find!\e[0m"
		exit 0
	fi
}

# Help
function help_pkg() {
	echo -e "\e[1;35m$CPKG_ABOUT\e[0m
\e[1m$CPKG_VER\e[0m        $VERSION (PreAlpha 4)
\e[1m$CPKG_DISTRO_VER\e[0m $GetCalmiraVersion

$HELP_CPKG $GetCalmiraVersion
"
}

check_file
