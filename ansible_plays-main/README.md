# Ansible Play Server Workspace

Setup workspace for development using [server workspace playbook](https://github.com/arpanrec/ansible_collection_utilities/blob/main/playbooks/server_workspace.md)

## Run the playbook

```bash
bash <(curl https://raw.githubusercontent.com/arpanrec/ansible_plays/main/webrun.sh)
```

For custom/silent install tags, extra-vars are optional

```bash
bash <(curl https://raw.githubusercontent.com/arpanrec/ansible_plays/main/webrun.sh) \
--tags all,code \
--extra-vars='pv_ua_nodejs_version=16 pv_ua_code_version=1.64.2'
```

## License

`MIT`
