PATH=/sbin:/bin:/usr/sbin:/usr/bin


# This function write the header for the unmount shell scripts.
generate_sh_header() {
    echo "#!/bin/sh"
    echo "PATH=/sbin:/bin:/usr/sbin:/usr/bin"
}

# This function filter the file to ignore according to the regexp given in
# parameter.
filter_ignore() {
    local ignore_regexp
    
    ignore_regexp="$1"
    
    while read line; do
        if [ -z "$ignore_regexp" ] || [ $(printf "$line" | sed -e "s/'$//" | egrep "$ignore_regexp") = "" ]; then
            echo "$line"
        fi
    done
}

# This function create a shell script that will generate the structure of
# the folder $dir
generate_folder_structure() {
    local dir ignore_regexp
    
    dir="$1"
    ignore_regexp="$2"

    find $dir -type d -exec echo "mkdir -p '{}'" \; | filter_ignore $ignore_regexp

    find $dir -type d -exec stat --format "chown %u '{}'" {} \; | filter_ignore "$ignore_regexp"
    find $dir -type d -exec stat --format "chgrp %g '{}'" {} \; | filter_ignore "$ignore_regexp"
    find $dir -type d -exec stat --format "chmod %a '{}'" {} \; | filter_ignore "$ignore_regexp"
}

# This function create a shell script that will generate recursively empty
# file present in $dir
generate_file_structure() {
    local dir ignore_regexp
    dir="$1"
    ignore_regexp="$2"
    
    find $dir -type f -print | filter_ignore "$ignore_regexp" | while read file; do
        echo "touch '$file'"
    done

    find $dir -type f -exec stat --format "chown %u '{}'" {} \; | filter_ignore "$ignore_regexp"
    find $dir -type f -exec stat --format "chgrp %g '{}'" {} \; | filter_ignore "$ignore_regexp"
    find $dir -type f -exec stat --format "chmod %a '{}'" {} \; | filter_ignore "$ignore_regexp"
}

# This function create a shell script that will generate the file content in
# $dir. Using base64 allow to do other things in the mount script.
#
# Using the tail method doesn't allow this.
#    echo "tail -n +5 \"$0\" | tar xzf - C '$dir'"
#    tar czf - -C "$dir" --exclude="$exclude_pattern" $include_pattern
generate_file_content() {
    local dir include_pattern exclude_pattern

    dir="$1"
    include_pattern="$2"
    exclude_pattern="$3"

#    echo "base64 -d - <<EOF | tar xzf - -C '$dir'"
#   tar czf name_of_archive_file.tar.gz name_of_directory_to_tar
archive_name=$dir-$(date +%Y%m%d-%H%M%S)
    echo "tar xzf /var/folder2ram/compressed/$archive_name.tar.gz /var/folder2ram/$dir"
    tar czf /var/folder2ram/compressed/$archive_name.tar.gz /var/folder2ram/$dir --exclude="$exclude_pattern" $include_pattern # | base64
#    echo "EOF"
}

#function to clean the tmpfs run before or after something
clean_tmpfs() {
echo "rm -r $dir/*"
}

