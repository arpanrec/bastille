#!/usr/bin/env bash
set -e

if [[ $(id -u) -eq 0 ]]; then
	echo "Root user detected!!!! Error"
	exit 1
fi

if [[ -z $* ]]; then

	__install_tags=()

	read -n1 -r -p "Enter \"Y\" to track dotfiles from 'https://github.com/arpanrec/dotfiles' (Press any other key to Skip*) : " install_dotfiles
	echo ""
	if [[ ${install_dotfiles} == "Y" || ${install_dotfiles} == "y" ]]; then
		__install_tags+=('dotfiles')
	fi

	read -n1 -r -p 'Enter "Y" to install utility scripts (Press any other key to Skip*) : ' install_scripts
	echo ""
	if [[ ${install_scripts} == "Y" || ${install_scripts} == "y" ]]; then
		__install_tags+=('scripts')
	fi

	read -n1 -r -p 'Enter "Y" to install Telegram (Press any other key to Skip*) : ' install_telegram
	echo ""
	if [[ $install_telegram == "Y" || $install_telegram == "y" ]]; then
		__install_tags+=('telegram')
	fi

	read -n1 -r -p 'Enter "Y" to install Bitwarden (Press any other key to Skip*) : ' install_bitwarden_app_image
	echo ""
	if [[ $install_bitwarden_app_image == "Y" || $install_bitwarden_app_image == "y" ]]; then
		__install_tags+=('bitwarden_desktop')
	fi

	read -n1 -r -p 'Enter "Y" to install Bitwarden Command-line Interface (Press any other key to Skip*) : ' install_bitwarden_cli
	echo ""
	if [[ $install_bitwarden_cli == "Y" || $install_bitwarden_cli == "y" ]]; then
		__install_tags+=('bw')
	fi

	read -n1 -r -p 'Enter "Y" to install Mattermost (Press any other key to Skip*) : ' install_mattermost
	echo ""
	if [[ $install_mattermost == "Y" || $install_mattermost == "y" ]]; then
		__install_tags+=('mattermost_desktop')
	fi

	read -n1 -r -p 'Enter "Y" to install Postman (Press any other key to Skip*) : ' install_postman
	echo ""
	if [[ $install_postman == "Y" || $install_postman == "y" ]]; then
		__install_tags+=('postman')
	fi

	read -n1 -r -p 'Enter "Y" to install neo vim (Press any other key to Skip*) : ' install_neovim
	echo ""

	## Neovim requires nodejs
	if [[ $install_neovim == "Y" || $install_neovim == "y" ]]; then
		echo "Neovim COC requires nodejs"
		install_node_js=y
		__install_tags+=('nvim')
	else
		read -n1 -r -p 'Enter "Y" to install node js (Press any other key to Skip*) : ' install_node_js
		echo ""
		if [[ $install_node_js == "Y" || $install_node_js == "y" ]]; then
			__install_tags+=('nodejs')
		fi
	fi

	read -n1 -r -p 'Enter "Y" to install go (Press any other key to Skip*) : ' install_go
	echo ""
	if [[ $install_go == "Y" || $install_go == "y" ]]; then
		__install_tags+=('go')
	fi

	read -n1 -r -p 'Enter "Y" to install Oracle JDK17 (Press any other key to Skip*) : ' install_jdk
	echo ""
	if [[ $install_jdk == "Y" || $install_jdk == "y" ]]; then
		__install_tags+=('jdk')
	fi

	read -n1 -r -p 'Enter "Y" to install Visual Studio Code (Press any other key to Skip*) : ' install_vscode
	echo ""
	if [[ $install_vscode == "Y" || $install_vscode == "y" ]]; then
		__install_tags+=('code')
	fi

	read -n1 -r -p 'Enter "Y" to download themes (Press any other key to Skip*) : ' download_themes
	echo ""
	if [[ $download_themes == "Y" || $download_themes == "y" ]]; then
		__install_tags+=('themes')
	fi

	read -n1 -r -p 'Enter "Y" to copy KDE profiles (Press any other key to Skip*) : ' copy_kde_konsave
	echo ""
	if [[ ${copy_kde_konsave} == "Y" || ${copy_kde_konsave} == "y" ]]; then
		__install_tags+=('kde')
	fi

	read -n1 -r -p 'Enter "Y" to install gnome (Press any other key to Skip*) : ' install_gnome
	echo ""
	if [[ ${install_gnome} == "Y" || ${install_gnome} == "y" ]]; then
		__install_tags+=('gnome')
	fi

	__ansible_tags=$(printf "%s," "${__install_tags[@]}")

fi

# shellcheck source=/dev/null
if [[ -z ${VIRTUAL_ENV} ]]; then
	export PATH="${HOME}/.local/bin:${PATH}"
	echo "Updating Python packages"
	"$(readlink -f "$(which python3)")" -m pip install testresources wheel setuptools pip virtualenv --user --upgrade
	echo "Pip Packages installed"
	if [[ ! -d "${PWD}/venv" ]]; then
		virtualenv venv
	fi
	if [[ -f "${PWD}/venv/local/bin/activate" ]]; then
		source venv/local/bin/activate
	else
		source venv/bin/activate
	fi
fi

echo ""
echo ""
echo ""
echo "Virtual Env :: ${VIRTUAL_ENV}"
echo "Working dir :: ${PWD}"
echo ""
echo ""
echo ""

pip install -r requirements.txt --upgrade
ansible-galaxy install -r requirements.yml --force

if [[ -n ${__ansible_tags} && ${__ansible_tags} != "," && -z $* ]]; then
	ansible-playbook -i inventory.yml arpanrec.utilities.server_workspace --tags "${__ansible_tags::-1}"
elif [[ -z ${__ansible_tags} && -n $* ]]; then
	ansible-playbook -i inventory.yml arpanrec.utilities.server_workspace "$@"
fi
