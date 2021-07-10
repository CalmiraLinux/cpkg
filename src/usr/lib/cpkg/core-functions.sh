#!/bin/bash
#
# CPkg - an automated packaging tool for Calmira Linux
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
VERSION=v1.0b1		# cpkg version
GetArch=$(uname -m)	# System arch
GetDate=$(date)		# System date
GetPkgLocation=$(pwd)	# Package location
PACKAGE_CACHE=/var/cache/cpkg/archives/PKG
VARDIR=/var/db/cpkg	# Database dir
PORT=false		# Turn off port mode (default)



#==================================================================#
#
# PROGRAM FUNCTIONS
#


# Function for list depends
## Variables
# REQ_DEPS  - required depends
# TEST_DEPS - deps for test suite (only for port-packages)
# OPT_DEPS  - optional deps
# BEF_DEPS  - package may be installed before this depends
# from $BEF_DEPS variable
## Options
# list_depends install - for install_pkg function
# list_depends remove  - for remove_pkg function
# list_depends info    - for package_info function
function list_depends() {	
	echo -e ">> $DEPEND_LIST_INSTALL
\e[1m$REQUIRED_DEP\e[0m		$REQ_DEPS
\e[1m$TESTING_DEP\e[0m		$TEST_DEPS
\e[1m$OPTIONAL_DEP\e[0m		$OPT_DEPS
\e[1m$BEFORE_DEP\e[0m		$BEF_DEPS" # List depends
	# TODO - добавить опцию, позволяющую выводить только те разделы, которые описаны в config.sh
	# На данный момент выводятся все поля, даже если они пусты.
	
	if [ $1 = "install" ]; then
		print_msg "\e[1m$DEP_INSTALL\e[0m"
	elif [ $1 = "remove" ]; then
		print_msg "\e[1;$DEP_REMOVE\e[0m"
	elif [ $1 = "info" ]; then
		print_msg "\e[1m$DEP_INFO\e[0m"
	elif [ $1 = "" ]; then
		log_msg "function 'list_depends' from 'core-functions.sh' has started without arguments" "EMERG"
	fi	# Show help message
}

# Function for check priority of package
# If priority = system, then package doesn't
# can remove from Calmira GNU/Linux
## Priority:
# 'system' and 'user'
function check_priority() {
	print_msg ">> $CHECK_PRIORITY_START"
	log_msg "Function 'check_priority' from 'core-functions.sh': STARTING" "Notice"
	if [ -z $PRIORITY ]; then
		log_msg "Function 'check_priority' from 'core-functions.sh'. Priority variable NOT FOUND. WARNING" "Warning"
		echo -e "$PRIORITY_NOT_FOUND"
		echo -e -n "$PRIORITY_NOT_FOUND_ANSWER"
		dialog_msg
	else
		# If priority = system, then package is not
		# will remove
		print_dbg_msg "Priority variable is found"
		log_msg "Function 'check_priority' from 'core-functions.sh'. Priority variable is found." "OK"
		if [ $PRIORITY = "system" ]; then
			echo -e "\e[1;31m$SYSTEM_PRIORITY_REMOVE_BLOCKED\e[0m"
			log_msg "ERROR: Function 'check_priority' from 'core-functions.sh' returned a signal number 1. System priority; remove blocked!" "EMERG"
			exit 1
		else
			log_msg "Function 'check_priority' from 'core-functions.sh'. User priority." "OK"
			echo -e "\e[1m$PRIORITY_MSG:\e[0m	$PRIORITY\n\e[32m$SYSTEM_PRIORITY_REMOVE_OK\e[0m"
		fi
	fi
}

# Function for adding and removing package to/from blacklist
## Options:
# $1 - mode
# $2 - package
## Mode:
# add    - add to blacklist
# remove - remove from blacklist
# check  -
function blacklist_pkg() {
	OPTION=$1
	PKG=$2
	BLACK_FILE="$VARDIR/packages/$PKG/black"
	unset CODE
	
	print_msg " >> \e[1;31m$CHECK_INSTALLED\e[0m"
	if [ -f "$VARDIR/packages/$PKG" ]; then
		log_msg "Directory '$VARDIR/packages/$PKG' is found." "OK"
	else
		print_msg "\e[1;31m$ERROR $PACKAGE \e[0m\e[35m'$PKG'\e[0m\e[1;31m $PACKAGE_NOT_INSTALLED_OR_NAME_INCORRECTLY\e[0m"
		exit 1
	fi
	
	if [ $OPTION = "add" ]; then
		# Add in blacklist
		print_msg ">> \e[1;31m$BLACKLIST_ADD_PKG\e[0m"
		
		echo "BLACKLIST=true" > $BLACK_FILE
		
	elif [ $OPTION = "check" ]; then
		# Checking..
		print_msg ">> \e[1;31m$BLACKLIST_CHECK_PKG\e[0m"
		
		if [ -f $BLACK_FILE ]; then
			if grep 'BLACKLIST=true' $BLACK_FILE; then
				print_msg "\e[32m$CHECK_BLACKLIST_DONE\e[0m"
				CODE=done
			else
				print_msg "\e[32m$CHECK_BLACKLIST_FAIL\e[0m"
				CODE=fail
			fi
		else
			print_msg "\e[32m$CHECK_BLACKLIST_FAIL\e[0m"
			CODE=fail
		fi
		
	elif [ $OPTION = "info_check" ]; then
		# Check for 'info_pkg' function
		if [ -f $BLACK_FILE ]; then
			if grep 'BLACKLIST=true' $BLACK_FILE; then
				CODE=done
			else
				CODE=fail
			fi
		else
			CODE=fail
		fi
		
	elif [ $OPTION = "remove" ]; then
		# Remove package from blacklist
		print_msg ">> \e[1;31m$BLACKLIST_REMOVE_PKG\e[0m"
		
		if [ -f $BLACK_FILE ]; then
			print_msg "\e[1m$REMOVE_BLACK\e[0m"
			rm -f $BLACK_FILE
			
			if [ -f $BLACK_FILE ]; then
				print_msg "\e[31m$REMOVE_BLACK_FAIL\e[0m"
				CODE=fail
			else
				print_msg "\e[32m$REMOVE_BLACK_DONE\e[0m"
				CODE=done
			fi
		else
			print_msg "\e[32m$CHECK_BLACKLIST_FAIL\e[0m"
			CODE=fail
		fi
	fi
}

# Function for check md5-sums of package
## $1 - mode. If mode='noinstall'; then function
# will be search and unpack the package. If
# mode='install', then function doesn't will be
# search and anpack the package.
## $2 - package
function check_md() {
	PKG=$2
	
	if [ $1 = "noinstall" ]; then
		search_pkg $PKG
		unpack_pkg $PKG
	elif [ $1 = "install" ]; then
		print_dbg_msg "function 'check_md': install mode"
	else
		print_msg "$ERROR_NO_MODE_FOR_CHECK_MD"
		exit 1
	fi
	
	print_msg ">> \e[1;31m$CHECK_MD\e[0m"
	
	cd $PACKAGE_CACHE
	
	# Search md5 file
	if [ -f "md5" ]; then
		echo "success" > /dev/null
	else
		print_msg "$ERROR_SEARCH_MD_FILE"
		exit 1
	fi
	
	MD=$(cat md5)
	MD_PKG=$(md5sum ../$PKG > /tmp/cpkg_md5)
	
	if grep "$MD" "$MD_PKG"; then
		print_msg "$DONE"
	else
		print_msg "$FAIL"
	fi
}


# Function for search a package
# Only for install_pkg function
# $1 - package
function search_pkg() {
	PKG=$1
	print_msg ">> $SEARCH_PACKAGE"
	if test -f "$PKG"; then
		print_msg "\e[32m$SEARCH1\e[0m \e[35m$PKG\e[0m \e[32m$SEARCH2\e[0m \e[35m$GetPkgLocation\e[0m"
	else
		print_msg "\e[1;32m$ERROR $SEARCH1\e[0m \e[35m$PKG\e[0m \e[1;31m$DOESNT_EXISTS\e[0m"
		exit 0
	fi
}

# Function for unpack a package
# Only for remove package
# $1 - package
function unpack_pkg() {
	PKG=$1
	print_dbg_msg "Copy $PKG in /var/cache/cpkg/archives..."
	cp $PKG /var/cache/cpkg/archives/

	if test -f "/var/cache/cpkg/archives/$PKG"; then
		print_msg ">> $UNPACK1 \e[35m$PKG\e[0m\e[1;32m...\e[0m"
	else
		echo "$ERROR_UNPACK_PKG_NOT_FOUND"
		exit 1
	fi

	print_dbg_msg "Change dir..."
	cd /var/cache/cpkg/archives

	if [ -d "PKG" ]; then
		rm -rf PKG
	fi

	tar -xf $PKG

	if [ -d "PKG" ]; then
		print_msg "$UNPACK_COMPLETE1 \e[35m$PKG\e[0m $UNPACK_COMPLETE2"
	else
		print_msg "$UNPACK_FAIL1 \e[35m$PKG\e[0m $UNPACK_FAIL2!\n"
		exit 1
	fi
}

# Arch test
# Only for install_pkg function
function arch_test_pkg() {
	print_msg -n ">> $ARCH_TEST"
	if [ -z $ARCHITECTURE ]; then
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
	if [ -f "config.sh" ]; then
		source config.sh	# Read package information
	else
		error no_config
		exit 1
	fi

	arch_test_pkg
	list_depends install
	dialog_msg
	check_metadata

	if [ -f "preinst.sh" ]; then
		print_msg ">> $EXECUTE_PREINSTALL"
		chmod +x preinst.sh
		./preinst.sh
	fi

	if [ -f "postinst.sh" ]; then
		print_msg ">> $SETTING_UP_POSTINSTALL \n"
		chmod +x postinst.sh
		POSTINST=$DIR/postinst.sh
	fi

	if [ -f "port.sh" ]; then
		print_msg ">> $INSTALL_PORT"
		PORT=true
		chmod +x port.sh
		./port.sh
		cd $DIR
	fi
	
	# Если переменная INSTALL_ROOT установлена, то cpkg скопирует пакет в ту
	# директорию, которая установлена в переменнной.
	if [ -z "$INSTALL_ROOT" ]; then
		INSTALL_ROOT="/"
	else
		print_msg "\e[31m$INSTALL_OTHER_PREFIX_WARNING\e[0m"
	fi
	
	# Тестирование на наличие директории pkg, в которой находятся данные
	# пакета. И копирование в INSTALL_ROOT.
	if [ -d "pkg" ]; then
		print_msg ">> $COPY_PKG_DATA"
		cd pkg
		cp -r * $INSTALL_ROOT
	else
		if [[ $PORT = "true" ]]; then
			echo "$WARN_NO_PKG_DIR"
		else
			error no_pkg_data
			exit 1
		fi
	fi
	
	if [ $PORT = "true" ]; then
	    CONF_DIR=$DIR
	else
	    CONF_DIR=..
	fi

	print_msg ">> $SETTING_UP_PACKAGE\n"
	print_msg "$ADD_IN_DB"
	echo "$NAME $VERSION" >> $DATABASE/all_db

	if [ -d $DATABASE/packages/$NAME ]; then
		rm -rvf $DATABASE/packages/$NAME
	fi
	
	mkdir $DATABASE/packages/$NAME			# Creating a directory with information about the package
	cp $CONF_DIR/config.sh $DATABASE/packages/$NAME	# Copying config file in database

	for FILE in "changelog" "postinst.sh" "preinst.sh" "port.sh"; do
    		if [ -f "$CONF_DIR/$FILE" ]; then
			print_msg "$FILE: $FOUND_PKG"
	    		cp $CONF_DIR/$FILE $DATABASE/packages/$NAME/	# Copying changelog and other files in database
	    	fi
	done

	if [ -f $DIR/postinst.sh ]; then
		print_msg ">> $EXECUTE_POSTINSTALL"
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
	if [ -d "$DATABASE/packages/$PKG" ]; then
		log_msg "Search package $PKG: $PWD" "OK" && log_msg "Read package information" "Process"
		if [ -f "$DATABASE/packages/$PKG/config.sh" ]; then
			cd $DATABASE/packages/$PKG
			log_msg "Read package information:" "OK"
			source config.sh
		else
			log_msg "Read package information:
test '$PWD/config.sh' fail, because this config file (config.sh) doesn't find" "FAIL"
			print_msg "\e[1;31m$FILE\e[0m \e[35m$(pwd)/config.sh\e[0m \e[1;31m$DOESNT_EXISTS $ERROR \e[0m"
			exit 1
		fi
	else
		log_msg "Package $PKG isn't installed or it's name was entered incorrectly" "FAIL"
		print_msg "\e[1;31m$PACKAGE\e[0m \e[35m$PKG\e[0m \e[1;31m$PACKAGE_NOT_INSTALLED_OR_NAME_INCORRECTLY\e[0m"
		exit 1
	fi
	
	# Выполнение опциональных скриптов перед удалением пакета
	if [ -f "preremove.sh" ]; then
		chmod +x preremove.sh
		./preremove.sh
	fi

	log_msg "Remove package $PKG" "Process"
	check_priority
	blacklist_pkg check $PKG
	if [ $CODE = "done" ]; then
		print_msg "\e[1;31m$ERROR: $ERROR_NO_DELETE_BLACKLIST\e[0m"
		exit 1
	fi
	
	list_depends remove
	dialog_msg
	
	print_msg ">> $REMOVE_PKG \e[35m$PKG\e[0m\e[1;34m...\e[0m"

	# Remove package files
	rm -rf $FILES
	
	# Выполнение опционалных скриптов после удаления пакета
	if [ -f "postremove.sh" ]; then
		chmod +x postremove.sh
		./postremove.sh
	fi
	
	# Remove package from cpkg datatabase
	rm -rf $DATABASE/packages/$PKG

	if [ -d $DATABASE/packages/$PKG ]; then
		log_msg "Removed unsucessfull" "FAIL"
		print_msg "\e[31m$PACKAGE $PKG $REMOVE_PKG_FAIL \e[0m"
	else
		log_msg "Removed sucessfull!" "OK"
		print_msg "\e[32m$PACKAGE $PKG $REMOVE_PKG_OK \e[0m"
	fi
}

# Function for download a package
# For unpack_pkg function
# $1 - package
function download_pkg() {
	if grep "$1" $SOURCE; then
		print_msg "$FOUND_PKG '$1'"
	else
		print_msg "$PACKAGE '$1' $NOT_FOUND_PKG $SOURCE"
		exit 1
	fi
	
	PKG=$(grep "https://github.com/Linuxoid85/cpkg_packages/raw/$BRANCH/$RELEASE/{add,calm,core,network,security,utils}/$1" $SOURCE)	# FIXME - доработать алгоритм поиска нужного пакета в базе данных
	#alias wget='wget --no-check-certificate' # For Calmira 2021.1-2021.2
	print_msg ">> $DOWNLOAD_PKG \e[35m$PKG\e[0m\e[1;32m...\e[0m"
	wget $PKG

	print_dbg_msg -n "test package... "
	if [ -f "$1" ]; then
		print_dbg_msg "done"
	else
	    if [ -f "$1*.txz" ]; then
	        print_dbg_msg "done"
	    else
    		print_dbg_msg "FAIL"
	    	print_msg "\e[1;31m$ERROR: $PACKAGE '$1' $DOWNLOAD_PKG_FAIL \e[0m"
	    	exit 1
	    fi
	fi
}

# Function to read package info
# $1 - package
function package_info() {
	PKG=$1
	if [ -d "$DATABASE/packages/$PKG" ]; then
		cd $DATABASE/packages/$PKG
		if [ -f "config.sh" ]; then
			log_msg "Read package information:" "OK"
			source config.sh
		else
			log_msg "Read package information:
test '$PWD/config.sh' fail, because this config file (config.sh) doesn't find" "FAIL"
			print_msg "\e[1;31m$ERROR\e[0m: $PWD/config.sh $DOESNT_EXISTS"
			exit 1
		fi
	else
		log_msg "Print info about package $PKG:
test '/etc/cpkg/database/packages/$PKG' fail, because this directory doesn't find" "FAIL"
		print_msg "\e[1;31m$ERROR: $PACKAGE \e[10m\e[1;35m$PKG\e[0m\e[1;31m $DOESNT_INSTALLED \e[0m"
		exit 1
	fi

	echo -e "\e[1;32m$PACKAGE_INFO ($PKG):\e[0m
\e[1;34m$PACKAGE_NAME\e[0m		$NAME
\e[1;34m$PACKAGE_DESCRIPTION\e[0m	$DESCRIPTION
\e[1;34m$PACKAGE_MAINTAINER\e[0m	$MAINTAINER
\e[1;34m$PACKAGE_FILES\e[0m		$FILES"
	list_depends info
	
	unset CODE
	blacklist_pkg check_info
	if [ $CODE = "done" ]; then
		print_msg "\e[1m$PACKAGE_IN_BLACKLIST\e[0m"
	fi
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
		exit 1
	fi

	PKG=$1
	print_msg ">> \e[1;32m$SEARCH_PACKAGE\e[0m \e[35m$PKG\e[0m\e[1;32m...\e[0m"

	exa $DATABASE/packages |grep $PKG
}

# Function for clean cpkg files
## Variables
# $1 - option
## Options
# cpkg_clean cache  - clean the cpkg cache      (/var/cache/cpkg/archives/*)
# cpkg_clean source - clean the cpkg source dir (/usr/src/*)
# cpkg_clean log    - clean the cpkg log dir    (/var/log/cpkg/*)
function cpkg_clean() {
	print_msg "[ $GetDate ] \e[1;32m$CACHE_CLEAN\e[0m"
	log_msg "Clearing cpkg files (type $1)..." "Process"
	if [ $1 = "cache" ]; then
		rm -rf /var/cache/cpkg/archives/*
	elif [ $1 = "source" ]; then
		rm -rf /usr/src/*
	elif [ $1 = "log" ]; then
		rm -rf /var/log/cpkg/*
	fi
	log_msg "Clearing cpkg files (type $1)..." "OK"
}

# Function for edit sources
function edit_src() {
	if [ -f "/etc/cpkg/pkg.list" ]; then
		if [ -z $EDITOR ]; then
			print_msg "\e[1m$WARNING $VARIABLE \e[0m\e[35m\$EDITOR\e[0m\e[1m $DOESNT_EXISTS! \e[0m"
			if [ -f $(which vim) ]; then
				export EDITOR="$(which vim)"
				log_msg "Function 'edit_src' from file 'core-functions.sh'. Editor: vim" "Notice"
			else
				print_msg "\e[1;32m$ERROR $PACKAGE\e[0m \e[35mvim\e[0m\e[1;31m $DOESNT_INSTALLED! \e[0m"
				log_msg "Error: package 'vim' doesn't installed!" "EMERG"
				exit 1
			fi
		fi
		log_msg "Function 'edit_src' from file 'core-functions.sh'. Editor: $EDITOR" "Notice"
		$EDITOR /etc/cpkg/pkg.list
	else
		print_msg "\e[1;31m$ERROR $FILE\e[0m \e[35m/etc/cpkg/pkg.list\e[0m\e[1;31m$DOESNT_EXISTS\e[0m"
		log_msg "Error: /etc/cpkg/pkg.list doesn't exists!" "EMERG/FAIL/ERROR"
		exit 1
	fi
}

# Help
function help_pkg() {
	less /usr/share/doc/cpkg/USAGE
	print_msg "$HELP_CPKG $(GetCalmiraVersion)"
}

#check_file
