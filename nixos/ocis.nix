{ config, pkgs, ... }:
{
  services.ocis = {
    # I can't manage this to work
    enable = false;
    #package = pkgs.ocis;
    address = "localhost";
    port = 9200;
    #url = "https://toly.is-cool.dev/ocis/";
    environment = {
      PROXY_TLS = "false";
      # does not work
      PROXY_HTTP_ROOT = "/ocis/";
      PROXY_HTTP_ADDR = "localhost:9200";
      OCIS_URL = "https://toly.is-cool.dev/ocis/";
      OCIS_EXCLUDE_RUN_SERVICES = "notifications";

      # TODO: secrets management (and move it to environmentFile)
      CS3_ALLOW_INSECURE = "true";
      GATEWAY_STORAGE_USERS_MOUNT_ID = "123";
      GRAPH_APPLICATION_ID = "1234";
      IDM_IDPSVC_PASSWORD = "password";
      IDM_REVASVC_PASSWORD = "password";
      IDM_SVC_PASSWORD = "password";
      IDP_ISS = "https://localhost:9200";
      IDP_TLS = "false";
      OCIS_INSECURE = "false";
      OCIS_INSECURE_BACKENDS = "true";
      OCIS_JWT_SECRET = "super_secret";
      OCIS_LDAP_BIND_PASSWORD = "password";
      OCIS_LOG_LEVEL = "error";
      OCIS_MACHINE_AUTH_API_KEY = "foo";
      OCIS_MOUNT_ID = "123";
      OCIS_SERVICE_ACCOUNT_ID = "foo";
      OCIS_SERVICE_ACCOUNT_SECRET = "foo";
      OCIS_STORAGE_USERS_MOUNT_ID = "123";
      OCIS_SYSTEM_USER_API_KEY = "foo";
      OCIS_SYSTEM_USER_ID = "123";
      OCIS_TRANSFER_SECRET = "foo";
      STORAGE_USERS_MOUNT_ID = "123";
      TLS_INSECURE = "true";
      TLS_SKIP_VERIFY_CLIENT_CERT = "true";
      WEBDAV_ALLOW_INSECURE = "true";

    };
  };
}
