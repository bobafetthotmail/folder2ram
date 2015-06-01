# folder2ram

a rewrite of fs2ram that aims to be simpler, faster, safer. 

Designed to be controlled manually for easy integration with other projects.

debian source package as I stay mostly in debian environments.

for now I'm focusing on wheezy, will do a Jessie/systemd package in the future.

DONE:

--implementing the script written by mcortese in 2010
in this webpage https://www.debian-administration.org/article/661/A_transient_/var/log
webpage saved and available in docs folder
much better and safer than fs2ram's own system, as it runs a bind mount before mounting the tmpfs.
Added check so that if it fails it will safely unmount stuff. Won't leave it borked.

--the configuration script (the one that gets user input and deploys/removes the initscripts, it's the factotum)

--the initscript template (the one that is used by the configuration script to make the initscripts)

--write better readme and manual about what happens when folder2ram is run.

--fixed the folder2ram initscript template file with dos2unix (converted it to Unix) because it was giving weird nonsense syntax errors. and I'm on linux. Never wrote anything on Windows or DOS.

TODO:

discover why folder2ram fails without error code

add safety checks to avoid trying to mount things as tmpfs when the folder is too big to fit into RAM

add optional names for mount points (easier to remember/faster to write than full path when calling folder2ram)

add optional periodic sync to disk

add optional remote sync

add optional custom/settable paths where the folders can be synced

add more options like tmpfs size and mount options


TODO2:

make this work with systemd.

add an option to make a squashfs or similar heavily compressed archive either on disk or moved to RAM. 
it should theoretically increase performance, usually the CPU can decompress faster than the storage system can read.
