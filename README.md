# StormOS
This is the Advanced installer, here by i aspect you know what you are doing.

## Installation Instruction
[THIS IN INTENDED TO BE RUN ON THE ARCHISO]
### How to setup through the ARCHISO
First Setup increased cowsize.
```
systemd-cow-setup --set-size=4G
```
Install git and glibc to fix bug
```
pacman -Sy glibc git
```
now we setup the installer
```
git clone https://github.com/dragontos/stormos
cd stormos
sh install.sh
```
