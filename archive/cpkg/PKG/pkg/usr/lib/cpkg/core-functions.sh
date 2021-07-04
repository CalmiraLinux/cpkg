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
GetCalmiraVersion=$DISTRIB_ID
GetPkgLocation=$(pwd)

#==================================================================#
#
# BASE FUNCTIONS
#

# Function for a print message on screen
function print_msg() {
	if [[ $QUIET = "true" ]]; then
		echo "$@" > /dev/null
	else
		echo -e $@
	fi
}

# Function for a print error message on screen
function error() {
	if [ $1 = "no_pkg" ]; then
		echo -e "\e[1;31mERROR\e[0m: package $PKG doesn't exists!"
	fi
	
	if [ $1 = "no_config" ]; then
		echo -e "\e[1;31mERROR\e[0m: configurition file doesn't exists!"
	fi
	
	if [ $1 = "no_pkg_data" ]; then
		echo -e "\e[1;31mERROR\e[0m: package data doesn't exists!"
	fi
	
	if [ $1 = "no_arch" ]; then
		echo -e "\e[1;31mERROR\e[0m: architecture $2 doesn't support on this host!"
	fi
	
	if [ $1 = "not_found_arch" ]; then
		echo -e "\e[1;31mERROR\e[0m: doesn't find ARCHITECTURE variable on config.sh!"
		
		read -p "Continue? (y/N): " run
		if [ $run = "N" ]; then
			exit 0
		fi
	fi
}

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
	cp $PKG /var/cache/cpkg/archives/

	if test -f "/var/cache/cpkg/archives/$PKG"; then
		print_msg ">> \e[1;32mUnpack package\e[0m \e[35m$PKG\e[0m\e[1;32m...\e[0m"
	else
		echo "Package $PKG not find."
		exit 0
	fi
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
		if [[ $ARCHITECTURE -ne $GetArch ]]; then
			if [[ $ARCHITECTURE -ne "multiarch" ]]; then
				error no_arch
			else
				print_msg -n "[ Multiarch DONE ] "
			fi
		else
			print_msg "[ Arch DONE ]"
		fi
	else
		print_msg "[ Arch FAIL ]"
		error not_found_arch
		if [[ $QUIET -eq "true" ]]; then
			exit 0
		else
			read -p "Exit cpkg? (y/N): " run
			if [[ $run -eq "y" ]]; then
				exit 0
			fi
		fi
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
		POSTINST=$(pwd)/postinst.sh
	fi
	
	if test -d "pkg"; then
		print_msg ">> \e[1;32mCopyng package data...\e[0m"
	else
		error no_pkg_data
		exit 0
	fi
	
	cd pkg
	cp -r * /
	
	print_msg ">> \e[1;32mSetting up a package...\e[0m\n"
	echo "$NAME $VERSION $DESCRIPTION $FILES
" >> /etc/cpkg/database/all_db
	mkdir /etc/cpkg/database/packages/$PKG			# Creating a directory with information about the package
	cp ../config.sh /etc/cpkg/database/packages/$PKG	# Copyng config file in database
	if test -f "../changelog"; then
		cp ../changelog /etc/cpkg/database/packages/$PKG	# Copyng changelog file in database
	fi

	print_msg ">> \e[32mExecute postinstall script\e[0m"
	if [ -d $POSTINST ]; then
		exit 0
	else
		bash $POSTINST
	fi
}

# Function for remove package
function remove_pkg() {
	PKG=$1
	if test -d "/etc/cpkg/database/packages/$PKG"; then
		if test -f "/etc/cpkg/database/packages/$PKG/config.sh"; then
			cd /etc/cpkg/database/packages/$PKG
			source config.sh
		else
			print_msg "\e[1;31mFile\e[0m \e[35m$(pwd)/config.sh\e[0m \e[1;31mdoesn't exists! ERROR! \e[0m"
			exit 0
		fi
	else
		print_msg "\e[1;31mPackage\e[0m \e[35m$PKG\e[0m \e[1;31mis not installed or it's name was entered incorrectly\e[0m"
		exit 0
	fi
	
	print_msg ">> \e[1;34mRemove package\e[0m \e[35m$PKG\e[0m\e[1;34m...\e[0m"
	rm -rf $FILES
	rm -rf /etc/cpkg/database/packages/$PKG
	if test -d /etc/cpkg/database/packages/$PKG; then
		print_msg "\e[31mPackage $PKG removed unsucessfully! \e[0m"
	else
		print_msg "\e[32mPackage $PKG removed sucessfully! \e[0m"
	fi
}

# Function to read package info
function package_info() {
	PKG=$2
	if test -d "/etc/cpkg/database/packages/$PKG"; then
		if test -f "/etc/cpkg/database/packages/$PKG/config.sh"; then
			cd /etc/cpkg/database/packages/$PKG
			source config.sh
		else
			print_msg "\e[1;31mFile\e[0m \e[1;35m$(pwd)/config.sh\e[0m \e[1;31mdoesn't exists! ERROR! \e[0m"
			exit 0
		fi
	else
		print_msg "\e[1;31mPackage\e[0m \e[1;35m$PKG\e[0m \e[1;31mis not installed or it's name was entered incorrectly\e[0m"
		exit 0
	fi
	
	echo -e "\e[1;32mPackage information ($PKG):\e[0m"
	echo -e "\e[1;34mPackage name\e[0m:             $NAME"
	echo -e "\e[1;34mPackage description\e[0m:      $DESCRIPTION"
	echo -e "\e[1;34mPackage maintainer\e[0m:       $MAINTAINER"
	echo -e "\e[1;34mPackage files\e[0m:            $FILES"
}

# Function for show package changelog
function package_changelog() {
	PKG=$2
	if test -d "/etc/cpkg/database/packages/$PKG"; then
		if test -f "/etc/cpkg/database/packages/$PKG/changelog"; then
			cd /etc/cpkg/database/packages/$PKG
		else
			print_msg "\e[1;31mMissing changelog.\e[0m"
			exit 0
		fi
	else
		print_msg "\e[1;31mPackage\e[0m \e[1;35m$PKG\e[0m \e[1;31mis not installed or it's name was entered incorrectly\e[0m"
		exit 0
	fi
	
	echo -e "\e[1;32mPackage changelog ($PKG):\e[0m"
	cat changelog
}

# Function for a list packages in file system
function file_list() {
	if [[ $1 -eq "--verbose=on" ]]; then
		ls -l $2
	fi
	
	if [[ $1 -eq "--verbose=off" ]]; then
		ls |grep "$2"
	fi
}

# Function for search a package in file system (do not for install/remove package!!!)
function file_search() {
	PKG=$2
	print_msg ">> \e[1;32mSearch package\e[0m \e[35m$PKG\e[0m\e[1;32m...\e[0m"
	if test -f "$PKG"; then
		echo -e "\e[1;32mSearch result:\e[0m"
		if [[ $1 -eq "--verbose=on" ]]; then
			file_list --verbose=on $PKG
		fi
		
		if [[ $1 -eq "--verbose=off" ]]; then
			file_list --verbose=off $PKG
		fi
	else
		error no_pkg
		exit 0
	fi
}

# Function for clean cache
function cache_clean() {
	print_msg "\e[1;32mClearing the cache...\e[0m"
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

---------------------------------------------------
\e[1;32mKEYS\e[0m
      --- none ---
---------------------------------------------------
(C) 2021 Michail Krasnov (aka Linuxoid85) \e[4m<michail383krasnov@mail.ru>\e[0m
For Calmira GNU/Linux $GetCalmiraVersion
"
}
