# Home server provisioning with Ansible

Tested on Manjaro.

Prerequisites:
```bash
sudo pacman -S ansible sshd
```


Run playbook (remove `--check` to apply changes)
```bash
ansible-playbook -i ./ansible/inventory.ini ./ansible/playbook.yaml --ask-become-pass --diff --check
```
