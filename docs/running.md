# Running it

## Without Docker

Needs the `pocketbase` binary (the version pinned in the Dockerfile).

```sh
scripts/provision.sh       # creates pocketbase/pb_data, the logins, prints the banner once
pocketbase serve --dir pocketbase/pb_data \
  --migrationsDir pocketbase/pb_migrations --hooksDir pocketbase/pb_hooks
```

## As a Home Assistant add-on

The repository root is also a Home Assistant add-on repository. In Home Assistant: **Settings →
Add-ons → Add-on store → ⋮ → Repositories**, add `https://github.com/<you>/<repo>`, install
the add-on, start it, and read the **Log** tab for the logins. Details in
[`addon/pocketbase_template/DOCS.md`](addon/pocketbase_template/DOCS.md).

## On an existing PocketBase

No container: in the existing server's dashboard, **Settings → Import collections**, paste
`pocketbase/collections.json` and **merge** (don't delete the other collections). The rules
enforce ownership on their own, so hooks are optional; copy `pocketbase/pb_hooks/` into the
server's `pb_hooks` only if you want the `app-user` command or your own hooks. Create an app
login under **users**. Tested with PocketBase v0.40.4; needs v0.23 or later.

## Network

Compose binds `127.0.0.1` only. For other devices on your LAN, drop the `127.0.0.1:` prefix in
`compose.yaml` and set `PUBLIC_URL`. Before exposing it to the internet, put HTTPS in front
(reverse proxy or tunnel).


## Security notes

- Never commit `pocketbase/pb_data/`, `.env` or `initial-credentials.txt`. `.gitignore` covers
  them and the privacy check refuses them.
- Public sign-up is off: logins are created by an admin or by provisioning.
- Rules are written to hold without hooks; keep it that way (see `AGENTS.md`).

