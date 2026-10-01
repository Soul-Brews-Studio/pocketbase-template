# PocketBase Template

A new [PocketBase](https://pocketbase.io) backend per project, in one click: **Use this template →
`docker compose up --build`** and you have a running PocketBase with an admin and an app login
already provisioned. The same image installs as a one-click Home Assistant add-on.

- Official PocketBase binary, pinned and SHA-256 verified (never built from source).
- Logins provisioned on first start with **random passwords, printed once**, kept in a 600 file.
- Schema as code (`pb_migrations/`), rules that are safe **without hooks**, `collections.json`
  for importing into an existing PocketBase.
- End-to-end tests for provisioning, access rules and realtime; CI on every push.
- `AGENTS.md`: instructions so an AI coding agent can turn the template into your project.

## Quick start

```sh
docker compose up --build -d
docker compose logs          # the banner with the admin UI URL and both logins, shown ONCE
```

```
 PocketBase Template ready (credentials shown ONCE)
 admin UI    : http://127.0.0.1:8090/_/
 admin login : admin@example.invalid / <random>
 app login   : app@example.invalid / <random>
 saved to    : /data/initial-credentials.txt (mode 600)
```

Open the admin UI, sign in, change what you like. Later starts never reset a password you
changed; they only say where the credentials file is.

```sh
docker compose down          # stop, keep data
docker compose down -v       # stop and DELETE all data (next start provisions again)
```

Settings are optional: copy `.env.example` to `.env` (`ADMIN_EMAIL`, `APP_USER_EMAIL`,
`PUBLIC_URL`, `PORT`). Passwords are never configured, always generated.

**Network:** compose binds `127.0.0.1` only. For other devices on your LAN, drop the
`127.0.0.1:` prefix in `compose.yaml` and set `PUBLIC_URL`. Before exposing it to the internet,
put HTTPS in front (reverse proxy or tunnel).

## Make it your project

1. **Use this template** on GitHub (or copy the files).
2. `scripts/rename.sh "Acme Tasks" acme_tasks "Task backend for Acme"`: project name, slug,
   add-on, compose, README title, all at once.
3. Replace the example `notes` collection in `pb_migrations/` with your own collections and
   rules, add matching cases to `scripts/e2e.mjs`.
4. `scripts/export-collections.sh` → `collections.json`, then `scripts/sync-addon.sh`.
5. `scripts/local-e2e.sh` until everything passes.

Or let an AI do it: open the repo in Claude Code, Codex or another agent and say
*"set this template up for &lt;project&gt;"*. It follows [`AGENTS.md`](AGENTS.md).

## Run without Docker

Needs the `pocketbase` binary (the version pinned in the Dockerfile).

```sh
scripts/provision.sh                  # creates pb_data/, the logins, prints the banner once
pocketbase serve --dir pb_data --migrationsDir pb_migrations --hooksDir pb_hooks
```

## Home Assistant add-on

The repository root is also a Home Assistant add-on repository. In Home Assistant: **Settings →
Add-ons → Add-on store → ⋮ → Repositories**, add `https://github.com/<you>/<repo>`, install the
add-on, start it, and read the **Log** tab for the logins. Details in
[`addon/pocketbase_template/DOCS.md`](addon/pocketbase_template/DOCS.md).

## Use an existing PocketBase instead

No container needed: in the existing server's dashboard, **Settings → Import collections**, paste
`collections.json` and **merge** (do not delete the other collections). The rules enforce
ownership on their own, so `pb_hooks/` is optional; copy it into the server's `pb_hooks` only if
you want the `app-user` command or your own hooks. Create an app login under **users**.
Tested with PocketBase v0.40.4; needs v0.23 or later.

## Layout

| path | what |
|---|---|
| `project.env` | project identity: name, slug, default port, default login emails |
| `pb_migrations/` | schema + rules (the `notes` example) |
| `pb_hooks/` | optional server code: the `app-user` command, example hook |
| `collections.json` | the same schema for "Import collections" (generated) |
| `compose.yaml`, `.env.example` | standalone run |
| `addon/<slug>/` | Dockerfile, `run.sh`, Home Assistant add-on files; `rootfs/` is generated |
| `repository.yaml` | makes the repo a Home Assistant add-on repository |
| `scripts/provision.sh` | first-start logins, random passwords, idempotent |
| `scripts/e2e.mjs`, `scripts/local-e2e.sh` | rules, provisioning, realtime and import tests |
| `scripts/rename.sh` | give the project its own name |
| `scripts/sync-addon.sh` | copy migrations/hooks/provisioning into the add-on (`--check` compares) |
| `scripts/export-collections.sh` | regenerate `collections.json` |
| `scripts/bump-pocketbase.sh` | pin a new PocketBase version + checksums |
| `scripts/privacy_check.py` | no paths, private IPs, credentials or PocketBase data in the repo |
| `AGENTS.md` | instructions for AI coding agents |

## Tests

```sh
scripts/local-e2e.sh                    # needs pocketbase, node (or RUNNER=bun), python3, curl
python3 scripts/privacy_check.py
```

`local-e2e.sh` provisions a fresh server, checks the banner, the 600 credentials file and
idempotence, then runs the rules tests three ways: with hooks, without hooks, and on a plain
PocketBase that imported `collections.json`. CI (`.github/workflows/ci.yml`) runs the same, plus
a Docker build check and the add-on sync check.

## Security notes

- Never commit `pb_data/`, `.env` or `initial-credentials.txt` (`.gitignore` covers them; the
  privacy check refuses them).
- Public sign-up is off: logins are created by an admin or by provisioning.
- Rules are written so they hold without hooks; keep it that way (see `AGENTS.md`).

## License

MIT, see [LICENSE](LICENSE). PocketBase is © its authors, MIT.
