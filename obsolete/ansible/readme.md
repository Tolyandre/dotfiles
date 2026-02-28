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


## Immich

```bash
# if rust error occures in vectorchord, install with GUI
sudo pamac install immich-server

ansible-playbook -i ./ansible/inventory.ini ./ansible/immich.yaml --diff
```

Fix postgres installation
```bash
sudo -i -u postgres 
initdb --locale=C.UTF-8 --encoding=UTF8 -D '/var/lib/postgres/data'
createdb immich
psql --dbname immich --username postgres -c 'CREATE EXTENSION IF NOT EXISTS vchord CASCADE'
psql -U postgres -c 'ALTER SYSTEM SET shared_preload_libraries = "vchord"'

sudo systemctl restart postgresql.service

```