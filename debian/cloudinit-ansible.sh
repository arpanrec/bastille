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
  sudo apt-get install -y "linux-headers-$(uname -r)"
else
  echo "installing linux-headers"
  sudo apt-get install -y "linux-headers"
fi

getent group "${CLOUD_INIT_GROUPNAME}" || sudo groupadd "${CLOUD_INIT_GROUPNAME}"

id -u "${CLOUD_INIT_USERNAME}" &>/dev/null ||
  sudo /sbin/useradd -m -d /home/"${CLOUD_INIT_USERNAME}" -g "${CLOUD_INIT_GROUPNAME}" -G wheel -s /bin/zsh "${CLOUD_INIT_USERNAME}"

sudo mkdir -p /home/"${CLOUD_INIT_USERNAME}"/.ssh

echo "${CLOUD_INIT_USE_SSHPUBKEY}" | sudo tee -a /home/"${CLOUD_INIT_USERNAME}"/.ssh/authorized_keys

sudo chown "${CLOUD_INIT_USERNAME}":"${CLOUD_INIT_GROUPNAME}" -R /home/"${CLOUD_INIT_USERNAME}"/.ssh
sudo chmod 700 /home/"${CLOUD_INIT_USERNAME}"/.ssh
sudo chmod 600 /home/"${CLOUD_INIT_USERNAME}"/.ssh/authorized_keys

sudo mkdir -p /etc/sudoers.d/
sudo su -c 'echo "%'"${CLOUD_INIT_GROUPNAME}"' ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/010-cloudinit'

sudo -H -u "${CLOUD_INIT_USERNAME}" bash -c 'set -ex && \
  export PATH="${HOME}/.local/bin:${PATH}" && \
  pip install ansible --user --upgrade && \
  ansible-galaxy collection install git+https://github.com/arpanrec/ansible_collection_utilities.git -f && \
  ansible-galaxy role install geerlingguy.docker -f && \
  mkdir "${HOME}/.tmp/cloudinit" -p && \
  echo "[local]" > "${HOME}/.tmp/cloudinit/inv" && \
  echo "localhost ansible_connection=local" >> "${HOME}/.tmp/cloudinit/inv" && \
  ansible-playbook -i "${HOME}/.tmp/cloudinit/inv" --extra-vars "pv_cloud_username=$(whoami)" arpanrec.utilities.cloudinit && \
  ansible-playbook -i "${HOME}/.tmp/cloudinit/inv" arpanrec.utilities.server_workspace --tags all
  '
