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
VERSION=1.0
GetArch=$(uname -m)
GetDate=$(date)
GetCalmiraVersion=$DISTRIB_ID
GetPkgLocation=$(pwd)

#==================================================================#
#
# BASE FUNCTIONS
#

# Function for search a package
function search_pkg() {
	PKG=$1
	print_msg ">> \e[1;32mSearch package\e[0m \e[35m$PKG\e[0m\e[1;32m...\e[0m"
	if test -f "$PKG"; then
		print_msg "\e[1;32mPackage\e[0m \e[35m$PKG\e[0m \e[1;32mis found of \e[0m\e[35m$GetPkgLocation\e[0m"
	else
		error no_pkg
		exit 0
	fi
}

# Function for unpack a package
function unpack_pkg() {
	PKG=$1
	search_pkg $PKG
	print_dbg_msg "Copy $PKG in /var/cache/cpkg/archives..."
	cp $PKG /var/cache/cpkg/archives/

	if test -f "/var/cache/cpkg/archives/$PKG"; then
		print_msg ">> \e[1;32mUnpack package\e[0m \e[35m$PKG\e[0m\e[1;32m...\e[0m"
	else
		echo "Package $PKG not find."
		exit 0
	fi

	print_dbg_msg "Change dir..."
	cd /var/cache/cpkg/archives

	if test -d "PKG"; then
		rm -rf PKG
	fi

	tar -xf $PKG

	if test -d "PKG"; then
		print_msg "\e[1;32mPackage\e[0m \e[35m$PKG\e[0m \e[1;32mare unpacked\e[0m\n"
	else
		print_msg "Package $PKG aren't unpacked!\n"
		exit 0
	fi
}

# Arch test
function arch_test_pkg() {
	print_msg -n ">> \e[1;32mArchitecture test...\e[0m"
	if [ -d $ARCHITECTURE ]; then
		print_msg " [ Arch variable not found ]"
	fi

	if [[ $ARCHITECTURE -ne $GetArch ]]; then
		if [[ $ARCHITECTURE -ne "multiarch" ]]; then
			error no_arch
		else
			print_msg "[ Multiarch DONE ] "
		fi
	else
		print_msg "[ Arch DONE ]"
	fi
}

# Function to install a package
## VARIABLES:
# $1=PKG - package
function install_pkg() {
	PKG=$1
	cd /var/cache/cpkg/archives
	cd PKG
	if test -f "config.sh"; then
		source config.sh
	else
		error no_config
	fi

	arch_test_pkg

	if test -f "preinst.sh"; then
		print_msg ">> \e[32mExecute preinstall script\e[0m"
		chmod +x preinst.sh
		bash preinst.sh
	fi

	if test -f "postinst.sh"; then
		print_msg ">> \e[32mSetting up postinstall script\e[0m\n"
		DIR=$(pwd)
		chmod +x postinst.sh
	fi

	if test -f "port.sh"; then
		print_msg ">> \e[32mInstall port package...\e[0m"
		PORT=true
		./port.sh
		cd $DIR
	fi

	if test -d "pkg"; then
		print_msg ">> \e[1;32mCopyng package data...\e[0m"
		cd pkg
		cp -r * /
	else
		if [[ $PORT = "true" ]]; then
			echo "WARN: package dir 'pkg' doesn't found."
		else
			error no_pkg_data
			exit 0
		fi
	fi

	print_msg ">> \e[1;32mSetting up a package...\e[0m\n"
	echo "$NAME $VERSION $DESCRIPTION $FILES
" >> /etc/cpkg/database/all_db
	mkdir /etc/cpkg/database/packages/$NAME			# Creating a directory with information about the package
	cp ../config.sh /etc/cpkg/database/packages/$NAME	# Copyng config file in database
	if test -f "../changelog"; then
		cp ../changelog /etc/cpkg/database/packages/$NAME	# Copyng changelog file in database
	fi

	if [ -f $POSTINST ]; then
		print_msg ">> \e[32mExecute postinstall script\e[0m"
		cd $DIR
		./postinst.sh
	else
		exit 0
	fi
}

# Function for remove package
function remove_pkg() {
	PKG=$1
	log_msg "Search package $PKG" "Process"
	if test -d "/etc/cpkg/database/packages/$PKG"; then
		log_msg "Search package $PKG: $PWD" "OK"
		log_msg "Read package information" "Process"
		if test -f "/etc/cpkg/database/packages/$PKG/config.sh"; then
			cd /etc/cpkg/database/packages/$PKG
			log_msg "Read package information:" "OK"
			source config.sh
		else
			log_msg "Read package information:" "FAIL"
			log_msg "dbg info:
test '$PWD/config.sh' fail, because this config file (config.sh) doesn't find" "FAIL"
			print_msg "\e[1;31mFile\e[0m \e[35m$(pwd)/config.sh\e[0m \e[1;31mdoesn't exists! ERROR! \e[0m"
			exit 0
		fi
	else
		log_msg "Package $PKG isn't installed or it's name was entered incorrectly" "FAIL"
		print_msg "\e[1;31mPackage\e[0m \e[35m$PKG\e[0m \e[1;31mis not installed or it's name was entered incorrectly\e[0m"
		exit 0
	fi

	log_msg "Remove package $PKG" "Process"
	print_msg ">> \e[1;34mRemove package\e[0m \e[35m$PKG\e[0m\e[1;34m...\e[0m"

	log_msg "Remove package data" "Process"
	rm -rf $FILES

	log_msg "Remove database" "Process"
	rm -rf /etc/cpkg/database/packages/$PKG
	if test -d /etc/cpkg/database/packages/$PKG; then
		log_msg "Removed sucessfull" "OK"
		print_msg "\e[31mPackage $PKG removed unsucessfully! \e[0m"
	else
		log_msg "Removed unsucessfull!" "FAIL"
		print_msg "\e[32mPackage $PKG removed sucessfully! \e[0m"
	fi
}

# Update package
function update_pkg() {
	PKG=$1
	cd $CACHE
	print_msg ">> \e[32mDownload $PKG...\e[0m"
	print_dbg_msg "Change dir ($CACHE)
Download package $PKG..."
	log_msg "Downloading package $PKG" "Process"
	wget $REPO/$PKG > /var/log/cpkg.log
	if test -f $PKG; then
		log_msg "Downloading ($PKG) complete" "OK"
	else
		log_msg "Downloading ($PKG) fail!" "FAIL"
		error no_pkg
		exit 0
	fi
	install_pkg $PKG
}

function download_pkg() {
	if grep "$1" $SOURCE; then
		print_msg "Found package '$1'"
	else
		print_msg "Package '$1' doesn't fing of $SOURCE"
		exit 0
	fi

	print_dbg_msg "download package..."
	wget $1 -o $LOG_DIR/download.log

	print_dbg_msg -n "test package... "
	if test -f "$1.txz"; then
		print_dbg_msg "done"
	else
		print_dbg_msg "FAIL"
		print_msg "\e[1;31mERROR: package '$1' was downloaded unsuccesfully!\e[0m"
		exit 0
	fi
}

# Function to read package info
function package_info() {
	PKG=$1
	if test -d "/etc/cpkg/database/packages/$PKG"; then
		cd /etc/cpkg/database/packages/$PKG
		log_msg "Read package information" "Process"
		if test -f "config.sh"; then
			log_msg "Read package information:" "OK"
			source config.sh
		else
			log_msg "Read package information:" "FAIL"
			log_msg "dbg info:
test '$PWD/config.sh' fail, because this config file (config.sh) doesn't find" "FAIL"
			print_msg "\e[1;31mERROR\e[0m: $PWD/config.sh doesn't find!"
			exit 0
		fi
	else
		log_msg "Print info about package $PKG" "FAIL"
		log_msg "dbg info:
test '/etc/cpkg/database/packages/$PKG' fail, because this directory doesn't find" "FAIL"
		print_msg "\e[1;31mERROR: package \e[10m\e[1;35m$PKG\e[0m\e[1;31m doesn't installed! \e[0m"
		exit 0
	fi

	echo -e "\e[1;32mPackage information ($PKG):\e[0m"
	echo -e "\e[1;34mPackage name\e[0m:             $NAME"
	echo -e "\e[1;34mPackage description\e[0m:      $DESCRIPTION"
	echo -e "\e[1;34mPackage maintainer\e[0m:       $MAINTAINER"
	echo -e "\e[1;34mPackage files\e[0m:            $FILES"
}

# Function for a list packages in file system
function file_list() {
	cd /etc/cpkg/database/packages/
	if [[ $1 -eq "--verbose=on" ]]; then
		ls -l
	fi

	if [[ $1 -eq "--verbose=off" ]]; then
		ls
	fi
}

# Function for search a package in file system (do not for install/remove package!!!)
function file_search() {
	PKG=$2
	print_msg ">> \e[1;32mSearch package\e[0m \e[35m$PKG\e[0m\e[1;32m...\e[0m"; log_msg "Search package $PKG" "Process"
	if test -f "$PKG"; then
		echo -e "\e[1;32mSearch result:\e[0m"
		if [[ $1 -eq "--verbose=on" ]]; then
			file_list --verbose=on $PKG
		fi

		if [[ $1 -eq "--verbose=off" ]]; then
			file_list --verbose=off $PKG
		fi
	else
		log_msg "Search package $PKG" "FAIL"
		error no_pkg
		exit 0
	fi
}

# Function for clean cache
function cache_clean() {
	print_msg "[ $GetDate ] \e[1;32mClearing the cache...\e[0m"
	log_msg "Clearing cpkg cache..." "?"
	rm -rf /var/cache/cpkg/archives/*
}

# Help
function help_pkg() {
	echo -e "\e[1;35mcpkg - Calmira Package Manager\e1[0m
\e[1mVersion:\e[0m        $VERSION
\e[1mDistro version:\e[0m $GetCalmiraVersion

\e[1;32mBASE FUNCTIONS\e[0m
\e[1minstall\e[0m        - install package
\e[1mremove\e[0m         - remove package
\e[1mlist\e[0m           - list all packages
\e[1msearch\e[0m         - search a package
\e[1mdownload\e[0m       - download a package

---------------------------------------------------
\e[1;32mKEYS\e[0m
\e[1m-i\e[0m             - install package
\e[1m-r\e[0m             - remove package
\e[1m-I\e[0m             - information about package
\e[1m-s\e[0m             - search install package
\e[1m--quiet=true\e[0m   - quiet mode
\e[1m--debug-mode\e[0m   - debug mode
---------------------------------------------------
(C) 2021 Michail Krasnov \e[4m<michail383krasnov@mail.ru>\e[0m
For Calmira GNU/Linux $GetCalmiraVersion
"
}
