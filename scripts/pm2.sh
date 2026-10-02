#!/usr/bin/env bash
# Run the backend with no Docker: the same `pocketbase serve` as docs/running.md ("Without Docker"),
# either in the foreground or kept alive by pm2 (restarted on crash, and on reboot after `pm2 save`).
# The justfile wraps these verbs: `just serve`, `just start`, `just logs`, ...
#
# Usage: scripts/pm2.sh <serve|start|stop|restart|status|logs|delete>
#   serve     provision, then run in the FOREGROUND (Ctrl-C stops it); pm2 not needed
#   start     provision (first run prints the logins ONCE), then start under pm2
#   stop      stop the process; data stays in pocketbase/pb_data
#   restart   restart the process (picks up new migrations and hooks)
#   status    pm2's view of this project
#   logs      follow the server log (Ctrl-C to leave)
#   delete    remove it from pm2; data stays
#
# The pm2 name is PROJECT_SLUG from project.env. The port is PORT from .env if set, otherwise
# DEFAULT_PORT. It binds 127.0.0.1 only, the same as compose.yaml. Needs the pocketbase binary
# pinned in the Dockerfile (on PATH, or $POCKETBASE), and `pm2` for everything but serve. Logins:
# this machine's shared dev password (PB_DEV_LOGINS=1, see docs/running.md#change-the-logins);
# PB_DEV_LOGINS=0 in .env = random.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"

# Read KEY from a KEY=value file; never sources it.
kv() { [ -f "$1" ] && sed -n "s/^$2=//p" "$1" | tail -n 1 | sed 's/^"\(.*\)"$/\1/' || true; }

name="$(kv "$root/project.env" PROJECT_SLUG)"; name="${name:-pocketbase}"
port="$(kv "$root/.env" PORT)"; [ -n "$port" ] || port="$(kv "$root/project.env" DEFAULT_PORT)"; port="${port:-8090}"
pb="${POCKETBASE:-$(command -v pocketbase || true)}"
serve_args=(serve --http "127.0.0.1:$port" --dir pocketbase/pb_data
  --migrationsDir pocketbase/pb_migrations --hooksDir pocketbase/pb_hooks --publicDir pocketbase/pb_public)

need() { command -v "$1" >/dev/null 2>&1 || { echo "pm2.sh: '$1' not found on PATH" >&2; exit 1; }; }

provision_first() {
  [ -n "$pb" ] && [ -x "$pb" ] || { echo "pm2.sh: pocketbase binary not found (PATH or \$POCKETBASE)" >&2; exit 1; }
  local want have
  want="$(sed -n 's/^ARG POCKETBASE_VERSION=//p' "$root"/addon/*/Dockerfile | head -n 1)"
  have="$("$pb" --version | awk '{print $NF}')"
  [ -z "$want" ] || [ "$want" = "$have" ] \
    || echo "pm2.sh: warning: pocketbase $have, the Dockerfile pins $want" >&2
  PB_DEV_LOGINS="${PB_DEV_LOGINS:-$(kv "$root/.env" PB_DEV_LOGINS)}"
  PB_DEFAULT_PASSWORD="${PB_DEFAULT_PASSWORD:-$(kv "$root/.env" PB_DEFAULT_PASSWORD)}"
  export PB_DEV_LOGINS="${PB_DEV_LOGINS:-1}" PB_DEFAULT_PASSWORD
  "$root/scripts/provision.sh" --url "http://127.0.0.1:$port" --pocketbase "$pb"
}

case "${1:-}" in
  serve)
    provision_first
    echo "pm2.sh: $name on http://127.0.0.1:$port   admin UI: http://127.0.0.1:$port/_/   (Ctrl-C stops)"
    cd "$root" && exec "$pb" "${serve_args[@]}" ;;
  start)
    need pm2
    if pm2 describe "$name" >/dev/null 2>&1; then
      echo "pm2.sh: '$name' is already in pm2; use restart, or delete first" >&2; exit 1
    fi
    provision_first
    pm2 start "$pb" --name "$name" --cwd "$root" --interpreter none -- "${serve_args[@]}"
    echo "pm2.sh: $name on http://127.0.0.1:$port   admin UI: http://127.0.0.1:$port/_/"
    echo "pm2.sh: to start it again after a reboot: pm2 save  (once: pm2 startup)" ;;
  stop|restart|delete) need pm2; pm2 "$1" "$name" ;;
  status) need pm2; pm2 describe "$name" ;;
  logs)   need pm2; pm2 logs "$name" ;;
  *) sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit 64 ;;
esac
