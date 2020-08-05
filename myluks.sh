#!/usr/bin/env bash
# Script Name : myluks.sh
# Description : Provides various functions on encrypted directory.
# Args        : Refer HELP section for usage.
# Author      : XXXXXX
# Email       : xxxx@xxxx.com

source mybshfunlib.sh

# Bash shell options
# ------------------
set -o nounset # Exit when script tries to use undeclared variables.
set -o errexit # Exit script when command fails. Add '|| true' to allow fail.

# Constant variables
# ------------------
readonly CURRENT_DIR="$PWD"
readonly SCRIPT_NAME=$(basename $0)
readonly DDIR="/docs"
readonly PDIR="/pass"
readonly DDEV="/dev/sda4"
readonly PDEV="/dev/sda8"
readonly DMAP="DMDOCS"
readonly PMAP="DMPASS"
readonly DUSR="neon"
readonly PUSR="neon"

# Check if necessary commands are installed
# -----------------------------------------
_is_cmd "cryptsetup"
_is_cmd "fuser"
_is_cmd "install"

###################################################################################################
# Delete temp files from the directory where the script has been executed.
# Globals/Constants:
#   CURRENT_DIR
###################################################################################################
_trap_cleanup() {
	echo "Oops! $(basename $(0)) ($$) has terminated."
	echo "Cleaning temporary files..."
	find "${CURRENT_DIR}" -type f -name "tmp_myluks.sh_*.mp4" -print -delete
	echo "Done"
	exit 2
}
trap '_trap_cleanup' SIGHUP SIGINT SIGQUIT SIGQUIT SIGTERM

###################################################################################################
# Show help.
###################################################################################################
_show_help() {
cat <<HELP
Usage: 
 ${SCRIPT_NAME} [option]... <argument>

Options:
 -h        Show this help.
 -m <dir>  Mount LUKS partition.
           d -> docs
           p -> pass
HELP
}

###################################################################################################
# Mounts the LUKS partition into a directory. Creates directory if necessary.
# Globals/Constants:
#   DDEV, DDIR, DMAP, DUSR, PDEV, PDIR, PMAP, PUSR
###################################################################################################
_mount_dir() {

	# Check $1 positional argument. If para is other than 'd' or 'p', exit script.
	if [[ "$1" = "d" ]] ; then
		local dev_name="${DDEV}"
		local dir_name="${DDIR}"
		local map_name="${DMAP}"
		local usr_name="${DUSR}"
	elif [[ "$1" = "p" ]] ; then
		local dev_name="${PDEV}"
		local dir_name="${PDIR}"
		local map_name="${PMAP}"
		local usr_name="${PUSR}"
	else
		echo "Couldn't find mount code... exiting."
		exit 1
	fi

	# Check if mount directory exist. If not, create it.
	if [[ ! -d "${dir_name}" ]] ; then
		echo "Directory '${dir_name}' does not exist. Creating it..."
		sudo install -o "${usr_name}" -g "${usr_name}" -m 0770 -d "${dir_name}"
		if [[ $? -eq 0 ]] ; then
			echo "...Done." 
		else 
			echo "Error: Couldn't create directory ${dir_name}."
			exit 1
		fi
	fi

	# Mount LUKS partition
	if [[ $(findmnt -M "${dir_name}") ]] ; then
		echo "${dir_name} already mounted with ${dev_name}. Doing nothing."
		exit 1
	else
		echo "Mounting ${dev_name} into ${dir_name} ..."
		sudo cryptsetup open --type luks2 "${dev_name}" "${map_name}"
		sudo mount "/dev/mapper/${map_name}" "${dir_name}"
		if [[ $? -eq 0 ]] ; then
			echo "${dir_name} mounted. Ready to use."
		else
			echo "Error: Couldn't mount ${dir_name}... Exiting."
			exit 1
		fi
	fi



}

###################################################################################################
# Unmounts the LUKS partition from a directory.
# Globals/Constants:
#   DDEV, DDIR, DMAP, DUSR, PDEV, PDIR, PMAP, PUSR
###################################################################################################
_umount_dir() {

	# Check $1 positional argument. If para is other than 'd' or 'p', exit script.
	if [[ "$1" = "d" ]] ; then
		local dev_name="${DDEV}"
		local dir_name="${DDIR}"
		local map_name="${DMAP}"
		local usr_name="${DUSR}"
	elif [[ "$1" = "p" ]] ; then
		local dev_name="${PDEV}"
		local dir_name="${PDIR}"
		local map_name="${PMAP}"
		local usr_name="${PUSR}"
	else
		echo "Couldn't find mount code... exiting."
		exit 1
	fi

	# Check if are unmounting from source directory.
	if [[ "$(echo $PWD)" = "${dir_name}" ]] ; then
		echo "You are trying to unmount ${dir_name} from within. Please change directory first, then try again."
		exit 1
	fi

	# Check if directory is already mounted.
	if [[ $(findmnt -M "${dir_name}") ]] ; then
		echo "Unmounting ${dir_name}..."

		# Check if the mount directory is busy
		if [[ $(sudo fuser --mount "${dir_name}") ]] ; then
			sudo fuser -kvi "${dir_name}"
		fi
		
		# Lazy umount the directory, then, if successful, close LUKS
		sudo umount -l "${dir_name}"
		if [[ $? -eq 0 ]] ; then
			sudo cryptsetup close "${map_name}"
			if [[ $? -eq 0 ]] ; then
				echo ""${dir_name}" unmounted.. Done."
			fi
		fi
	else
		echo "${dir_name} not mounted. Doing nothing."
	fi
}


#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#%% Main Function
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
while getopts ":hm:u:" opt ; do
	#echo "Processing $opt : OPTIND is $OPTIND"
	case $opt in
		h) _show_help ;;
		m) _mount_dir "$OPTARG" ;;
		u) _umount_dir "$OPTARG" ;;
		:) echo "Error: -$OPTARG requires an argument" ; exit 1 ;;
		?) echo "Error: unknown option -$OPTARG" ; exit 1 ;;
	esac
done
