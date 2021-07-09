#!/bin/bash
#
# CPkg - an automated packaging tool for Calmira Linux
# Copyright (C) 2021 Michail Krasnov
#
# meta-functions.sh
#
# Project Page: http://github.com/Linuxoid85/cpkg
# Michail Krasnov <michail383krasnov@mail.ru>
#

# Function to get a copy of the package metadata
function GetCopyMetadata() {
	cat > metadata.old << "EOF"
Platform: LX4
Version:  1.0
Build date: 10.07.2021
Builder:  Linuxoid85
EOF
}

# Function for grep package metadata
function GrepMetadata() {
	cd metadata
	cat metadata.package
}

# Function to get a default metadata
function DefMetadata() {
	GetCopyMetadata
	cat metadata.old
}

# Function for get package metadata
function check_metadata() {
	print_msg ">> \e[32m$CHECK_METADATA\e[0m"
	if [ -f "metadata.xz" ]; then
		tar -xf metadata.xz
		if [ "$(GrepMetadata)" = "$(DefMetadata)" ]; then
			print_msg "--> \e[32m$CHECK_METADATA_OK\e[0m"
		else
			print_msg "--> \e[31m$CHECK_METADATA_FAIL\e[0m"
		fi
	else
		print_msg "$FAIL!"
	fi
}
