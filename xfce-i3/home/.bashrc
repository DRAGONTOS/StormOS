#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

#alias nvidia="optimus-manager --set-startup nvidia"
#alias intel="optimus-manager --set-startup hybrid"

alias install="sudo pacman -S"
alias uninstall="sudo pacman -Rns"
alias pupd="sudo pacman -Syyu"
alias yupd="yay -Syu --noconfirm"
alias edit="mousepad"
alias sedit="sudo mousepad"
alias rsmb="sudo systemctl restart smb"
alias rnmb="sudo systemctl restart nmb"
alias yinstall="yay -S"
alias reflect="sudo reflector --verbose -l 20 --sort rate --save /etc/pacman.d/mirrorlist"
alias gpgup="updpkgsums"
alias reload="source ~/.bashrc"
alias up-grub="sudo grub-mkconfig -o /boot/grub/grub.cfg"
neofetch