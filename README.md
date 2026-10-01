# PocketBase Template

[![ci](https://github.com/Soul-Brews-Studio/pocketbase-template/actions/workflows/ci.yml/badge.svg)](https://github.com/Soul-Brews-Studio/pocketbase-template/actions/workflows/ci.yml)
![PocketBase](https://img.shields.io/badge/PocketBase-v0.40.4-b8dbe4)
![License: MIT](https://img.shields.io/badge/license-MIT-green)

A new [PocketBase](https://pocketbase.io) backend per project, in one click.
**Use this template → `docker compose up --build`** and you have a running PocketBase with an
admin and an app login already provisioned. The same image installs as a one-click Home
Assistant add-on.

- **Pinned and verified:** the official PocketBase binary, checked against its SHA-256; never built from source.
- **Logins on first start:** random passwords, printed once, kept in a mode-600 file.
- **Schema as code:** migrations, rules that hold **without hooks**, and `collections.json` for an existing server.
- **Tested:** provisioning, access rules and realtime, end to end, in CI on every push.
- **AI-ready:** a new repo opens a *Set up this backend* issue, and `AGENTS.md` tells a coding agent how to finish it.

## Contents

- [Quick start](#quick-start)
- [Make it your project](#make-it-your-project)
- [Repository layout](#repository-layout)
- [Other ways to run it](#other-ways-to-run-it)
- [Tests](#tests)
- [Security notes](#security-notes)

## Quick start

```sh
docker compose up --build -d
docker compose logs              # the banner below, shown ONCE
```

```
 PocketBase Template ready (credentials shown ONCE)
 admin UI    : http://127.0.0.1:8090/_/
 admin login : admin@example.invalid / <random>
 app login   : app@example.invalid / <random>
 saved to    : /data/initial-credentials.txt (mode 600)
```

Sign in to the admin UI and change what you like. Later starts never reset a password you
changed; they only say where the credentials file is.

| command | does |
|---|---|
| `docker compose down` | stop, keep the data |
| `docker compose down -v` | stop and **delete** all data; the next start provisions again |

Settings are optional: copy `.env.example` to `.env` (`ADMIN_EMAIL`, `APP_USER_EMAIL`,
`PUBLIC_URL`, `PORT`). Passwords are never configured, always generated.

## Make it your project

A repo created from this template opens a **"Set up this backend"** issue on its first push
(`.github/workflows/init.yml`) with this checklist:

1. `scripts/rename.sh "Acme Tasks" acme_tasks "Task backend for Acme"`: name, slug, add-on, compose and README title in one go.
2. Replace the example `notes` collection in `pocketbase/pb_migrations/` with your own collections and rules, and add matching checks to `scripts/e2e.mjs`.
3. `scripts/export-collections.sh`, then `scripts/sync-addon.sh`.
4. `scripts/local-e2e.sh` until it prints `LOCAL E2E: ALL PASS`.

**Or let an AI do it:** open the repo in Claude Code, Codex or another coding agent and say
*"Set up this template for my project, following AGENTS.md."* It asks for the name, purpose and
data model first. See [`AGENTS.md`](AGENTS.md).

## Repository layout

```
├── pocketbase/                 what PocketBase loads: edit here
│   ├── pb_migrations/          schema + access rules (the `notes` example)
│   ├── pb_hooks/               optional server code: the `app-user` command, an example hook
│   └── collections.json        the same schema for "Import collections" (generated)
├── addon/<slug>/               the image: Dockerfile, run.sh, Home Assistant add-on files
│   └── rootfs/                 generated copy of pocketbase/ + provision.sh (never edit)
├── scripts/
│   ├── provision.sh            first-start logins, random passwords, idempotent
│   ├── e2e.mjs, local-e2e.sh   provisioning, rules, realtime and import tests
│   ├── rename.sh               give the project its own name
│   ├── sync-addon.sh           copy pocketbase/ into the add-on (--check compares)
│   ├── export-collections.sh   regenerate collections.json
│   ├── bump-pocketbase.sh      pin a new PocketBase version + checksums
│   └── privacy_check.py        no paths, private IPs, credentials or data in the repo
├── .github/                    CI, the init workflow and the setup issue text
├── compose.yaml, .env.example  standalone run
├── project.env                 project identity: name, slug, port, default login emails
├── repository.yaml             makes the repo a Home Assistant add-on repository
└── AGENTS.md, CLAUDE.md        instructions for AI coding agents
```

## Other ways to run it

### Without Docker

Needs the `pocketbase` binary (the version pinned in the Dockerfile).

```sh
scripts/provision.sh       # creates pocketbase/pb_data, the logins, prints the banner once
pocketbase serve --dir pocketbase/pb_data \
  --migrationsDir pocketbase/pb_migrations --hooksDir pocketbase/pb_hooks
```

### As a Home Assistant add-on

The repository root is also a Home Assistant add-on repository. In Home Assistant: **Settings →
Add-ons → Add-on store → ⋮ → Repositories**, add `https://github.com/<you>/<repo>`, install
the add-on, start it, and read the **Log** tab for the logins. Details in
[`addon/pocketbase_template/DOCS.md`](addon/pocketbase_template/DOCS.md).

### On an existing PocketBase

No container: in the existing server's dashboard, **Settings → Import collections**, paste
`pocketbase/collections.json` and **merge** (don't delete the other collections). The rules
enforce ownership on their own, so hooks are optional; copy `pocketbase/pb_hooks/` into the
server's `pb_hooks` only if you want the `app-user` command or your own hooks. Create an app
login under **users**. Tested with PocketBase v0.40.4; needs v0.23 or later.

### Network

Compose binds `127.0.0.1` only. For other devices on your LAN, drop the `127.0.0.1:` prefix in
`compose.yaml` and set `PUBLIC_URL`. Before exposing it to the internet, put HTTPS in front
(reverse proxy or tunnel).

## Tests

```sh
scripts/local-e2e.sh                 # needs pocketbase, node (or RUNNER=bun), python3, curl
python3 scripts/privacy_check.py
```

`local-e2e.sh` provisions a fresh server and checks the banner, the 600 credentials file and
idempotence. It then runs the rules tests three ways: with hooks, without hooks, and on a plain
PocketBase that imported `collections.json`. CI runs the same, plus a Docker build check, a
compose smoke test and the add-on sync check.

To move to a new PocketBase release: `scripts/bump-pocketbase.sh <version>`, then the tests.

## Security notes

- Never commit `pocketbase/pb_data/`, `.env` or `initial-credentials.txt`. `.gitignore` covers
  them and the privacy check refuses them.
- Public sign-up is off: logins are created by an admin or by provisioning.
- Rules are written to hold without hooks; keep it that way (see `AGENTS.md`).

## License

MIT, see [LICENSE](LICENSE). PocketBase is © its authors, MIT.
