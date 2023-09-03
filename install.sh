#!/usr/bin/env bash
#

aliases() {
# Drive to install to.
echo ""
lsblk
echo ""
read -p "Please specify which drive it should be installed on [/dev/sda]: " DRIVE

# Hostname of the installed machine.
read -p "Please input your Hostname: " HOSTNAME

# Root password (leave blank to be prompted).
read -p "Please input an Password for root: " ROOTPASS

# Main user to create (by default, added to wheel group, and others).
read -p "Please input a username for user: " USER

# The main user's password (leave blank to be prompted).
read -p "Please input an Password for user: " USERPASS

# System timezone.
read -p "Please input your region [Europe/Amsterdam]: " TIMEZONE

echo
echo ====================
echo
echo What Desktop do you want to use?
echo
echo 1, XFCE Desktop
echo
echo 2, Hyprland WindowManager
echo
echo 3, Dwm WindowManager
echo
echo 0, Server Install
echo
echo ====================
echo

read -p "Choose an Option.. [1/0] " DESKTOP

}

setup_disk() {
    # Create an MBR partition table
    parted $DRIVE mklabel msdos

    # Create the "boot" partition (FAT32)
    parted $DRIVE mkpart primary fat32 1MiB 1GB
    parted $DRIVE set 1 boot on

    # Create the "root" partition (ext4, using the rest of the disk)
    parted $DRIVE mkpart primary ext4 1GB 100%

    # Format the "boot" partition as FAT32
    mkfs.fat -F32 ${DRIVE}1

    # Format the "root" partition as ext4
    mkfs.ext4 ${DRIVE}2

    # Mount disks
    mount ${DRIVE}2 /mnt
    mkdir /mnt/boot
    mount ${DRIVE}1 /mnt/boot
}

setup_packages() {
	# Actual pacstrap install
	pacstrap -K /mnt base base-devel linux linux-firmware grub git kitty zsh btop sudo openssh networkmanager cryptsetup lvm2 vim nano neovim
	# Chaotic-AUR Install
	cat > /mnt/chaoticaur.sh <<EOF
pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
pacman-key --lsign-key 3056513887B78AEB
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm
EOF
	arch-chroot /mnt sh chaoticaur.sh
}

choose_desktop() {


case $DESKTOP in
    '1')
	pacman -Sy git glibc --noconfirm
	arch-chroot /mnt pacman -Syu zenity pavucontrol xorg-xrandr xterm pulseaudio xfce4-pulseaudio-plugin firefox yay xfce4 xfce4-goodies plank kwin systemsettings kde-gtk-config neofetch lightdm-gtk-greeter lightdm colloid-gtk-theme-git surfn-icons-git --noconfirm

	## services
	arch-chroot /mnt systemctl enable lightdm

	## Config files
	mv -f /root/StormOS/xfce/home/.config /mnt/home/$USER/
	mv -f /root/StormOS/xfce/home/.local/* /mnt/home/$USER/.local/
	mv -f /root/StormOS/xfce/home/Desktop /mnt/home/$USER/
	mv -f /root/StormOS/xfce/usr/local/bin/* /mnt/usr/local/bin/
	mv -f /root/StormOS/xfce/usr/local/share/* /mnt/usr/local/share/
	mv -f /root/StormOS/xfce/usr/share/themes/* /mnt/usr/share/themes/
	mv -f /root/StormOS/xfce/usr/share/pixmaps/* /mnt/usr/share/pixmaps/
	mv -f /root/StormOS/xfce/usr/share/backgrounds/* /mnt/usr/share/backgrounds/
	mv -f /root/StormOS/xfce/usr/share/applications/* /mnt/usr/share/applications/
	mv -f /root/StormOS/xfce/usr/bin/* /mnt/usr/bin/
	cp -f /root/StormOS/xfce/etc/environment /mnt/etc/
	cp -f /root/StormOS/xfce/etc/lightdm/* /mnt/etc/lightdm/

	arch-chroot /mnt chown -R $USER:$USER /home/$USER
	arch-chroot /mnt chmod +x /usr/bin/*
	;;
    '2');;
    '3');;
    '0');;
    *);;
esac

}

chrootscript() {
touch /mnt/chrootscript.sh
cp config /mnt/
cat > /mnt/chrootscript.sh <<EOF
#!/usr/bin/env bash

# Services
systemctl enable NetworkManager
systemctl enable sshd

hwclock --systohc
locale-gen
echo "root:$ROOTPASS" | chpasswd
useradd -m -s /bin/bash -G adm,systemd-journal,wheel,rfkill,games,network,video,audio,optical,floppy,storage,scanner,power "$USER"
echo "$USER:$USERPASS" | chpasswd
nmcli general hostname $HOSTNAME
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
exit
EOF
arch-chroot /mnt sh chrootscript.sh
}

setup_configs() {
  cat > /mnt/etc/pacman.conf <<EOF
#
# /etc/pacman.conf
#
# See the pacman.conf(5) manpage for option and repository directives

#
# GENERAL OPTIONS
#
[options]
# The following paths are commented out with their default values listed.
# If you wish to use different paths, uncomment and update the paths.
#RootDir     = /
#DBPath      = /var/lib/pacman/
#CacheDir    = /var/cache/pacman/pkg/
#LogFile     = /var/log/pacman.log
#GPGDir      = /etc/pacman.d/gnupg/
#HookDir     = /etc/pacman.d/hooks/
HoldPkg     = pacman glibc
#XferCommand = /usr/bin/curl -L -C - -f -o %o %u
#XferCommand = /usr/bin/wget --passive-ftp -c -O %o %u
#CleanMethod = KeepInstalled
Architecture = auto

# Pacman won't upgrade packages listed in IgnorePkg and members of IgnoreGroup
#IgnorePkg   =
#IgnoreGroup =

#NoUpgrade   =
#NoExtract   =

# Misc options
#UseSyslog
Color
#NoProgressBar
CheckSpace
#VerbosePkgLists
ILoveCandy
ParallelDownloads = 5

# By default, pacman accepts packages signed by keys that its local keyring
# trusts (see pacman-key and its man page), as well as unsigned packages.
SigLevel    = Required DatabaseOptional
LocalFileSigLevel = Optional
#RemoteFileSigLevel = Required

# NOTE: You must run `pacman-key --init` before first using pacman; the local
# keyring can then be populated with the keys of all official Arch Linux

#
# REPOSITORIES
#   - can be defined here or included from another file
#   - pacman will search repositories in the order defined here
#   - local/custom mirrors can be added here or in separate files
#   - repositories listed first will take precedence when packages
#     have identical names, regardless of version number
#   - URLs will have $repo replaced by the name of the current repo
#   - URLs will have $arch replaced by the name of the architecture
#
# Repository entries are of the format:
#       [repo-name]
#       Server = ServerName
#       Include = IncludePath
#
# The header [repo-name] is crucial - it must be present and
# uncommented to enable the repo.
#

# The testing repositories are disabled by default. To enable, uncomment the
# repo name header and Include lines. You can add preferred servers immediately
# after the header, and they will be used before the default mirrors.

#[core-testing]
#Include = /etc/pacman.d/mirrorlist

[core]
Include = /etc/pacman.d/mirrorlist

#[extra-testing]
#Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

# If you want to run 32 bit applications on your x86_64 system,
# enable the multilib repositories as required here.

#[multilib-testing]
#Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist

# An example of a custom package repository.  See the pacman manpage for
# tips on creating your own repositories.
#[custom]
#SigLevel = Optional TrustAll
#Server = file:///home/custompkgs
EOF

  cat > /mnt/etc/sudoers <<EOF
## sudoers file.
##
## This file MUST be edited with the 'visudo' command as root.
## Failure to use 'visudo' may result in syntax or file permission errors
## that prevent sudo from running.
##
## See the sudoers man page for the details on how to write a sudoers file.
##

##
## Host alias specification
##
## Groups of machines. These may include host names (optionally with wildcards),
## IP addresses, network numbers or netgroups.
# Host_Alias	WEBSERVERS = www1, www2, www3

##
## User alias specification
##
## Groups of users.  These may consist of user names, uids, Unix groups,
## or netgroups.
# User_Alias	ADMINS = millert, dowdy, mikef

##
## Cmnd alias specification
##
## Groups of commands.  Often used to group related commands together.
# Cmnd_Alias	PROCESSES = /usr/bin/nice, /bin/kill, /usr/bin/renice, \
# 			    /usr/bin/pkill, /usr/bin/top

##
## Defaults specification
##
## You may wish to keep some of the following environment variables
## when running commands via sudo.
##
## Locale settings
# Defaults env_keep += "LANG LANGUAGE LINGUAS LC_* _XKB_CHARSET"
##
## Run X applications through sudo; HOME is used to find the
## .Xauthority file.  Note that other programs use HOME to find
## configuration files and this may lead to privilege escalation!
# Defaults env_keep += "HOME"
##
## X11 resource path settings
# Defaults env_keep += "XAPPLRESDIR XFILESEARCHPATH XUSERFILESEARCHPATH"
##
## Desktop path settings
# Defaults env_keep += "QTDIR KDEDIR"
##
## Allow sudo-run commands to inherit the callers' ConsoleKit session
# Defaults env_keep += "XDG_SESSION_COOKIE"
##
## Uncomment to enable special input methods.  Care should be taken as
## this may allow users to subvert the command being run via sudo.
# Defaults env_keep += "XMODIFIERS GTK_IM_MODULE QT_IM_MODULE QT_IM_SWITCHER"
##
## Uncomment to enable logging of a command's output, except for
## sudoreplay and reboot.  Use sudoreplay to play back logged sessions.
# Defaults log_output
# Defaults!/usr/bin/sudoreplay !log_output
# Defaults!/usr/local/bin/sudoreplay !log_output
# Defaults!/sbin/reboot !log_output

##
## Runas alias specification
##

##
## User privilege specification
##
root ALL=(ALL) ALL

## Uncomment to allow members of group wheel to execute any command
%wheel ALL=(ALL) ALL

## Same thing without a password
# %wheel ALL=(ALL) NOPASSWD: ALL

## Uncomment to allow members of group sudo to execute any command
# %sudo ALL=(ALL) ALL

## Uncomment to allow any user to run sudo if they know the password
## of the user they are running the command as (root by default).
# Defaults targetpw  # Ask for the password of the target user
# ALL ALL=(ALL) ALL  # WARNING: only use this together with 'Defaults targetpw'

%rfkill ALL=(ALL) NOPASSWD: /usr/sbin/rfkill
%network ALL=(ALL) NOPASSWD: /usr/bin/netcfg, /usr/bin/wifi-menu

## Read drop-in files from /etc/sudoers.d
## (the '#' here does not indicate a comment)
#includedir /etc/sudoers.d
EOF

    chmod 440 /etc/sudoers
}

setup_grub() {
    	arch-chroot /mnt grub-install $DRIVE
    	cp -rf /root/StormOS/grub/* /mnt/boot/grub/themes/
	cp -rf /root/StormOS/default/* /mnt/etc/default/
	arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}

finishing_up() {
 	rm /mnt/chrootscript.sh
 	rm /mnt/chaoticaur.sh
	cd
	umount -R /mnt
	reboot
}

configure() {
aliases

echo "setting up disk"
setup_disk

echo "Intalling Packages"
setup_packages

echo "Setting up Configs"
setup_configs

echo "Setting up chroot"
chrootscript

choose_desktop

echo "setting up grub"
setup_grub

finishing_up
}
configure
