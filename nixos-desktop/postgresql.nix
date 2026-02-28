{ config, pkgs, ... }:
{
  # postgres is a dependency for immich
  services.postgresql = {
    enable = true;
  };

  /*
  How to create user and reset password:

  sudo -u postgres psql
  CREATE ROLE dbeaver WITH LOGIN;
  ALTER ROLE dbeaver WITH SUPERUSER;
  ALTER ROLE dbeaver WITH PASSWORD 'ваш_пароль';
  */

  services.postgresqlBackup = {
    enable = true;
    backupAll = true;
    location = "/mnt/seagate/Backup/postgresql";
  };
}
