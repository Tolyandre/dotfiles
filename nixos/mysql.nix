{ config, pkgs, ... }:
{
  # mysql (mariadb) is a dependency for seafile
  services.mysql.settings = {
    mysqld = {
      # override to bind to localhost only
      bind_address = "127.0.0.1";
    };
  };

  services.mysqlBackup = {
    enable = true;
    location = "/mnt/seagate/Backup/mysql_mariadb";
    databases = [
      "ccnet_db"
      "seafile_db"
      "seahub_db"
    ];
  };
}