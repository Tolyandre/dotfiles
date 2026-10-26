# Dedicated Firefox instance that trusts the Russian Trusted CA chain
# (Госуслуги and other Минцифры-signed sites) ONLY inside its own profile —
# the main Firefox keeps a clean trust store. The wrapper re-imports the
# certs idempotently (delete-then-add) on every launch, so updating a .cer
# in certs/ and rebuilding is enough to rotate them.
#
# -no-remote + a dedicated --profile directory make it an independent
# instance that runs alongside the main Firefox (no forwarding to an already
# running process). The profile lives outside profiles.ini, so the main
# Firefox can never open it. It is pre-seeded with the built-in Alpenglow
# theme once, to make its windows visually distinct.
{ pkgs, ... }:

let
  certutil = "${pkgs.nssTools}/bin/certutil";

  rootCa = ./certs/Russian_Trusted_Root_CA.cer;
  subCa = ./certs/Russian_Trusted_Sub_CA.cer;
  subCa2024 = ./certs/Russian_Trusted_Sub_CA_2024.cer;
in
{
  home.packages = [
    (pkgs.writeShellScriptBin "firefox-russian-cert" ''
      set -euo pipefail
      profile="$HOME/.local/share/firefox-russian-cert/profile"
      mkdir -p "$profile"

      # cert9.db normally appears after the first run; create it ourselves so
      # the CAs can be imported before launch. Firefox adopts the db as-is.
      [ -f "$profile/cert9.db" ] || ${certutil} -N -d "sql:$profile" --empty-password

      # "C,," trusts a CA for TLS server authentication only.
      ${certutil} -d "sql:$profile" -D -n "Russian Trusted Root CA" 2>/dev/null || true
      ${certutil} -d "sql:$profile" -A -t "C,," -n "Russian Trusted Root CA" -i ${rootCa}
      ${certutil} -d "sql:$profile" -D -n "Russian Trusted Sub CA" 2>/dev/null || true
      ${certutil} -d "sql:$profile" -A -t "C,," -n "Russian Trusted Sub CA" -i ${subCa}
      ${certutil} -d "sql:$profile" -D -n "Russian Trusted Sub CA 2024" 2>/dev/null || true
      ${certutil} -d "sql:$profile" -A -t "C,," -n "Russian Trusted Sub CA 2024" -i ${subCa2024}

      # One-time seed: the built-in Alpenglow theme (per-profile state, like
      # all theme/pref settings). user.js persists, so the choice sticks
      # without pinning future theme changes made inside the browser.
      if [ ! -f "$profile/user.js" ]; then
        printf '%s\n' \
          'user_pref("extensions.activeThemeID", "firefox-alpenglow@mozilla.org");' \
          > "$profile/user.js"
      fi

      # `firefox` itself comes from the system-wide programs.firefox.enable.
      exec firefox --profile "$profile" -no-remote "$@"
    '')

    (pkgs.makeDesktopItem {
      name = "firefox-russian-cert";
      exec = "firefox-russian-cert %U";
      icon = "firefox";
      desktopName = "Firefox (Russian Trusted)";
      categories = [
        "Network"
        "WebBrowser"
      ];
      # No mimeType on purpose: this entry must not compete with the main
      # Firefox as a default-browser candidate.
    })
  ];
}
