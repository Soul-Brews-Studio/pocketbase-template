# Running it

## Without Docker

Needs the `pocketbase` binary (the version pinned in the Dockerfile).

```sh
scripts/provision.sh       # creates pocketbase/pb_data, the logins, prints the banner once
pocketbase serve --dir pocketbase/pb_data \
  --migrationsDir pocketbase/pb_migrations --hooksDir pocketbase/pb_hooks
```

### With `just` (foreground or pm2)

```sh
just serve        # foreground, no pm2 and no Docker (Ctrl-C stops it)
just start        # under pm2; then just logs | restart | stop | status | delete
just password     # where the shared dev password is (login: admin@local.test)
just e2e          # the full local test
```

The recipes wrap `scripts/pm2.sh`; use it directly where `just` is not installed.

### Kept running with pm2

The same server, restarted on crash and (after `pm2 save`) on reboot. The pm2 name is
`PROJECT_SLUG`; the port is `PORT` from `.env`, else `DEFAULT_PORT`; it binds `127.0.0.1` only.

```sh
scripts/pm2.sh start       # provision (logins shown ONCE), then start under pm2
scripts/pm2.sh logs        # follow the server log
scripts/pm2.sh restart     # after new migrations or hooks
scripts/pm2.sh stop        # or delete; pocketbase/pb_data stays either way
pm2 save                   # remember it; `pm2 startup` once makes pm2 itself start at boot
```

## As a Home Assistant add-on

The repository root is also a Home Assistant add-on repository: use the README's **Add the
repository** button (or **Settings → Add-ons → Add-on store → ⋮ → Repositories** and the repo
URL), install, start, and read the **Log** tab for the logins.

- **Sidebar panel with auto-login:** the add-on appears in the sidebar; opening it signs a Home
  Assistant user in to the PocketBase dashboard as the admin (`auto_login`, trusted only from
  Supervisor's ingress proxy). The landing page is `pocketbase/pb_public/index.html`.
- **Prebuilt image (public repos):** the init workflow sets `image:` in the add-on's
  `config.yaml` and `.github/workflows/addon-image.yml` pushes
  `ghcr.io/<owner>/{arch}-addon-<slug>` for amd64 and aarch64, so Home Assistant pulls instead of
  building. **GHCR packages start private**: after the first run, set each package to *Public*
  (Packages → package → Package settings → Change visibility). Release a new image by bumping
  `version:` in `config.yaml`. Private repos have no `image:` line and build on the device.

- **Migrations live in the repo.** Add them to `pocketbase/pb_migrations/` and push: the
  `addon-image` workflow publishes a new version (bumping the patch number itself if you did not),
  CI regenerates `collections.json`, and Home Assistant offers the update, which applies them.
  The panel shows the running version and the commit it was built from.
- **Drop-in migrations are a hotfix path:** put a `.js` file in
  `/addon_configs/<this add-on>/pb_migrations` (Samba or File editor) or use **Upload a migration**
  in the panel, then **Apply migrations** (restarts the add-on). Until it is committed, the panel
  marks it *not in the repo yet* with **Commit to repo ↗** (GitHub's editor, pre-filled, same
  file name) and **Download**. Once the next version ships it as built-in, the drop-in is ignored
  and never runs twice. Locally, `compose.yaml` mounts `./extra` the same way.

- **Your app's UI at `/`:** `ui/` holds an example web app (plain HTML, signs in with the app
  login). The `ui-release` workflow publishes it as a GitHub release `ui-v<ui/VERSION>` with a
  `dist.zip`; bump `ui/VERSION` to release. At every start the add-on loads the release named by
  `ui_version` (`latest`, a tag, a full URL, or `bundled` for none) from `ui_repo` (default: this
  repository) and serves it at `/`, so the sidebar panel opens your app. The admin page
  (auto-login, setup QR, migrations) moves to **`/_setup/`**. While running, a newer release shows
  up there (and as a Home Assistant notification) with **Update UI**, which swaps it in without a
  restart; the previous build is kept as `old`. Replace `ui/` with any framework's build: the zip
  needs `index.html` at its root and relative URLs (it runs under the ingress prefix).

Details in [`addon/pocketbase_template/DOCS.md`](../addon/pocketbase_template/DOCS.md).

## On an existing PocketBase

No container: in the existing server's dashboard, **Settings → Import collections**, paste
`pocketbase/collections.json` and **merge** (don't delete the other collections). The rules
enforce ownership on their own, so hooks are optional; copy `pocketbase/pb_hooks/` into the
server's `pb_hooks` only if you want the `app-user` command or your own hooks. Create an app
login under **users**. Tested with PocketBase v0.40.4; needs v0.23 or later.

## Change the logins

`just serve` / `just start` (`scripts/pm2.sh`) start with **one shared dev login**:
`admin@local.test` (admin page and app, from `project.env`) with this machine's dev password. It is random, made once, and reused by every project on the
machine, so one password opens all of them:

```sh
cat ~/.config/pocketbase-template/dev-password      # mode 600; never in a repo
```

Compose uses random logins (shown once) unless `.env` sets `PB_DEFAULT_PASSWORD`, which works for
`pm2.sh` too and wins over the shared file. That is fine on `127.0.0.1`; change the logins before
anyone else can reach the server. The Home Assistant add-on never uses a shared password: its
logins are random and shown once.

- **Admin (superuser):** admin UI `/_/` → *System* → *Superusers* → edit, or
  `pocketbase superuser update <email> <new-password> --dir pocketbase/pb_data`
  (in a container: `docker compose exec pocketbase pocketbase superuser update … --dir /data/pb_data`).
- **App user:** admin UI → *Collections* → `users` → the record → *Change password*.
- **New installs with random logins instead:** `PB_DEV_LOGINS=0` in `.env` before the first start.
  Provisioning never resets an existing login, so changing `.env` later has no effect on it.

## Network

Compose binds `127.0.0.1` only. For other devices on your LAN, first
[change the logins](#change-the-logins), then drop the `127.0.0.1:` prefix in `compose.yaml` and set
`PUBLIC_URL`. Before exposing it to the internet, put HTTPS in front
(reverse proxy or tunnel).


## Security notes

- Never commit `pocketbase/pb_data/`, `.env` or `initial-credentials.txt`. `.gitignore` covers
  them and the privacy check refuses them.
- Public sign-up is off: logins are created by an admin or by provisioning.
- Rules are written to hold without hooks; keep it that way (see `AGENTS.md`).

