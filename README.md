# StormOS
This is the Advanced Installer. Here, I expect you to know what you are doing.

## Project Purpose
To Create a CLI/TUI Arch Installer.

## Installation Instruction
[THIS IN INTENDED TO BE RUN ON THE ARCHISO]
### How to setup through the ARCHISO
First, set up an increased cowsize.
```
systemd-cow-setup --set-size=4G
```
Install Git and GLIBC to Fix Bug.
```
pacman -Sy glibc git
```
Now, we set up the installer.
```
git clone https://github.com/dragontos/stormos
cd stormos
sh install.sh
```
## Contributors
- DRAGONTOS
