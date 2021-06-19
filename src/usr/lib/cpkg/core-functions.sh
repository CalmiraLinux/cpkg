#!/bin/bash
#
# CPkg - an automated packaging tool fog Calmira Linux
# Copyright (C) 2021 Michail Krasnov
#
# core-functions.sh
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# Project Page: http://github.com/Linuxoid85/cpkg
# Michail Krasnov <michail383krasnov@mail.ru>
#

#==================================================================#
#
# BASE VARIABLES
#
VERSION=1.0pa4
GetArch=$(uname -m)
GetDate=$(date)
GetPkgLocation=$(pwd)
PORT=false

#==================================================================#
#
# BASE FUNCTIONS
#

# Function for list depends
function list_depends() {
	echo -e "$DEPEND_LIST_INSTALL
\e[1m$REQUIRED_DEP\e[0m		$REQ_DEPS
\e[1m$TESTING_DEP\e[0m		$TEST_DEPS
\e[1m$OPTIONAL_DEP\e[0m		$OPT_DEPS
\e[1m$BEFORE_DEP\e[0m		$BEF_DEPS"
	echo -e "\n\e[1mУстановите или удалите эти зависимости перед тем, как устанавливать или удалять этот пакет!\e[0m\n"
}

# Function for search a package
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
		else
			print_msg "$MULTIARCH_DONE "
		fi
	else
		print_msg "$ARCH_DONE"
	fi
}

# Function to install a package
## VARIABLES:
# $1=PKG - package
function install_pkg() {
	PKG=$1
	cd /var/cache/cpkg/archives
	cd PKG
	DIR=$(pwd)
	if test -f "config.sh"; then
		source config.sh
	else
		error no_config
	fi

	arch_test_pkg
	
	list_depends
	read -p "$CONTINUE (y/n): " run
	if [ $run = "y" ]; then
		print_dbg_msg "Continue"
	else
		echo "$CANSELLED"
		exit 0
	fi

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
	echo "$NAME $VERSION $DESCRIPTION $FILES
" >> $DATABASE/all_db

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
function remove_pkg() {
	PKG=$1
	log_msg "Search package $PKG" "Process"
	if test -d "$DATABASE/packages/$PKG"; then
		log_msg "Search package $PKG: $PWD" "OK"
		log_msg "Read package information" "Process"
		if test -f "$DATABASE/packages/$PKG/config.sh"; then
			cd $DATABASE/packages/$PKG
			log_msg "Read package information:" "OK"
			source config.sh
		else
			log_msg "Read package information:" "FAIL"
			log_msg "dbg info:
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
	
	list_depends
	echo "Удалите эти пакеты перед/после удаления пакета $PKG!"
	
	print_msg "$REMOVE_PKG \e[35m$PKG\e[0m\e[1;34m...\e[0m"

	log_msg "Remove package data" "Process"
	rm -rf $FILES

	log_msg "Remove database" "Process"
	rm -rf $DATABASE/packages/$PKG
	if test -d $DATABASE/packages/$PKG; then
		log_msg "Removed unsucessfull" "OK"
		print_msg "\e[31m$PACKAGE $PKG $REMOVE_PKG_FAIL \e[0m"
	else
		log_msg "Removed sucessfull!" "FAIL"
		print_msg "\e[32m$PACKAGE $PKG $REMOVE_PKG_OK \e[0m"
	fi
}

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
function package_info() {
	PKG=$1
	if test -d "$DATABASE/packages/$PKG"; then
		cd $DATABASE/packages/$PKG
		log_msg "Read package information" "Process"
		if test -f "config.sh"; then
			log_msg "Read package information:" "OK"
			source config.sh
		else
			log_msg "Read package information:" "FAIL"
			log_msg "dbg info:
test '$PWD/config.sh' fail, because this config file (config.sh) doesn't find" "FAIL"
			print_msg "\e[1;31m$ERROR\e[0m: $PWD/config.sh $DOESNT_EXISTS"
			exit 0
		fi
	else
		log_msg "Print info about package $PKG" "FAIL"
		log_msg "dbg info:
test '/etc/cpkg/database/packages/$PKG' fail, because this directory doesn't find" "FAIL"
		print_msg "\e[1;31m$ERROR: $PACKAGE \e[10m\e[1;35m$PKG\e[0m\e[1;31m $DOESNT_INSTALLED \e[0m"
		exit 0
	fi

	echo -e "\e[1;32m$PACKAGE_INFO ($PKG):\e[0m"
	echo -e "\e[1;34m$PACKAGE_NAME\e[0m:             $NAME"
	echo -e "\e[1;34m$PACKAGE_DESCRIPTION\e[0m:      $DESCRIPTION"
	echo -e "\e[1;34m$PACKAGE_MAINTAINER\e[0m:       $MAINTAINER"
	echo -e "\e[1;34m$PACKAGE_FILES\e[0m:            $FILES"
	
	list_depends
}

# Function for a list packages in file system
function file_list() {
	cd $DATABASE/packages/
	if [ $1 = "--verbose=on" ]; then
		exa -l --tree
	else
		exa
	fi
}

# Function for search a package in file system (do not for install/remove package!!!)
function file_search() {
	PKG=$2
	print_msg ">> \e[1;32m$SEARCH_PACKAGE\e[0m \e[35m$PKG\e[0m\e[1;32m...\e[0m"
	log_msg "Search package $PKG" "Process"

	if test -f "$PKG"; then
		echo -e "\e[1;32m$SEARCH_RESULT\e[0m"
		if [[ $1 -eq "--verbose=on" ]]; then
			file_list --verbose=on $PKG
		fi

		if [[ $1 -eq "--verbose=off" ]]; then
			file_list --verbose=off |grep $PKG
		fi
	else
		log_msg "Search package $PKG" "FAIL"
		error no_pkg
		exit 0
	fi
}

# Function for clean cache
function cache_clean() {
	print_msg "[ $GetDate ] \e[1;32m$CACHE_CLEAN\e[0m"
	log_msg "Clearing cpkg cache..." "?"
	rm -rf /var/cache/cpkg/archives/*
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
