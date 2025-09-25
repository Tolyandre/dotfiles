{ config, pkgs, ... }:
{
  # mysql (mariadb) is a dependency for seafile
  services.mysql.settings = {
    mysqld = {
      bind_address = "127.0.0.1";
    };
  };

  services.mysqlBackup = {
    enable = true;
    location = "/mnt/seagate/Backup/mysql_mariadb";
  };
}