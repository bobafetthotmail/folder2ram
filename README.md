# folder2ram

A script that moves a folder to RAM (tmpfs) and can sync it to disk any time thanks to bind mounts.

Designed to be self-contained and controlled manually for easy integration with other projects.

Packed as a debian package as I stay mostly in debian environments.
Will also make a openSUSE package after I fully migrated to that.

READYNESS: stable (finally)

FEATURES:

-can move a folder (and its contents) to a tmpfs mount in ram, then move it back to permanent storage at shutdown
-can sync the contents at any time
-can be set to autostart
-supports natively SysV init 
-supports natively Systemd init


DONE (newest first):

-- the repo has been rearranged in preparation for an openSUSE package

-- folders created by folder2ram are inheriting the user, group and permissions of the nearest parent folder in their path

-- working with systemd

-- major rework to clean up stuff, now there is only ONE initscript calling the main script

-- added manual sync do disk

-- fixed various bugs about initscripts and checks failing.

-- fixed the folder2ram initscript template file with dos2unix (converted it to Unix) because it was giving weird nonsense syntax errors. And I'm on linux. Never wrote on folder2ram from Windows.

-- write better readme and manual about what happens when folder2ram is run.

-- the initscript template (the one that is used by the configuration script to make the initscripts)

-- the configuration script (the one that gets user input and deploys/removes the initscripts, it's the factotum)

-- implementing the script written by mcortese in 2010
in this webpage https://www.debian-administration.org/article/661/A_transient_/var/log
webpage saved and available in docs folder
much better and safer than fs2ram's own system, as it runs a bind mount before mounting the tmpfs.
Added check so that if it fails it will safely unmount stuff. Won't leave it borked.







TODO (additional features for the future, these wait until I'm sure the core is stable):

add safety checks to avoid trying to mount things as tmpfs when the folder is too big to fit into RAM
(mostly to notify the user during configuration, the initscript fails safely already, no broken things in any case)

add optional names for mount points (easier to remember/faster to write than full path when calling folder2ram)

add optional periodic sync to disk

add optional remote sync

add optional custom/settable paths where the folders can be synced

add more options like tmpfs size and mount options


TODO2 (these may become top priority or stay in the backburner for ages):

add an option to make a squashfs or similar heavily compressed archive either on disk or moved to RAM. 
it should theoretically increase performance, usually the CPU can decompress faster than the storage system can read.
