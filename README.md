#  The-Linux-Install-Script
This is the Advanced Installer. Here, I expect you to know what you are doing.

## Project Purpose
To Create a CLI/TUI Arch Installer.

## Installation Instruction
[THIS IN INTENDED TO BE RUN ON THE ARCHISO]
### How to setup through the ARCHISO
First, set up an increased cowsize.
```
mount -o remount,size=4G /run/archiso/cowspace
```
Install Git and GLIBC to Fix a Bug.
```
pacman -Sy glibc git
```
Now, we set up the installer.
```
git clone -b arch-stable https://github.com/Trensa-Organization/The-Linux-Install-Script
cd the-linux-install-script
sh install.sh
```
## Contributors
- DRAGONTOS
- bfitzgit23
- senalbulumulle

## Goals
- Create an installer using GTK4.
- Ensure modularity in its design.
- Maintain simplicity without unnecessary bloat.
- Craft a manifesto.
- Establish automation capabilities.
- Create a start screen branch with hyperlinks and stuff.
