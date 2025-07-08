# Home server provisioning with Ansible

Tested on Manjaro.

Prerequisites:

```bash
sudo pacman -S ansible bws-bin

ansible-galaxy collection install bitwarden.secrets python-bitwarden-sdk
```

To set secrets obtain an access token from https://vault.bitwarden.com 

```bash
# put access token here
export BWS_ACCESS_TOKEN=

# or create .env file
export $(xargs <.env)
```

Run playbook (remove `--check` to apply changes)
```bash
ansible-playbook -i ./ansible/inventory.ini ./ansible/playbook.yaml --diff --check
```
