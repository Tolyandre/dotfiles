# Wrapper used as `services.xrdp.defaultWindowManager`. It boots an isolated,
# ephemeral PipeWire instance for the xrdp session and only then starts Plasma.
#
# WHY A PRIVATE INSTANCE
# ----------------------
# This box runs PipeWire system-wide (`pipewire.nix`, `systemWide = true`) so
# that `toly` and `game` both reach the PC speakers from local logins. That
# shared daemon must NOT host the xrdp sink:
#   * upstream `load_pw_modules.sh` calls `pw-cli quit` and
#     `pactl set-default-sink xrdp-sink` — harmless in a throwaway instance,
#     destructive against the shared one (would kill everyone's audio / reroute
#     other accounts' sound to the phone);
#   * we want a remote session's audio isolated to that session's RDP client.
#
# So each xrdp session gets its OWN pipewire+pipewire-pulse pair:
#   * no ALSA backend (can't touch the PC sound card);
#   * only `protocol-native` + `pulse` so apps in the session connect to it;
#   * `libpipewire-module-xrdp` is loaded into it to provide `xrdp-sink`;
#   * it dies with the session.
#
# The real Plasma binary is `exec`'d last so the whole session inherits the
# private audio environment.
#
# TROUBLESHOOTING (if audio still hits the PC speakers after this)
#   * Check Plasma isn't respawning `pipewire.service` via the user systemd
#     instance and overriding env. Symptom: `pw-cli info 0` inside the session
#     names a core other than `xrdp-*.local`. Fix: mask pipewire.service for the
#     xrdp session, or unset DBUS_SESSION_BUS_ADDRESS so plasma-dbus activation
#     of the user services doesn't fire.
#   * Check `~/.xsession-errors` and the pipewire log this script writes.
{
  lib,
  runCommand,
  kdePackages,
  pipewire,
  wireplumber,
  pipewire-module-xrdp,
}:

runCommand "startplasma-x11-xrdp" { } ''
  # Use the system's default pipewire.conf verbatim. Writing a minimal config
  # from scratch proved fragile: protocol-native needs args={ } and SPA lib
  # mappings to create the pipewire-0 socket, and missing any of those silently
  # produces a daemon with no listening socket — clients then fall back to the
  # system-wide daemon at /run/pipewire/pipewire-0 (shared across accounts).
  # ALSA devices won't actually appear because no session manager (wireplumber)
  # runs for this private instance; only xrdp-sink is registered, via
  # load_pw_modules.sh. The default config's core.name is already "pipewire-0".
  mkdir -p $out/etc/pipewire
  cp ${pipewire}/share/pipewire/pipewire.conf $out/etc/pipewire/pipewire.conf
  cp ${pipewire}/share/pipewire/pipewire-pulse.conf $out/etc/pipewire/pipewire-pulse.conf

  # Wireplumber config: use the system's known-good config with a single
  # override that disables ALL hardware monitoring (ALSA, bluetooth, video).
  # This way the session manager handles stream linking (policy.standard) so
  # pipewire-pulse can route audio to xrdp-sink, but the remote session only
  # sees xrdp-sink — not the PC's physical sound cards. Writing a full config
  # from scratch proved fragile (missing components → crashes).
  mkdir -p $out/etc/wireplumber/wireplumber.conf.d
  cp ${wireplumber}/share/wireplumber/wireplumber.conf $out/etc/wireplumber/
  cat > $out/etc/wireplumber/wireplumber.conf.d/99-no-hardware.conf <<'WPEOF'
  wireplumber.profiles = {
      main = {
          hardware.audio = disabled
          hardware.bluetooth = disabled
          hardware.video-capture = disabled
      }
      main-systemwide = {
          hardware.audio = disabled
          hardware.bluetooth = disabled
          hardware.video-capture = disabled
      }
  }
  WPEOF

  cat > $out/bin-wrapper <<'EOF'
  #!/bin/sh
  set -eu

  # xrdp sets XRDP_SESSION and XRDP_SOCKET_PATH in the session environment.
  # Only engage the private audio stack for actual xrdp sessions; if this
  # wrapper is ever run from a local login, fall through to plain Plasma so we
  # never disturb the system-wide daemon.
  if [ -z "''${XRDP_SESSION:-}" ] || [ -z "''${XRDP_SOCKET_PATH:-}" ]; then
      exec @startplasma@
  fi

  BASE=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
  SESSDIR="$BASE/xrdp-pw-$$"
  mkdir -p "$SESSDIR/pulse"
  chmod 700 "$SESSDIR"
  # CRITICAL: the private pipewire must listen on the DEFAULT socket name
  # (pipewire-0), so that clients — which look for
  # $XDG_RUNTIME_DIR/pipewire-0 first — connect to OUR daemon instead of
  # falling back to the system-wide socket at /run/pipewire/pipewire-0.
  # (Setting PIPEWIRE_CORE to a custom name renames the socket and breaks this,
  # because clients then don't find pipewire-0 and fall back to the system
  # daemon — which is shared across accounts.)
  export XDG_RUNTIME_DIR="$SESSDIR"
  # Comma-separated search path: our module dir first, pipewire's built-ins
  # second, so `load-module libpipewire-module-xrdp` resolves and so do the
  # protocol-native/pulse modules the config references.
  export PIPEWIRE_MODULE_DIR="${pipewire-module-xrdp}/lib/pipewire-0.3:${pipewire}/lib/pipewire-0.3"
  # Point PulseAudio clients at our private pipewire-pulse socket.
  export PULSE_SERVER="unix:$SESSDIR/pulse/native"

  PW_LOG="$SESSDIR/pipewire.log"
  PWP_LOG="$SESSDIR/pipewire-pulse.log"

  cleanup() {
      rc=$?
      # Kill the private daemons we started (PID subst below). `true` so a
      # missing pidfile never aborts cleanup.
      [ -f "$SESSDIR/pw.pid" ] && kill "$(cat "$SESSDIR/pw.pid")" 2>/dev/null || true
      [ -f "$SESSDIR/pwp.pid" ] && kill "$(cat "$SESSDIR/pwp.pid")" 2>/dev/null || true
      [ -f "$SESSDIR/wp.pid" ] && kill "$(cat "$SESSDIR/wp.pid")" 2>/dev/null || true
      rm -rf "$SESSDIR"
      exit $rc
  }
  trap cleanup EXIT INT TERM

  # Start the private PipeWire core.
  PIPEWIRE_CONFIG_DIR="@configdir@/pipewire" \
      pipewire 2>"$PW_LOG" &
  echo $! > "$SESSDIR/pw.pid"

  # Start the PulseAudio compatibility layer on top of it.
  PIPEWIRE_CONFIG_DIR="@configdir@/pipewire" \
      pipewire-pulse 2>"$PWP_LOG" &
  echo $! > "$SESSDIR/pwp.pid"

  # Start wireplumber with a profile that enables policy (stream linking) but
  # disables all hardware monitoring (ALSA, etc.) so the session only sees
  # xrdp-sink. Without wireplumber, pipewire-pulse can't link streams to sinks.
  WIREPLUMBER_CONFIG_DIR="@configdir@/wireplumber" \
      wireplumber 2>"$SESSDIR/wp.log" &
  echo $! > "$SESSDIR/wp.pid"

  # Wait for the native socket to appear before loading the xrdp module.
  for _ in $(seq 1 50); do
      if pw-cli info 0 >/dev/null 2>&1; then break; fi
      sleep 0.1
  done

  # Wait for the chansrv audio socket to exist before loading the module.
  # pipewire-module-xrdp calls try_connect() only ONCE (from the stream's
  # initial UNCONNECTED state change) and never retries — if the chansrv socket
  # doesn't exist at that moment, the sink is stuck in IO error forever.
  # Chansrv creates the socket shortly after session start, so we wait for it.
  EXPECTED_SINK_SOCKET="$XRDP_SOCKET_PATH/$XRDP_PULSE_SINK_SOCKET"
  for _ in $(seq 1 100); do
      [ -S "$EXPECTED_SINK_SOCKET" ] && break
      sleep 0.2
  done

  # Load the xrdp pipewire module directly (not via load_pw_modules.sh, which
  # uses `pw-cli quit` as a probe and `pw-cli -m` for loading — both have
  # subtle issues). We load into our private daemon and keep pw-cli alive in
  # the background so the module stays loaded.
  XRDP_SOCKET_PATH="$XRDP_SOCKET_PATH" XRDP_SESSION="$XRDP_SESSION" \
      PIPEWIRE_MODULE_DIR="${pipewire-module-xrdp}/lib/pipewire-0.3:${pipewire}/lib/pipewire-0.3" \
      pw-cli -m -d load-module libpipewire-module-xrdp \
          sink.node.latency=2048 \
          sink.stream.props={node.name=xrdp-sink} \
          source.stream.props={node.name=xrdp-source} \
          >/dev/null 2>"$SESSDIR/load-module.log" &

  # Give the module a moment to initialize.
  sleep 2

  # Ensure xrdp-sink is the default sink. Wireplumber usually handles this
  # automatically (xrdp-sink is the only sink), but set it explicitly as a
  # fallback.
  pw-metadata -n settings 0 default.audio.sink '{"name":"xrdp-sink"}' 2>/dev/null || true
  pw-metadata -n settings 0 default.audio.source '{"name":"xrdp-source"}' 2>/dev/null || true

  # Hand off to Plasma. exec so the session PID stays the plasma process and
  # our EXIT trap runs when the session ends.
  exec @startplasma@
  EOF

  mkdir -p $out/bin
    sed -e "s|@startplasma@|${lib.getBin kdePackages.plasma-workspace}/bin/startplasma-x11|" \
      -e "s|@configdir@|$out/etc|g" \
      $out/bin-wrapper > $out/bin/startplasma-x11-xrdp
  chmod +x $out/bin/startplasma-x11-xrdp
  rm $out/bin-wrapper
''
