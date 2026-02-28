# README — secrets repository (template)

Этот файл — шаблон `README.md` для вашего приватного репозитория `dotfiles-secrets`.
Скопируйте его в корень `~/Repo/Tolyandre/dotfiles-secrets/README.md`.

Цель
- Хранить только зашифрованные SOPS-файлы с секретами (yaml/json/.env/binary).
- Доступ к репозиторию — приватный (deploy key / git+ssh), а расшифровка происходит
  на целевой машине в фазе активации через `sops-nix`.

Репо: структура примера

```
secrets/
  elo/
    elo-project-466111.json.sops
  common.yaml.sops
README.md
```

1) Генерация ключей (локально, разработчик)
- Рекомендуется использовать `age` (простой и современный).
- Создайте ключ локально и сохраните приватный ключ в надёжном месте (не пушить в git):

```bash
# Сгенерировать age-ключ (приватный будет записан в ./age.key,
# команда распечатает публичный ключ (начинается с age1...))
age-keygen -o ./age.key
echo "Скопируйте публичный ключ (age1...) из вывода и добавьте его как recipient"
```

2) Шифрование секрета и добавление в репо

```bash
# Пример: зашифровать JSON для сервиса elo
PUBLIC_AGE_RECIPIENT="age1..." # подставьте публичный ключ, который получили выше
sops --encrypt --age "$PUBLIC_AGE_RECIPIENT" secrets/elo/elo-project-466111.json > secrets/elo/elo-project-466111.json.sops
git add secrets/elo/elo-project-466111.json.sops
git commit -m "Add elo service secret (encrypted)"
git push origin main
```

3) Доступ к приватному репозиторию (deploy key) — настройка на сервере (где вы запускаете `nixos-rebuild`)
- На GitHub/GitLab создайте read-only **deploy key** для `dotfiles-secrets`.
- Скопируйте приватную часть deploy key на сервер и сохраните её, например, в `/root/.ssh/id_deploy_secrets`.

Пример на сервере:

```bash
# как root
mkdir -p /root/.ssh
# положите приватный deploy-key в /root/.ssh/id_deploy_secrets
install -m 600 /tmp/id_deploy_secrets /root/.ssh/id_deploy_secrets
# (опционально) добавить ssh-config чтобы использовать конкретный ключ
cat >> /root/.ssh/config <<'EOF'
Host github.com
  IdentityFile /root/.ssh/id_deploy_secrets
  IdentitiesOnly yes
EOF

# проверить доступ
git ls-remote git@github.com:YourUser/dotfiles-secrets.git
```

4) Где на сервере хранить ключ расшифровки (age / gpg)
- sops-nix должен иметь возможность расшифровывать файлы в фазе активации. Удобный и рекомендуемый путь для `age` — поместить приватный ключ в защищённую постоянную директорию,
  например `/nix/persist/var/lib/sops-nix/key.txt` (или `/var/lib/sops/key.txt`).

Пример (на сервере):

```bash
mkdir -p /nix/persist/var/lib/sops-nix
# перенесите приватный age-ключ сюда; убедитесь, что файл только для root
install -m 600 /root/age.key /nix/persist/var/lib/sops-nix/key.txt
chown root:root /nix/persist/var/lib/sops-nix/key.txt
```

В `configuration.nix` в `sops` укажите путь:

```nix
sops = {
  age.keyFile = "/nix/persist/var/lib/sops-nix/key.txt"; # путь на сервере
};
```

5) Подключение приватного репозитория как flake input
- В вашем `flake.nix` добавьте input вида `secrets.url = "git+ssh://git@github.com:YourUser/dotfiles-secrets.git";`.
- При этом сервер должен иметь доступ к приватному репо (deploy key на месте).

Пример snippet для `flake.nix`:

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  sops-nix.url = "github:Mic92/sops-nix";
  secrets.url = "git+ssh://git@github.com:YourUser/dotfiles-secrets.git";
};
```

6) Пример использования в `configuration.nix` (sops-nix)

```nix
{ config, pkgs, inputs, ... }:
{
  imports = [ inputs.sops-nix.nixosModule ];

  sops.secrets."elo/elo-project-466111.json" = {
    sopsFile = builtins.toString inputs.secrets + "/secrets/elo/elo-project-466111.json.sops";
    path = "/run/secrets/elo/elo-project-466111.json";
    owner = "root";
    mode = "0400";
  };

  services.elo-web-service.google-service-account-key = "/run/secrets/elo/elo-project-466111.json";
}
```

Примечание: если вы формируете `nixosSystem` внутри `flake.nix`, `inputs.secrets` будет доступен там и можно передать его в конфигурацию. При необходимости помогу подогнать пример под ваш `flake.nix`.

7) Проверка и развертывание

На сервере (после установки deploy key и ключа age в месте, указанном в конфиге):

```bash
sudo nixos-rebuild switch --flake .#nixos-desktop
```

`sops-nix` выполнит расшифровку во время фазы activation и положит расшифрованные файлы в `/run/secrets/...` с правами, которые вы указали.

8) Дополнительные советы
- Не храните приватные ключи в git.
- Для командной работы используйте централизованный KMS (GCP/AWS/Azure) или добавляйте публичные ключи членов команды как recipients.
- Для восстановления/миграции ключей изучите `ssh-to-age`/`ssh-to-pgp` инструменты.

Если хотите, я могу:
- подготовить патч для вашего `flake.nix` и `nixos-desktop/configuration.nix` с примером `inputs.secrets` и `sops` конфигурацией, или
- создать шаблонный зашифрованный секрет и показать точные команды шифрования/декодирования.

---
Файл создан автоматически в репозитории `dotfiles` как `SECRETS-REPO-README.md` — скопируйте содержимое в `dotfiles-secrets/README.md`.
