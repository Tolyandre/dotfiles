{ config, pkgs, ... }:
{
  # postgres is a dependency for immich

  services.postgresqlBackup = {
    enable = true;
    backupAll = true;
    location = "/mnt/seagate/Backup/postgresql";
  };
}