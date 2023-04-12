# Init System

Setup new system with basic utils

## Vars

- `pv_sinit_ansible_host`

  - Description: Hostname or IP address
  - Type: `str`
  - Required: `false`

- `pv_sinit_ansible_connection`

  - Description: Ansible Connection
  - Type: `str`
  - Required: `false`

- `pv_sinit_ansible_port`

  - Description: Ansible Post
  - Type: `int`
  - Required: `false`

- `pv_sinit_ansible_user`

  - Description: Ansible User
  - Type: `str`
  - Required: `false`

- `pv_sinit_ansible_password`

  - Description: Ansible Password
  - Type: `str`
  - Required: `false`

- `pv_sinit_ansible_ssh_private_key_file`

  - Description: Private Key File Content
  - Type: `str`
  - Required: `false`

- `pv_sinit_ansible_become_method`

  - Description: Ansible Become Method
  - Type: `str`
  - Required: `false`

- `pv_sinit_ansible_become_password`

  - Description: Ansible become Password
  - Type: `str`
  - Required: `false`

- `pv_sinit_expected_hostname`

  - Description: Expected Hostname for the system
  - Type: `str`
  - Required: `false`

- `pv_sinit_admin_username`

  - Description: Create a admin user
  - Type: `str`
  - Default: `vmuser`
  - Required: `false`

- `pv_sinit_ssh_public_key_content_for_admin_suer`

  - Description: SSH Public Key Content for Admin User
  - Type: `str`
  - Default: `{{ lookup('url', 'https://gitlab.com/arpanrecme/dotfiles/-/raw/main/.ssh/id_rsa.pub') }}`
  - Required: `false`

- `pv_sinit_is_install_docker`
  - Description: Want to install Docker-CE?
  - Type: `bool`
  - Required: `false`

## How to

```bash
git clone git@github.com:arpanrec/ansible-play-system-init.git ansible-play-system-init
cd ansible-play-system-init
python3 -m pip install --user --upgrade pip
python3 -m pip install --user --upgrade wheel setuptools
python3 -m pip install --user --upgrade virtualenv
virtualenv --python $(readlink -f $(which python3)) venv
source venv/bin/activate
pip install -r requirements.txt --upgrade
ansible-galaxy install -r roles/requirements.yml -f
ansible-playbook <playbook name>
```

In order to pass variables in silent mode

```bash
ansible-playbook play_silent.yml \
  --extra-vars='pv_sinit_ansible_user=root pv_sinit_ansible_become_method=su'
```

## LICENSE

`MIT`
