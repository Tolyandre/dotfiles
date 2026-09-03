{
  secrets,
  ...
}:
{
  # GitHub access token for nix fetchers. Flake inputs declared as
  # `github:...` (nixpkgs, hermes-agent, home-manager, ...) are downloaded
  # via api.github.com, where anonymous requests share a 60 req/h per-IP
  # limit; autoUpgrade and manual rebuilds regularly exhaust it (HTTP 429).
  # A token raises the limit to 5000 req/h per token.
  #
  # The secret file content is a ready-made nix.conf line:
  #   access-tokens = github.com=<TOKEN>
  # Create/rotate it in the secrets repo (see its README for the key):
  #   printf 'access-tokens = github.com=<TOKEN>\n' > /tmp/gh.conf
  #   sops --encrypt --input-type binary --output-type binary \
  #     --age "$PUBLIC_AGE_RECIPIENT" /tmp/gh.conf \
  #     > secrets/github-access-tokens.conf.sops
  sops.secrets."github-access-tokens" = {
    sopsFile = "${secrets}/secrets/github-access-tokens.conf.sops";
    format = "binary";
    # Read by root (nixos-rebuild, autoUpgrade, nix-daemon) and by toly
    # (nix build, dev shells), hence owner toly.
    owner = "toly";
    mode = "0400";
  };

  # `!include` keeps the token out of the world-readable nix store: the
  # generated /etc/nix/nix.conf only references the sops-decrypted file,
  # which lives on tmpfs (/run/secrets) and never enters the store. `!`
  # makes the include optional, so fetches fall back to anonymous when the
  # file is missing (e.g. before the first activation after adding this
  # secret). Read by every nix invocation: root, toly and the daemon —
  # system rebuilds and user-level nix/home-manager commands need no
  # separate setup.
  nix.extraOptions = ''
    !include /run/secrets/github-access-tokens
  '';
}
