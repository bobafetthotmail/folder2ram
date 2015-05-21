# author:
#
#     Philippe Le Brouster <plb@nebkha.net>
#
# Copyright:
#
#     Copyright (C) 2009 - 2010 Philippe Le Brouster <plb@nebkha.net>
#
# License:
#
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     This package is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# On Debian systems, the complete text of the GNU General
# Public License version 3 can be found in `/usr/share/common-licenses/GPL-3'.

FS2RAM_ETCFILE=/etc/fs2ram/fs2ram.conf
FS2RAM_UNMOUNT_SCRIPT_ETCDIR=/etc/fs2ram/unmount-scripts
FS2RAM_UNMOUNT_SCRIPT_DIR=/lib/fs2ram/unmount-scripts
FS2RAM_MOUNT_SCRIPT_VARDIR=/var/lib/fs2ram/mount-scripts


log_info_message() {
    echo $*
}

log_warning_message() {
    echo $*
}

log_error_message() {
    echo $*
}

is_mounted() {
    local dir
    dir=$1
    mountpoint -q "$dir" > /dev/null
}

is_tmpfs() {
   local dir
   dir=$1
   [ "$(stat --format "%T" -f $dir)" = "tmpfs" ];
}

do_mountpoint() {
    local mtpt action force quiet action_done
    mtpt="$1"
    action="$2"
    force="$3"
    quiet="$4"

    if [ -f "$FS2RAM_ETCFILE" ]; then

        # the fs2ram config file use almost the same syntax than /etc/fstab.
        # There is two more columns more called 'script' and 'script_opts'
        while read tab_dev tab_mountpoint tab_script tab_script_opts tab_type tab_opts
        do
            case "$tab_dev" in (""|\#*) continue;; esac
            case "$mtpt" in
                "") : ;;
                "$tab_mountpoint") : ;;
                *) continue ;;
            esac
            case "$tab_type" in
                # Manage only tmpfs
                tmpfs) : ;;

                *)
                    log_warning_message "fs2ram: $tab_type type for $tab_mountpoint unsupported"
                    continue
                    ;;
            esac
            case "$tab_script" in
                -) tab_script="" ;;
            esac
            case "$tab_script_opts" in
                -) tab_script_opts="" ;;
            esac

            case "$action" in
                mount-only)
                    mount_mountpoint "$tab_dev" "$tab_mountpoint" "$tab_type" "$tab_opts" "$quiet"
                    ;;

                unmount-only)
                    unmount_mountpoint "$tab_dev" "$tab_mountpoint" "$tab_type" "$tab_opts" "$quiet"
                    ;;

                execute-unmount-script)
                    if [ -n "$tab_script" ]; then
                        execute_unmount_script "$tab_mountpoint" "$tab_script" "$tab_script_opts" "$quiet"
                    fi
                    ;;

                execute-mount-script)
                    if [ -n "$tab_script" ]; then
                        execute_mount_script "$tab_mountpoint" "$tab_script" "$tab_script_opts" "$quiet"
                    fi
                    ;;

                mount)
                    if mount_mountpoint "$tab_dev" "$tab_mountpoint" "$tab_type" "$tab_opts" "$quiet" || [ "$force" = "true" ]; then
                        if [ -n "$tab_script" ]; then
                            execute_mount_script "$tab_mountpoint" "$tab_script" "$tab_script_opts" "$quiet"
                        fi
                    fi
                    ;;

                unmount)
                    if [ -z "$tab_script" ] || execute_unmount_script "$tab_mountpoint" "$tab_script" "$tab_script_opts" "$quiet" || [ "$force" = "true" ]; then
                        unmount_mountpoint "$tab_dev" "$tab_mountpoint" "$tab_type" "$tab_opts" "$quiet"
                    fi
                    ;;

                *)
                    log_warning_message "fs2ram : the action $action is not defined"
                    ;;

            esac

            action_done=true

        done < $FS2RAM_ETCFILE
    fi

    [ "$action_done" != "true" ] && [ -n "$mtpt" ] && log_warning_message "fs2ram: can't find $mtpt in $FS2RAM_ETCFILE"

    return 0
}

# mount
mount_mountpoint() {
    local dev mtpt type opts quiet
    dev=$1
    mtpt=$2
    type=$3
    opts=$4
    quiet=$5

    if  is_mounted "$mtpt"; then
        # Skip if already mounted
        if is_tmpfs "$mtpt"; then
            log_warning_message "fs2ram: $mtpt is already mounted with tmpfs"
        else
            log_warning_message "fs2ram: $mtpt is already mounted with another type than tmpfs"
        fi
        return 1
    else
        [ "$quiet" != "true" ] && log_info_message "fs2ram: mounting $mtpt ($type)."
        if ! mount -t "$type" -o "$opts" "$dev" "$mtpt"; then
            log_error_message "fs2ram: Unable to mount $mtpt."
            return 1
        fi
    fi
    return 0
}

execute_unmount_script() {
    local mtpt script script_opts quiet tmp_mount_script mount_script unmount_script
    mtpt=$1
    script=$2
    script_opts=$3
    quiet=$4

    unmount_script=$(get_unmount_script "$script")
    mount_script=$(get_mount_script "$mtpt")

    if [ -n "$script" ] && [ -z "$unmount_script" ]; then
        # Unmount script not found.
        log_warning_message "fs2ram: the unmount script '$script' was not found either in '$FS2RAM_UNMOUNT_SCRIPT_ETCDIR' or in '$FS2RAM_UNMOUNT_SCRIPT_DIR'"
        return 0
    fi

    if [ ! -x "$unmount_script" ]; then
        # Unmount script not executable
        log_warning_message "fs2ram: '$unmount_script' is not executable."
        return 0
    fi

    tmp_mount_script=$(get_tmp_mount_script "$mtpt")
    if [ ! -x "$tmp_mount_script" ]; then
        log_error_message "fs2ram: unable to create tempory mount script file for the mountpoint '$mtpt'"
        [ -e "$tmp_mount_script" ] && rm -f "$tmp_mount_script"
        return 1
    fi

    [ "$quiet" != "true" ] && log_info_message "fs2ram: executing the unmount script for the mountpoint '$mtpt'."
    if ! $unmount_script $mtpt $script_opts > "$tmp_mount_script"; then
        log_error_message "fs2ram: the unmount script '$unmount_script $script_opts' for the mountpoint '$mtpt' failed."
        [ -e "$tmp_mount_script" ] && rm -f "$tmp_mount_script"
        return 1
    fi
    mv -f "$tmp_mount_script" "$mount_script"

    return 0
}

execute_mount_script() {
    local mtpt mount_script quiet
    mtpt=$1
    quiet=$4
    mount_script=$(get_mount_script "$mtpt")

    if [ ! -x "$mount_script" ]; then
        log_error_message "fs2ram: the mount script '$mount_script' for the mountpoint '$mtpt' is either not found or not executable. Aborting."
        return 1
    fi

    [ "$quiet" != "true" ] && log_info_message "fs2ram: executing the mount script for the mountpoint '$mtpt'."
    if ! $mount_script; then
        log_error_message "fs2ram: the mount script for the mountpount '$mtpt' failed."
        return 1
    fi
}

# unmount
unmount_mountpoint() {
    local dev mtpt type opts quiet
    dev=$1
    mtpt=$2
    type=$3
    opts=$4
    quiet=$5

    if ! is_mounted "$mtpt"; then
        # Skip if not mounted
        log_warning_message "Mountpoint $mtpt is not mounted."
        return 1
    fi

    [ "$quiet" != "true" ] && log_info_message "fs2ram: unmounting $tab_mountpoint ($type)."
    if ! umount "$mtpt"; then
        log_error_message "fs2ram: Unable to unmount $mtpt."
        return 1
    fi
    return 0
}

# Retrieve the unmount script path for the given scrip filename
get_unmount_script() {
    local script
    script=$1

    # In case of no script given
    [ -z "$script" ] && return

    # Check if it is an absolute script path
    if [ -x "/$script" ]; then
        echo "/$script"
    
    # Check if it is a user-defined script in /etc
    elif [ -x "$FS2RAM_UNMOUNT_SCRIPT_ETCDIR/$script" ]; then
        echo "$FS2RAM_UNMOUNT_SCRIPT_ETCDIR/$script"
    
    # Check if it is a default unmount script
    elif [ -x "$FS2RAM_UNMOUNT_SCRIPT_DIR/$script" ]; then
        echo "$FS2RAM_UNMOUNT_SCRIPT_DIR/$script"
    fi
}

# Retrieve the mount script path for a given mountpoint
get_mount_script() {
    local mtpt
    mtpt=$(echo "$1" | sed -e "s'%'%%'g;s'/'%'g")
    echo "$FS2RAM_MOUNT_SCRIPT_VARDIR/$mtpt"
}
get_tmp_mount_script() {
    local mtpt
    mtpt=$(echo "$1" | sed -e "s'%'%%'g;s'/'%'g")
    echo "$(tempfile -d "$FS2RAM_MOUNT_SCRIPT_VARDIR" -p "$mtpt" -m 0700)"
}

