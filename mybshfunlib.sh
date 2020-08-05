#!/usr/bin/env bash
# Script Name : mybshfunlib
# Description : Collection of various functions.
# Author      : XXXXXX
# Email       : xxxxx@gmail.com


###################################################################################################
# Checks if file exists.
# Arguments:
#   $1: Filename
# Return:
#   2, if file does not exist.
###################################################################################################
_is_file() {
	if [[ ! -f "$1" ]] ; then
		echo "I/O ERROR: File '$1' does not exist."
		exit 2
	fi
}

###################################################################################################
# Change case to lower.
# Arguments:
#   $1: Variable content.
# Return:
#   echo content of $1 to lower case.
###################################################################################################
_to_lower() {
	local input="$1"
	local output="$(echo $1 | tr [A-Z] [a-z])"
	echo "${output}"
}

###################################################################################################
# Change case to upper.
# Arguments:
#   $1: Variable content.
# Return:
#   echo content of $1 to upper case.
###################################################################################################
_to_upper() {
	local input="$1"
	local output="$(echo $1 | tr [a-z] [A-Z])"
	echo "${output}"
}

###################################################################################################
# Change case to pascal.
# Arguments:
#   $1: Variable content.
# Return:
#   echo content of $1 to pascal case.
###################################################################################################
_to_pascal() {
	local input="$1"
	local to_lower="$(_to_lower "$1")"
	local output="$(echo ${to_lower} \
		| sed 's/\([a-z]\)\([a-zA-Z0-9]*\)/\u\1\2/g')"
	echo "${output}"
}

###################################################################################################
# Draws a line based on use selected character.
# Arguments:
#   $1: Symbol type.
#   $2: (optional) length to print.
# Return:
#   echo repeated characters by specified length.
###################################################################################################
_draw_line() {
	local symbol="$1"
	local length=${2:-$(tput cols)}
	printf "%${length}s\n"|tr " " "${symbol}"
}

###################################################################################################
# Checks if the package is installed.
# Arguments:
#   $1: Command name.
# Return:
#   echo command installed status.
###################################################################################################
_is_cmd() {
	local cmd_name="$1"
	if [[ ! $(command -v "${cmd_name}") ]]  ; then
		echo "Error: '${cmd_name}' not installed. Try again after installing it."
		exit 1
	fi
}
