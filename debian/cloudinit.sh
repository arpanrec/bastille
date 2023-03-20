#!/bin/bash
set -ex

if ! command -v sudo &>/dev/null; then
  apt update && apt install sudo -y
fi

export CLOUD_INIT_GROUPNAME=${CLOUD_INIT_GROUPNAME:-cloudinit}
export CLOUD_INIT_USERNAME=${CLOUD_INIT_USERNAME:-clouduser}
export CLOUD_INIT_USE_SSHPUBKEY=${CLOUD_INIT_USE_SSHPUBKEY:-'ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBJXzoi1QAbLmxnyudx+7Dm+FGTYU+TP02MTtxqq9w82Rm2kIDtGf4xVGxaidYEP/WcgpOHacjKDa7p2skBYljmk= arpan.rec@gmail.com'}
export CLOUD_INIT_SSHPORT=${CLOUD_INIT_SSHPORT:-22}

if [ "$(hostname)" = 'localhost' ]; then
  CLOUD_INIT_HOSTNAME=${CLOUD_INIT_HOSTNAME:-cloudvm}
else
  CLOUD_INIT_HOSTNAME=$(hostname)
fi

if [ "$(domainname)" = '(none)' ]; then
  CLOUD_INIT_DOMAINNAME=${CLOUD_INIT_DOMAINNAME:-clouddomain}
else
  CLOUD_INIT_DOMAINNAME=$(domainname)
fi

export CLOUD_INIT_HOSTNAME
export CLOUD_INIT_DOMAINNAME

echo """
CLOUD_INIT_GROUPNAME = ${CLOUD_INIT_GROUPNAME}
CLOUD_INIT_USERNAME = ${CLOUD_INIT_USERNAME}
CLOUD_INIT_USE_SSHPUBKEY = ${CLOUD_INIT_USE_SSHPUBKEY}
CLOUD_INIT_SSHPORT = ${CLOUD_INIT_SSHPORT}
CLOUD_INIT_HOSTNAME = ${CLOUD_INIT_HOSTNAME}
CLOUD_INIT_HOSTNAME = ${CLOUD_INIT_HOSTNAME}
"""

sudo apt update
sudo apt upgrade -y

sudo apt install -y \
  zip unzip net-tools build-essential tar wget curl ca-certificates sudo systemd telnet gnupg2 apt-transport-https lsb-release software-properties-common locales systemd-timesyncd network-manager gnupg2 gnupg pigz cron acl ufw vim python3-pip git fontconfig gtk-update-icon-cache libnss3 libatk1.0-0 libatk-bridge2.0-0 libgtk-3-0 bzip2 libgbm-dev libglib2.0-dev libdrm-dev libasound2 jq zsh libcap2-bin ntfs-3g exfat-fuse exfat-utils vim neovim \
  openssh-client openssh-server openssh-sftp-server

if [[ $(apt-cache search "linux-headers-$(uname -r)") ]]; then
  echo "installing linux-headers-$(uname -r)"
  apt-get install -y "linux-headers-$(uname -r)"
else
  echo "installing linux-headers"
  apt-get install -y "linux-headers"
fi

sudo mkdir -p /etc/sudoers.d/
sudo su -c 'echo "root ALL=(ALL:ALL) ALL" > /etc/sudoers.d/1000-root'
sudo su -c 'echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/1200-wheel'
sudo su -c 'echo "%sudo ALL=(ALL:ALL) ALL" > /etc/sudoers.d/1100-sudo'

getent group "${CLOUD_INIT_GROUPNAME}" || sudo groupadd "${CLOUD_INIT_GROUPNAME}"
getent group wheel || sudo groupadd wheel
getent group sudo || sudo groupadd sudo

id -u "${CLOUD_INIT_USERNAME}" &>/dev/null ||
  sudo /sbin/useradd -m -d /home/"${CLOUD_INIT_USERNAME}" -g "${CLOUD_INIT_GROUPNAME}" -G wheel -s /bin/zsh "${CLOUD_INIT_USERNAME}"

sudo mkdir -p /home/"${CLOUD_INIT_USERNAME}"/.ssh

echo "${CLOUD_INIT_USE_SSHPUBKEY}" | sudo tee -a /home/"${CLOUD_INIT_USERNAME}"/.ssh/authorized_keys

sudo chown "${CLOUD_INIT_USERNAME}":"${CLOUD_INIT_GROUPNAME}" -R /home/"${CLOUD_INIT_USERNAME}"/.ssh
sudo chmod 700 /home/"${CLOUD_INIT_USERNAME}"/.ssh
sudo chmod 600 /home/"${CLOUD_INIT_USERNAME}"/.ssh/authorized_keys

sudo su -c 'echo "%'"${CLOUD_INIT_GROUPNAME}"' ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/010-cloudinit'
sudo su -c 'echo "'"${CLOUD_INIT_USERNAME}"' ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/010-cloudinit'

sudo mkdir -p /etc/ssh/sshd_config.d

echo """
Port ${CLOUD_INIT_SSHPORT}
PasswordAuthentication no
PermitRootLogin no
PermitEmptyPasswords no
MaxAuthTries 3
X11Forwarding no
ClientAliveInterval 60
ClientAliveCountMax 3
ChallengeResponseAuthentication no
""" | sudo tee /etc/ssh/sshd_config.d/0001-cloudinit.conf

sudo sed -i '/^127.0.1.1/d' /etc/hosts
echo "127.0.1.1 ${CLOUD_INIT_HOSTNAME} ${CLOUD_INIT_HOSTNAME}.${CLOUD_INIT_DOMAINNAME}" | sudo tee -a /etc/hosts
sudo hostnamectl set-hostname "${CLOUD_INIT_HOSTNAME}"

sudo wget https://download.docker.com/linux/debian/gpg -O /etc/apt/trusted.gpg.d/docker.asc
sudo chmod 644 /etc/apt/trusted.gpg.d/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/download_docker_com_linux_debian.list >/dev/null
sudo apt-get update
sudo sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo usermod -aG docker "${CLOUD_INIT_USERNAME}"

sudo ufw allow "${CLOUD_INIT_SSHPORT}"

MAN_SERVICES=('NetworkManager' 'systemd-timesyncd' 'systemd-resolved' 'ufw' 'cron' 'ssh')
for MAN_SERVICE in "${MAN_SERVICES[@]}"; do
  echo "Enable Service: ${MAN_SERVICE}"
  sudo systemctl enable --now "${MAN_SERVICE}"
done

sudo systemctl restart ssh

sudo -H -u "${CLOUD_INIT_USERNAME}" bash -c 'bash <(curl https://raw.githubusercontent.com/arpanrec/ansible_plays/main/webrun.sh) --tags all'
sudo -H -u "${CLOUD_INIT_USERNAME}" bash -c 'git --git-dir="$HOME/.dotfiles" --work-tree=$HOME reset --hard HEAD'
