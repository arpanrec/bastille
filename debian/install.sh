#!/usr/bin/env bash
set -e

apt update

cp /etc/apt/sources.list /etc/apt/sources.list.bak."$(date +%s)"

cat <<EOT >"/etc/apt/sources.list"
deb http://deb.debian.org/debian bullseye main contrib non-free
deb-src http://deb.debian.org/debian bullseye main contrib non-free

deb http://security.debian.org/debian-security bullseye-security main contrib non-free
deb-src http://security.debian.org/debian-security bullseye-security main contrib non-free

deb http://deb.debian.org/debian bullseye-updates main contrib non-free
deb-src http://deb.debian.org/debian bullseye-updates main contrib non-free
EOT

apt update

apt-get install -y firmware-linux-free firmware-linux-nonfree linux-headers-"$(uname -r)" dkms network-manager dhcpcd5 \
    network-manager net-tools build-essential openssh-server gnupg2 wget rsync

wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg
echo "deb https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list

apt update

apt-get install fonts-liberation software-properties-common apt-transport-https wget ca-certificates gnupg2 vim sublime-text -y

systemctl set-default graphical.target

apt-get install -y task-gnome-desktop gnome

apt-get install -y git curl zsh terminator htop

if hash google-chrome-stable &>/dev/null; then
    echo "google-chrome is installed!"
else
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O google-chrome-stable_current_amd64.deb
    dpkg -i google-chrome-stable_current_amd64.deb
    rm -rf google-chrome-stable_current_amd64.deb
fi

apt-get install -y python3-pip
apt-get install -y ffmpegthumbnailer ffmpeg vlc eog heif-gdk-pixbuf heif-thumbnailer libavcodec-extra

__optional_packages=('gnome-tweak-tool' 'gnome-tweaks' 'gnome-shell-extension-manager')

for i in "${__optional_packages[@]}"; do
    echo "Checking for package $i"
    __apt_search=$(apt-cache search --names-only "$i")
    if [[ -n "$__apt_search" ]]; then
        echo "Installing $i"
        apt-get install -y "$i"
    else
        echo "No install candidate for $i"
    fi
done


apt install -y gnome-shell-extensions gnome-shell-extension-prefs

sed -i 's/managed=false/managed=true/' /etc/NetworkManager/NetworkManager.conf

timedatectl set-ntp true
timedatectl set-timezone Asia/Kolkata

systemctl enable NetworkManager
systemctl enable dhcpcd
systemctl enable ssh

echo "End Of Script"
