# folder2ram

a fork of fs2ram that aims to be simpler, faster, safer. 

Designed to be controlled manually for easy integration with other projects

debian source package only as fs2ram is a debian package and I stay mostly in debian environments.

for now I'm focusing on wheezy.

NOTDONE:
translations in /debian/po weren't changed.

DONE:

--check what is happening with """ inside /home/alby/folder2ram/lib/folder2ram/unmount-scripts/common.sh

--modified to implement the script written by mcortese in 2010
in this webpage https://www.debian-administration.org/article/661/A_transient_/var/log
webpage saved and available in docs folder
much better and safer than fs2ram's own system, as it runs a bind mount before mounting the tmpfs.
Added check so that if it fails it will safely unmount stuff. Won't leave it borked.

-fixed two bugs reported in fs2ram bugtracker (can now mount folders already inside tmpfs, moved examples in another folder) 

--weird folder compression is removed, left compression as an optional script

--removed autostart after installation

TODO:

write better readme and manual about what happens when folder2ram is run, what folders are bound and where they will go.

make sure that keep_file and keep_folder structure clean their tmpfs folder before running.

remove configuration choices (so that by default it does nothing)

remove configuration cli GUI

add optional periodic sync to disk

add optional remote sync

add optional custom/settable paths where the folders can be synced


TODO2:

make this work with systemd.
