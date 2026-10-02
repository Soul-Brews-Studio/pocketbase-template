#!/usr/bin/env bash
# Run the backend under pm2, with no Docker: the same `pocketbase serve` as docs/running.md
# ("Without Docker"), kept alive by pm2 and restarted on crash or reboot (after `pm2 save`).
#
# Usage: scripts/pm2.sh <start|stop|restart|status|logs|delete>
#   start     provision (first run prints the logins ONCE), then start under pm2
#   stop      stop the process; data stays in pocketbase/pb_data
#   restart   restart the process (picks up new migrations and hooks)
#   status    pm2's view of this project
#   logs      follow the server log (Ctrl-C to leave)
#   delete    remove it from pm2; data stays
#
# The pm2 name is PROJECT_SLUG from project.env. The port is PORT from .env if set, otherwise
# DEFAULT_PORT. It binds 127.0.0.1 only, the same as compose.yaml. Needs `pm2` and the pocketbase
# binary pinned in the Dockerfile (on PATH, or $POCKETBASE). Logins: this machine's shared dev
# password (PB_DEV_LOGINS=1, see docs/running.md#change-the-logins); PB_DEV_LOGINS=0 in .env = random.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"

# Read KEY from a KEY=value file; never sources it.
kv() { [ -f "$1" ] && sed -n "s/^$2=//p" "$1" | tail -n 1 | sed 's/^"\(.*\)"$/\1/' || true; }

name="$(kv "$root/project.env" PROJECT_SLUG)"; name="${name:-pocketbase}"
port="$(kv "$root/.env" PORT)"; [ -n "$port" ] || port="$(kv "$root/project.env" DEFAULT_PORT)"; port="${port:-8090}"
pb="${POCKETBASE:-$(command -v pocketbase || true)}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "pm2.sh: '$1' not found on PATH" >&2; exit 1; }; }
need pm2

case "${1:-}" in
  start)
    [ -n "$pb" ] && [ -x "$pb" ] || { echo "pm2.sh: pocketbase binary not found (PATH or \$POCKETBASE)" >&2; exit 1; }
    want="$(sed -n 's/^ARG POCKETBASE_VERSION=//p' "$root"/addon/*/Dockerfile | head -n 1)"
    have="$("$pb" --version | awk '{print $NF}')"
    [ -z "$want" ] || [ "$want" = "$have" ] \
      || echo "pm2.sh: warning: pocketbase $have, the Dockerfile pins $want" >&2
    if pm2 describe "$name" >/dev/null 2>&1; then
      echo "pm2.sh: '$name' is already in pm2; use restart, or delete first" >&2; exit 1
    fi
    PB_DEV_LOGINS="${PB_DEV_LOGINS:-$(kv "$root/.env" PB_DEV_LOGINS)}"
    PB_DEFAULT_PASSWORD="${PB_DEFAULT_PASSWORD:-$(kv "$root/.env" PB_DEFAULT_PASSWORD)}"
    export PB_DEV_LOGINS="${PB_DEV_LOGINS:-1}" PB_DEFAULT_PASSWORD
    "$root/scripts/provision.sh" --url "http://127.0.0.1:$port" --pocketbase "$pb"
    pm2 start "$pb" --name "$name" --cwd "$root" --interpreter none -- \
      serve --http "127.0.0.1:$port" --dir pocketbase/pb_data \
      --migrationsDir pocketbase/pb_migrations --hooksDir pocketbase/pb_hooks \
      --publicDir pocketbase/pb_public
    echo "pm2.sh: $name on http://127.0.0.1:$port   admin UI: http://127.0.0.1:$port/_/"
    echo "pm2.sh: to start it again after a reboot: pm2 save  (once: pm2 startup)" ;;
  stop|restart|delete) pm2 "$1" "$name" ;;
  status) pm2 describe "$name" ;;
  logs)   pm2 logs "$name" ;;
  *) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 64 ;;
esac
