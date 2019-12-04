# folder2ram

A script that moves a folder to RAM (tmpfs) and can sync it to disk any time thanks to bind mounts.

Designed to be self-contained and controlled manually for easy integration with other projects.

Packed as a debian package as it is made for OpenMediaVault that is a Debian-based distro.

The script itself is self-contained though, to use it in another distro just copy it from /debian_package/sbin into the /sbin of your system, chmod +x it to make it executable and you are ready to go.

There is a gentoo ebuild in https://github.com/comio/comio-overlay (not mantained by me).

READYNESS: stable

### FEATURES:

-can move a folder (and its contents) to a tmpfs mount in ram, then move it back to permanent storage at shutdown

-can sync the contents at any time

-can be set to autostart

-supports natively SysV init

-supports natively Systemd init


### DONE (newest first):

-- all files and the script itself now are not created world-writable nor world-executable anymore

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

-- use option fields of config file to specify mount options (now default mount option in "defaults" instead of "nosuid,noexec,nodev").

------------------------------------------

Things I never got around to implement:

-add safety checks to avoid trying to mount things as tmpfs when the folder is too big to fit into RAM
(mostly to notify the user during configuration, folder2ram fails safely already, no broken things in any case)

-add optional names for mount points (easier to remember/faster to write than full path when calling folder2ram)

-add optional periodic sync to disk

-add optional remote sync

-add optional custom/settable paths where the folders can be synced

-add an option to make a squashfs or similar heavily compressed archive either on disk or moved to RAM.
it should theoretically increase performance, usually the CPU can decompress faster than the storage system can read.

## INSTALLATION

Run the following commands as root or with sudo:

Download the script from this github repo directly and place it in /sbin with this command

**wget -O /sbin/folder2ram https://raw.githubusercontent.com/bobafetthotmail/folder2ram/master/debian_package/sbin/folder2ram**

Then make it executable
**chmod +x /sbin/folder2ram**

Then execute it (still as root) to see the help.
**folder2ram**

and you will see the following help text
```

Welcome to folder2ram version 0.3.0  !
folder2ram is a script-based utility that relocates the contents of a folder to RAM
and on shutdown unmounts it safely synching the data back to the permanent storage.

There are four main components of folder2ram system:
--the init script in /etc/init.d or the systemd service in /etc/folder2ram that calls this main script on boot and shutdown
--the main script in /etc/sbin/folder2ram
--the configuration file in /etc/folder2ram/folder2ram.conf
--the folders in /var/folder2ram, the bind-mounted folders
  they allow easy access to the original folder in permanent storage
  since if you mount folder A on folder B you lose access to folder B
  this trick allows access to B, allowing synching with the tmpfs at will

for first startup use -configure action, edit the mount points as you wish, then -mountall

list of actions (only one at a time):

-enableinit
::::::::::sets up an appropriate autostart/stop init script, does not start it

-enablesystemd
::::::::::sets up an appropriate autostart/stop systemd service, does not start it

-disableinit
::::::::::removes the autostart/stop init script and unmounts all mount points

-disablesystemd
::::::::::removes the autostart/stop systemd service and unmounts all mount points

-safe-disableinit
::::::::::removes the autostart/stop init script but unmounts only at shutdown (hence safely)
::::::::::it also works if folder2ram is unistalled shortly afterwards

-safe-disablesystemd
::::::::::removes the autostart/stop systemd service but unmounts only at shutdown (hence safely)
::::::::::it also works if folder2ram is unistalled shortly afterwards

-status
::::::::::print all mountpoints and their status (mounted or unmounted)

-sync X
::::::::::sync to disk the content of folder2ram's tmpfs folder number X (start counting from top entry in the config file)

-syncall
::::::::::sync to disk the content of folder2ram's tmpfs folders

-mountall
::::::::::folder2ram will mount all folders in the config file

-umountall
::::::::::folder2ram will unmount all folders in the config file

-configure
::::::::::folder2ram will open the configuration file in a text editor

-reset
::::::::::restore default config file

-clean
::::::::::unmounts all folders then removes any autostart
::::::::::WARNING: this might break programs that are using files in the tmpfs
::::::::::if you have programs using the tmpfs please use -safe-disableinit or
::::::::::-safe-disablesystemd, and then reboot the system
```


As mentioned in the help,
"for first startup use -configure action, edit the mount points as you wish, then -mountall"

So do a

**folder2ram -configure**

and it will generate the default config file and then ask you what is your favourite text editor to open it.

Edit that file to add your folders and then you can start it with a
**folder2ram -mountall**

If you want to start it on boot, you will probably need to create and enable the systemd service or init script. Execute only ONE of the two commands, depending on what you are using.

A normal Debian 8 or 9 system is using systemd for services so you will need to write

**folder2ram -enablesystemd**

If your Debian is using init scripts instead (this is NOT the default Debian install), then write

**folder2ram -enableinit**

## Which directories are recommended

In Openmediavault (Debian) this script is using this configuration file

https://github.com/OpenMediaVault-Plugin-Developers/openmediavault-flashmemory/blob/master/usr/share/openmediavault/mkconf/flashmemory

```
#################################################################################
#folder2ram main config file, autogenerated by openmediavault flashmemory plugin#
#################################################################################
#
#PROTIP: to make /var/lock or /tmp available as ram filesystems,
#        it is preferable to set the variables RAMTMP, RAMLOCK
#        in /etc/default/tmpfs.
#
#FILE SYSTEM: does nothing, will be implemented in the future. (everything goes to tmpfs for now)
#OPTIONS: does nothing, will be implemented in the future.
#
#<file system>  <mount point>                 <options>
#tmpfs		/var/cache                 #this folder will be activated later after testing is completed
tmpfs		/var/log
tmpfs		/var/tmp
tmpfs		/var/lib/openmediavault/rrd
tmpfs		/var/spool
tmpfs		/var/lib/rrdcached/
tmpfs		/var/lib/monit
tmpfs		/var/lib/php                #keep_folder_structure   folder2ram does not have an equivalent yet
tmpfs		/var/lib/netatalk/CNID
tmpfs		/var/cache/samba
```

In this post on OpenMediavault forum I explain how you can track down additional folders that are seeing many writes (as you may have installed other applications)

https://forum.openmediavault.org/index.php/Thread/6438-Tutorial-Experimental-Third-party-Plugin-available-Reducing-OMV-s-disk-writes-al/
