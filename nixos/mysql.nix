{ config, pkgs, ... }:
{
  # mysql (mariadb) is a dependency for seafile
  services.mysql.settings = {
    mysqld = {
      bind_address = "127.0.0.1";
    };
  };
}