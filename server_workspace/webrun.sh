#!/usr/bin/env bash
set -e

__clone_directory="${HOME}/.tmp/make_my_computer"
__working_dir="${__clone_directory}/server_workspace"
__git_setup_repo='https://github.com/arpanrec/make_my_computer.git'

if ! hash git &>/dev/null; then
	echo "git not Installed"
	exit 1
fi

if ! hash virtualenv &>/dev/null; then
	echo "python-virtualenv/python3-virtualenv not Installed"
	exit 1
fi

mkdir -p "$(dirname "${__clone_directory}")"

if [[ ! -d ${__clone_directory} ]]; then
	git clone --depth 1 --single-branch "${__git_setup_repo}" "${__clone_directory}"
	cd "${__working_dir}"
else
	cd "${__working_dir}"
fi

git reset --hard HEAD
git clean -f -d
git pull

./server_workspace.sh "$@"
