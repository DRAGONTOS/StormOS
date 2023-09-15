#!/usr/bin/env bash
#
# What root is the script cloned in eg /root/stormos and root is what you need to change for customizability
root="root"
debugging="true"

case $debugging in
	'true')
	exec > >(tee -a "/$root/stormos/install_log.txt") 2>&1
	;;
	*)
	;;
esac



sudo pacman -Sy vim --noconfirm

configeditask() {
clear
echo ""
echo "=============================================="
echo "  Welcome to the Advanced StormOS Installer  "
echo "=============================================="
echo ""
echo "[ONLY DO THIS IF YOU KNOW WHAT YOU ARE DOING!!]"
echo ""
read -p "Do you want to edit the configuration file? (y/n): " confedti

case $confedti in
	'y')
	vim /$root/stormos/install.sh
	sleep 5
	echo ''
	echo 'Saved to install drive /mnt/home/$USER/Documents/InstallConfig'
	echo ''
	sed -i '14,16,38d' /$root/stormos/install.sh
	clear
	sh /$root/stormos/install.sh
	;;
	*);;
esac
}


aliases() {
# Disk setup
echo ""
lsblk
echo ""
# Comment this out and uncomment DRIVE if you want to set the configuration manually
read -p "Please specify which drive it should be installed on [/dev/sda]: " DRIVE
#DRIVE='/dev/sda'

# Hostname of the installed machine.
# Comment this out and uncomment HOSTNAME if you want to set the configuration manually
read -p "Please input your Hostname: " HOSTNAME
#HOSTNAME='stormos'

# Main user to create (by default, added to wheel group, and others).
# Comment this out and uncomment USER if you want to set the configuration manually
read -p "Please input a username for user: " USER
#USER='namumi'

manualmode="false"


if [ "$manualmode" == "false" ]; then
# User Password
while true; do
    # Display a custom prompt and then read the password (hidden with asterisks)
    echo -n "Please enter your password for user $USER "
    read -s password

    # Confirm the password by asking the user to enter it again (hidden with asterisks)
    echo -e "\nConfirm your password: "
    read -s confirm_password

    # Check if the passwords match
    if [ "$password" == "$confirm_password" ]; then
        echo -e "\nPasswords match!"
	USERPASS="$password"
        break  # Exit the loop if passwords match
    else
        echo -e "\nPasswords do not match. Please try again."
    fi
done

# Root Password
while true; do
    # Display a custom prompt and then read the password (hidden with asterisks)
    echo -n "Please enter your password for root "
    read -s password

    # Confirm the password by asking the user to enter it again (hidden with asterisks)
    echo -e "\nConfirm your password: "
    read -s confirm_password

    # Check if the passwords match
    if [ "$password" == "$confirm_password" ]; then
        echo -e "\nPasswords match!"
	ROOTPASS="$password"
        break  # Exit the loop if passwords match
    else
        echo -e "\nPasswords do not match. Please try again."
    fi
done

else
	ROOTPASS="dt"
	USERPASS="dt"
fi

# System timezone.
# Comment this out and uncomment TIMEZONE if you want to set the configuration manually
read -p "Please input your region [Europe/Amsterdam]: " TIMEZONE
#TIMEZONE='Europe/Amsterdam'

echo
echo ====================
echo
echo What Desktop do you want to use?
echo
echo 1, XFCE Desktop
echo
echo 2, XFCE-i3 Desktop
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
	if [ -d "/sys/firmware/efi/" ]; then
    		# Create a GPT partition table
    		parted $DRIVE mklabel gpt

    		# Create the "EFI System Partition" (ESP) - 1GB (adjust the size as needed)
    		parted $DRIVE mkpart primary fat32 1MiB 1GB
    		parted $DRIVE set 1 esp on

    		# Create the "root" partition (ext4, using the rest of the disk)
    		parted $DRIVE mkpart primary ext4 1GB 100%

    		# Format the ESP as FAT32
    		mkfs.fat -F32 ${DRIVE}1

    		# Format the "root" partition as ext4
    		mkfs.ext4 ${DRIVE}2

    		# Mount the root partition
    		mount ${DRIVE}2 /mnt

    		# Create the "boot" directory in the root partition
    		mkdir -p /mnt/boot/efi

    		# Mount the ESP to /mnt/boot
    		mount ${DRIVE}1 /mnt/boot/efi

	else
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
	fi


}

setup_packages() {
	pacpakpak=("base" \
		"base-devel" \
		"plymouth" \
		"linux" \
		"linux-firmware" \
		"linux-headers" \
		"grub" \
		"efibootmgr" \
		"git" \
		"kitty" \
		"zsh" \
		"btop" \
		"sudo" \
		"openssh" \
		"networkmanager" \
		"cryptsetup" \
		"lvm2" \
		"vim" \
		"nano" \
		"neovim" \
		"ttf-jetbrains-mono" \
		"ttf-jetbrains-mono-nerd" \
		"ttf-arimo-nerd" \
		"ttf-tinos-nerd" \
		"reflector")

	# Actual pacstrap install
	pacstrap -K /mnt "${pacpakpak[@]}"	# Chaotic-AUR Install
	cat > /mnt/chaoticaur.sh <<EOF
pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
pacman-key --lsign-key 3056513887B78AEB
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm
EOF
	arch-chroot /mnt reflector --verbose -l 20 --sort rate --save /etc/pacman.d/mirrorlist
	arch-chroot /mnt sh chaoticaur.sh
}

choose_desktop() {


case $DESKTOP in
    '1')
	# var for wanted packages
		packagesdes1=("qt5ct" \
		"qt5-translations" \
		"oxygen-sounds" \
		"blueprint-compiler" \
		"appstream-glib" \
		"dmidecode" \
		"rust" \
		"gradience" \
		"zenity" \
		"update-grub" \
		"pavucontrol" \
		"xorg-xrandr" \
		"xterm" \
		"pulseaudio" \
		"xfce4-pulseaudio-plugin" \
		"firefox" \
		"yay" \
		"xfce4" \
		"xfce4-goodies" \
		"plank" \
		"kwin" \
		"systemsettings" \
		"kde-gtk-config" \
		"neofetch" \
		"lightdm-gtk-greeter" \
		"lightdm" \
		"colloid-gtk-theme-git" \
		"surfn-icons-git" \
		"mpd" \
		"mpv" \
		"mpc" \
		"ncmpcpp" \
		"pulsemixer" \
		"extra-cmake-modules" \
		"qt5-quick3d")
	
	cp -f /$root/stormos/binaries/oxygen-sounds-5.27.8-1-any.pkg.tar.zst /mnt/
	cp -f /$root/stormos/binaries/qt5-translations-5.15.10-1-any.pkg.tar.zst /mnt/
	arch-chroot /mnt pacman -U oxygen-sounds-5.27.8-1-any.pkg.tar.zst --noconfirm 
	arch-chroot /mnt pacman -U qt5-translations-5.15.10-1-any.pkg.tar.zst --noconfirm
	arch-chroot /mnt pacman -Syu "${packagesdes1[@]}" --noconfirm
	## services
	arch-chroot /mnt systemctl enable lightdm

	## Config files
	mkdir -p /mnt/etc/lightdm
	mv -f /$root/stormos/xfce/home/.config /mnt/home/$USER/
	mv -f /$root/stormos/xfce/home/.local/* /mnt/home/$USER/.local/
	mv -f /$root/stormos/xfce/home/Desktop /mnt/home/$USER/
	mv -f /$root/stormos/xfce/home/Music /mnt/home/$USER/
	mv -f /$root/stormos/xfce/usr/local/bin/* /mnt/usr/local/bin/
	mv -f /$root/stormos/xfce/usr/local/share/* /mnt/usr/local/share/
	mv -f /$root/stormos/xfce/usr/share/themes/* /mnt/usr/share/themes/
	mv -f /$root/stormos/xfce/usr/share/pixmaps/* /mnt/usr/share/pixmaps/
	mv -f /$root/stormos/xfce/usr/share/backgrounds/* /mnt/usr/share/backgrounds/
	mv -f /$root/stormos/xfce/usr/share/applications/* /mnt/usr/share/applications/
	mv -f /$root/stormos/xfce/usr/bin/* /mnt/usr/bin/
	mv -f /$root/stormos/xfce/home/.mozilla /mnt/home/$USER/
	cp -f /$root/stormos/xfce/etc/environment /mnt/etc/
	cp -f /$root/stormos/xfce/etc/lightdm/* /mnt/etc/lightdm/
	cp -f /$root/stormos/binaries/mission-center-0.3.1-1-x86_64.pkg.tar.zst /mnt/
	cp -f /$root/stormos/binaries/kwin-effects-cube-2.0.0-2-x86_64.pkg.tar.zst /mnt/

	arch-chroot /mnt chown -R $USER:$USER /home/$USER
	arch-chroot /mnt chmod +x /usr/bin/playmovie
	arch-chroot /mnt chmod +x /usr/bin/axelc8
	arch-chroot /mnt chmod +x /usr/bin/wgetm
	arch-chroot /mnt chmod +x /usr/bin/menuxstorm

	arch-chroot /mnt pacman -U kwin-effects-cube-2.0.0-2-x86_64.pkg.tar.zst --noconfirm
	arch-chroot /mnt pacman -U mission-center-0.3.1-1-x86_64.pkg.tar.zst --noconfirm
	;;
	'2')
	# var for wanted packages
	packagesdes2=("qt5ct" \
		"blueprint-compiler" \
		"appstream-glib" \
		"dmidecode" \
		"rust" \
		"gradience" \
		"nitrogen" \
		"picom" \
		"ocs-url" \
		"gnome-tweaks" \
		"meson" \
		"libconfig" \
		"ninja" \
		"asciidoc" \
		"uthash" \
		"libxdg-basedir" \
		"i3" \
		"zenity" \
		"update-grub" \
		"pavucontrol" \
		"xorg-xrandr" \
		"xterm" \
		"pulseaudio" \
		"xfce4-pulseaudio-plugin" \
		"firefox" \
		"yay" \
		"xfce4" \
		"xfce4-goodies" \
		"kde-gtk-config" \
		"neofetch" \
		"lightdm-gtk-greeter" \
		"lightdm" \
		"colloid-gtk-theme-git" \
		"surfn-icons-git" \
		"mpd" \
		"mpv" \
		"mpc" \
		"ncmpcpp" \
		"pulsemixer" \
		"xfce4-dev-tools")

	arch-chroot /mnt pacman -Syu "${packagesdes2[@]}" --noconfirm
	## services
	arch-chroot /mnt systemctl enable lightdm

	## Config files
	mv -f /$root/stormos/xfce-i3/home/.config /mnt/home/$USER/
	mv -f /$root/stormos/xfce-i3/home/.local/* /mnt/home/$USER/.local/
	mv -f /$root/stormos/xfce-i3/home/Desktop /mnt/home/$USER/
	mv -f /$root/stormos/xfce-i3/home/Music /mnt/home/$USER/
	mv -f /$root/stormos/xfce-i3/usr/local/bin/* /mnt/usr/local/bin/
	mv -f /$root/stormos/xfce-i3/usr/local/share/* /mnt/usr/local/share/
	mv -f /$root/stormos/xfce-i3/usr/share/themes/* /mnt/usr/share/themes/
	mv -f /$root/stormos/xfce-i3/usr/share/pixmaps/* /mnt/usr/share/pixmaps/
	mv -f /$root/stormos/xfce-i3/usr/share/backgrounds/* /mnt/usr/share/backgrounds/
	mv -f /$root/stormos/xfce-i3/usr/share/applications/* /mnt/usr/share/applications/
	mv -f /$root/stormos/xfce-i3/usr/bin/* /mnt/usr/bin/
	mv -f /$root/stormos/xfce-i3/home/.mozilla /mnt/home/$USER/
	mv -f /$root/stormos/xfce-i3/home/.icons /mnt/home/$USER/
	cp -f /$root/stormos/xfce-i3/etc/environment /mnt/etc/
	cp -f /$root/stormos/xfce-i3/etc/lightdm/* /mnt/etc/lightdm/
	cp -f /$root/stormos/binaries/i3ipc-glib-git-r183.1634568402.ef6d030-1-x86_64.pkg.tar.zst /mnt/
	cp -f /$root/stormos/binaries/xfce4-i3-workspaces-plugin-git-1.4.2.r0.g427f165-1-x86_64.pkg.tar.zst /mnt/
	cp -f /$root/stormos/binaries/mission-center-0.3.1-1-x86_64.pkg.tar.zst /mnt/


	arch-chroot /mnt chown -R $USER:$USER /home/$USER
	arch-chroot /mnt chmod +x /usr/bin/playmovie
	arch-chroot /mnt chmod +x /usr/bin/axelc8
	arch-chroot /mnt chmod +x /usr/bin/wgetm
	arch-chroot /mnt chmod +x /usr/bin/menuxstorm

	arch-chroot /mnt pacman -U i3ipc-glib-git-r183.1634568402.ef6d030-1-x86_64.pkg.tar.zst --noconfirm
	arch-chroot /mnt pacman -U xfce4-i3-workspaces-plugin-git-1.4.2.r0.g427f165-1-x86_64.pkg.tar.zst --noconfirm
	arch-chroot /mnt pacman -U mission-center-0.3.1-1-x86_64.pkg.tar.zst --noconfirm
	arch-chroot /mnt pacman -R xfdesktop --noconfirm
	;;
    '3');;
    '0');;
    *);;
esac

}

# Sets up things in chroot
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
useradd -m "$USER"
usermod -aG adm,systemd-journal,wheel,rfkill,games,network,video,audio,optical,floppy,storage,scanner,power "$USER"
echo "$USER:$USERPASS" | chpasswd
nmcli general hostname $HOSTNAME
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
exit
EOF
arch-chroot /mnt sh chrootscript.sh
}

# This cats config files.
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

# Sets up the plymouth theme (This is doesn't matter)
setup_plymouth() {
	#mkdir -p /mnt/usr/share/plymouth/themes/natural-gentoo-remastered/
	#cp /$root/stormos/plymouth/natural-gentoo-remastered/natural-gentoo-remastered.plymouth /mnt/usr/share/plymouth/themes/natural-gentoo-remastered/
	echo "This is not used because you are on branch Arch"
}


setup_grub() {
	genfstab -U /mnt >> /mnt/etc/fstab
	if [ -d "/sys/firmware/efi/" ]; then
    		echo "EFI mode"
		mkdir -p /mnt/boot/efi
		arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi
	else
    		echo "BIOS mode"
    		arch-chroot /mnt grub-install $DRIVE
	fi

    	cp -rf /$root/stormos/grub/* /mnt/boot/grub/themes/
	cp -rf /$root/stormos/default/* /mnt/etc/default/
	arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}

#Finishing touches
finishing_up() {
	# Removes all unneeded files
 	rm /mnt/chrootscript.sh
 	rm /mnt/chaoticaur.sh
	rm /mnt/i3ipc-glib-git-r183.1634568402.ef6d030-1-x86_64.pkg.tar.zst
	rm /mnt/xfce4-i3-workspaces-plugin-git-1.4.2.r0.g427f165-1-x86_64.pkg.tar.zst
	rm /mnt/mission-center-0.3.1-1-x86_64.pkg.tar.zst
	cd
	read -p "Do you want REBOOT or Check? [y/n] " reck
	case $confedti in
		'y')
		mkdir -p /mnt/home/$USER/Documents/InstallConfig
		cp /$root/stormos/install.sh /mnt/home/$USER/Documents/InstallConfig/
		;;
		*)
		;;
	esac


	case $reck in
		'y')
		umount -R /mnt
	 	reboot
		;;
		'n')
		bash
		exit
		;;
		*);;
	esac
}

# This executes all the functions()
configure() {
configeditask

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

setup_plymouth

echo "setting up grub"
setup_grub

finishing_up
}
configure
