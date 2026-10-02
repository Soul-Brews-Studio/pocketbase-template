# The front door for running this backend: `just` lists the recipes.
# Every recipe wraps a script in scripts/, which stay the source of truth (CI and anyone without
# `just` use them directly). Login for local runs: admin@local.test plus this machine's shared dev
# password (`just password`); see docs/running.md#change-the-logins.

# list the recipes
default:
    @just --list

# run in the foreground, no pm2 and no Docker (Ctrl-C stops it)
serve:
    scripts/pm2.sh serve

# start under pm2 (provisions first; the first run prints the logins once)
start:
    scripts/pm2.sh start

# stop the pm2 process (data stays)
stop:
    scripts/pm2.sh stop

# restart under pm2 (picks up new migrations and hooks)
restart:
    scripts/pm2.sh restart

# follow the server log
logs:
    scripts/pm2.sh logs

# pm2's view of this project
status:
    scripts/pm2.sh status

# remove it from pm2 (data stays)
delete:
    scripts/pm2.sh delete

# where this machine's shared dev password lives (prints the path, not the password)
password:
    @f="${PB_DEV_PASSWORD_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/pocketbase-template/dev-password}"; \
      if [ -s "$f" ]; then echo "login: admin@local.test   password: cat $f"; \
      else echo "no shared dev password yet: it is made by the first 'just serve' or 'just start'"; fi

# the full local test: provisioning, rules, realtime, import, add-on sync
e2e:
    scripts/local-e2e.sh

# run it with Docker instead (random logins in `docker compose logs`, shown once)
up:
    docker compose up --build -d

# stop the Docker run (`docker compose down -v` also deletes its data)
down:
    docker compose down
