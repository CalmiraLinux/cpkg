#!/bin/bash
#
# CPkg - an automated packaging tool fog Calmira Linux
# Cooyright (C) 2021 Michail Krasnov
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
# Project Page: http://github.com/Linuxoid85/c\
# Michail Krasnov (aka Linuxoid85) michail383krasnov@mail.ru
#

#==================================================================#
#
# LOAD SCRIPT CONFIGURATIONS
#

# CONF - configuration directory
# SOURCE - a mirror of Calmira
CONF=/etc/cpkg
SOURCE=$CONF/pkg.list
QUIET="true"	# turn off quiet mode (default)
DBG="false"	# turn off debug mode (default)
CLEAN="false"	# turn off cleaning cache (default)
if [[ $(whoami) -eq "root" ]]; then	# get log directory
	LOG_DIR=/var/log/
else
	LOG_DIR=~/.local/share/cpkg/log
	if test -d $LOG_DIR; then
		print_dbg_msg "done"
	else
		print_dbg_msg "retry..."
		mkdir -p $LOG_DIR
	fi
fi

print_dbg_msg "testing cpkg files... "
for FILE in "settings" "pkg.list"; do
	print_dbg_msg -n "testing $FILE... "
	if test -f "/etc/cpkg/$FILE"; then
		print_dbg_msg "done"
		source /etc/cpkg/$FILE
	else
		print_dbg_msg "FAIL"
	fi
done

for FUNC in other-functions.sh core-functions.sh; do
	print_dbg_msg -n "testing $FUNC... "
	if test -f "/usr/lib/cpkg/$FUNC"; then
		print_dbg_msg "done"
		source /usr/lib/cpkg/$FUNC		# Load the additional/other cpkg functions
	else
		print_dbg_msg "FAIL"
		echo -e "\e[1;31mERROR: source /usr/lib/cpkg/$FUNC doesn't found! \e[0m"
		exit 0
	fi
done

source /etc/lsb-release				# Load the system information

test_root
check_file

#==================================================================#
#
# COMMAND LINE PARSING
#

if [ $# -eq 0 ]; then
	help_pkg
fi

# Options
while [ -n "$1" ]; do
	case $1 in
		install|-i)
			echo -e "[ $(date) ] [ Install the package $2 ]\n" >> $LOG_DIR/history.log

			# Clean package cache
			if [[ $CLEAN -eq "true" ]]; then
				cache_clean
			fi

			unpack_pkg $2	# Unpack the package
			cd /var/cache/cpkg/archives
			install_pkg $2
		;;

		remove|-r)
			echo -e "[ $(date) ] [ Remove the package $2 ]\n" >> $LOG_DIR/history.log
			remove_pkg $2	# Remove
		;;

		download|-d)
			# Clean package cache
			if [[ $CLEAN -eq "true" ]]; then
				cache_clean
			fi

			echo -e "[ $(date) ] [ Download the package $2 ]\n" >> $LOG_DIR/history.log
			cd /var/cache/cpkg/archives
			download_pkg $2
		;;

		list|-l)
			echo -e "[ $(date) ] [ List packages ]\n" >> $LOG_DIR/history.log
			if [ $2 = "--verbose" ]; then
				file_list --verbose=on
			else
				file_list --verbose=off
			fi
		;;

		search|-s)
			echo -e "[ $(date) ] [ Search install package ]\n" >> $LOG_DIR/history.log
			file_list --verbose=on |grep $2
		;;

		info|-I)
			echo -e "[ $(date) ] [ Information about $2 ]\n" >> $LOG_DIR/history.log
			package_info $2
		;;

		clean|-C)
			echo -e "[ $(date) ] [ Clean cache ]\n" >> $LOG_DIR/history.log
			cache_clean
		;;

		help)
			help_pkg
		;;

		--quiet=true)	# Turn on quiet mode
			QUIET="true"
		;;

		--debug-mode)	# Turn on a debug mode
			DBG="true"
		;;


		### INSTALL OPTIONS ###

		--clean|-c)	# Clean cache before installation
			CLEAN="true"
		;;

		*)
			echo -e "[ $(date) ] [ Uknown option(s) '$@' ]\n" >> $LOG_DIR/history.log
			echo -e "\e[1;31mERROR: option(s) '$@' doesn't exists! \e[0m\n"
			help_pkg
		;;
	esac

	exit 0
done
			
