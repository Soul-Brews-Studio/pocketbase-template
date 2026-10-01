# Tutorial: install your backend on Home Assistant

A repo made from this template is also a Home Assistant add-on store. This walkthrough installs
one, **Catlab Bro** (`nazt/catlab-bro`, created from the template), on a real Home Assistant OS
host and runs the whole loop: install, the sidebar panel with auto-login, a migration added
without a new image and then committed back to the repo, an automatic release, an app UI update
without a restart, and moving the app UI to another source.

Recorded on Home Assistant OS (Supervisor 2026.9) with PocketBase v0.40.4, catlab-bro 0.1.0 →
0.1.11 and app UI ui-v0.1.0 → ui-v0.1.5. Unrelated sidebar entries are blurred; passwords and the
setup QR code are redacted.

**Before you start**

- The repository is **public** and the init workflow has run once: it named the project, gave it
  its own host port, pointed the README buttons at the repo, set `image:` to the prebuilt GHCR
  image and published the first app UI release (`ui-v0.1.0`).
- The `addon-image` workflow is green and the image pulls without a login:
  `curl -s "https://ghcr.io/token?scope=repository:<owner>/amd64-addon-<slug>:pull"` must return a
  token. GHCR packages can start out private; if so, set each package to **Public** once
  (GitHub → Packages → package → Package settings → Change visibility).

## 1. Add the repository

Click **Add the repository to my Home Assistant** in the repo's README, or go to
**Settings → Add-ons → Add-on store → ⋮ → Repositories** and paste the repository URL. Then open
the add-on from the store.

Supervisor keeps its own copy of the repository: after you push a new version, use
**⋮ → Check for updates** in the store to see it now rather than at its next periodic check.

![The store page of Catlab Bro: version 0.1.0, an Ingress badge, and the Install button](images/02-store-page.png)

## 2. Install

Click **Install**. With `image:` set, Supervisor **pulls** the prebuilt image (seconds) instead of
building it on the device (minutes). When it is done the page shows **Start** and a
**Show in sidebar** switch.

![Catlab Bro installed and stopped, with Start, Start on boot, Watchdog and Show in sidebar](images/03-installed.png)

## 3. Check the port

Open **Configuration → Network**. Each project gets its own host port (here **8277**), derived
from its slug by `scripts/rename.sh`, so several PocketBase add-ons can run side by side. The
container itself always listens on 8090.

![The Network section: container port 8090/tcp published on host port 8277](images/04-network-port.png)

> **Trap: "port 8090 is already in use".** Older versions of the template published 8090,
> PocketBase's default. On a host that already runs another PocketBase add-on, **Start** then
> fails with this message. Set a free host port here and save.
>
> ![The error dialog: Cannot start app because port 8090 is already in use](images/00b-port-in-use.png)

## 4. Start and read the log once

Click **Start**. Home Assistant does not start an add-on after installing it; after this first
time, **Start on boot** keeps it running.

![Catlab Bro running, with Stop and Restart](images/05-started.png)

The **Log** tab shows the first-start banner once: the admin login, the app login (random
passwords), the API base on the published port, and where the credentials are kept
(`/data/initial-credentials.txt`, mode 600). Later starts only say where the file is. The log
also says which drop-in migrations were merged and which app UI release was loaded.

![The log: Mode: Home Assistant add-on, the credentials banner with passwords redacted, PocketBase listening on 8090](images/06-log-banner.png)

## 5. Open the sidebar panel: your app

Click **Catlab Bro** in the sidebar. The panel opens the project's **app UI**, the release of
`ui/` named by the `ui_version` option (`latest` by default), served at `/`. The example app
signs in with the app login and sets that user's notes as an index, newest first, with their
dates; the two starter notes come from `pocketbase/seed/notes.json`, loaded once on the first
start. Tick a note to mark it done.

![The app UI in the panel: Catlab Bro, Sign in with the app login, UI ui-v0.1.4 in the footer](images/15-app-ui-signin.png)

![The app UI signed in: two notes set as an index with dotted leaders to their dates, one ticked off](images/16-app-ui-notes.png)

## 6. The admin page: `/_setup/`

The app's **Setup** link (or `/_setup/`) opens the admin page. It asks the add-on for a session
through Home Assistant's ingress: **signed in to Home Assistant = signed in as the PocketBase
admin**, no password. The page reads like the backend's release notes:

- The **first** Home Assistant user to open it claims the add-on; any other user is refused
  afterwards. Ingress is open to every Home Assistant user, not only admins, so the add-on does
  not trust "came through ingress" alone. To allow other users, list their ids in the
  `ha_user_ids` option (or delete `/data/ha-owner` to claim it again).
- **Running 0.1.10**, built from `1db9e5b` (a link to the commit) on PocketBase 0.40.4. When the
  store has a newer version, an **Available** line links to the add-on page to install it.
- **Unreleased**: drop-in migrations that exist only on this device (steps 8 and 9).
- **Set up an app**: the API base, the app login and a one-tap setup link
  (`catlab-bro://setup?u=…&e=…&p=…`) as a QR code. It contains the app password, so it is only
  shown here, and the page masks it.
- **App UI**: the running release, updates and its source (steps 10 and 11).

![The admin page in the panel: Running 0.1.10 built from 1db9e5b, Unreleased with a committed drop-in and the path to delete it, Set up an app with the QR code redacted](images/17-setup-page.png)

## 7. The dashboard, inside the panel

**Open dashboard** shows the PocketBase dashboard right in the panel, already signed in (the
arrow next to it opens it in its own tab). PocketBase normally forbids being framed; the
template's hook allows it for its own origin only, which Home Assistant's ingress shares.

![The PocketBase dashboard inside the Home Assistant panel, signed in as admin, with the users, cats and notes collections](images/13-dashboard-in-panel.png)

## 8. Add a migration without a new image

For a hotfix, a JS migration can be added at runtime: **Upload a migration** on the admin page,
or drop the file into the folder it shows, `/addon_configs/<this add-on>/pb_migrations`, with
the Samba share or the File editor add-on (**Copy path** copies it). The drop-in shows as
**Pending** and **Not in the repo**, dated from the timestamp in its name. **Apply 1 migration**
restarts the add-on, and PocketBase applies it at start; the page waits and reloads itself (about
ten seconds). Here `1790990000_add_toys.js` creates a `toys` collection.

![Unreleased: 1790990000_add_toys.js uploaded, Pending and Not in the repo, with Apply 1 migration and "restarts the add-on"](images/11-migration-uploaded.png)

![After Apply: the migration is Applied but still Not in the repo, with Commit to repo and Download](images/12-migration-applied.png)

## 9. Commit it to the repo

The repository is the source of truth: a migration that only lives in `/addon_configs` is not in
git, a fresh install would not have it, and deleting that folder loses it. So the admin page
keeps it under **Unreleased**, in amber, with **Commit to repo** and **Download**. Commit to repo
opens GitHub's editor with the file already filled in, under `pocketbase/pb_migrations/` with the
**same name**; you commit with your own GitHub login (the add-on stores no token).

![GitHub's new-file page pre-filled: catlab-bro / pocketbase / pb_migrations / 1790990000_add_toys.js on main, with the migration's code](images/18-github-commit-prefilled.png)

The push does the rest, with no manual steps:

- **CI** regenerates `pocketbase/collections.json` and the add-on's copy of `pocketbase/` and
  commits them (a web-editor commit cannot run those scripts).
- **addon-image** sees that the current version is already published, bumps the patch number
  (0.1.10 → 0.1.11), adds a CHANGELOG line with the commit's subject, and publishes the image.

In Home Assistant, **Check for updates**, then **Update**: the changelog lists the commit.

![The update dialog: installed 0.1.10, latest 0.1.11, with the changelog line of the push](images/14-update-0.1.11.png)

After the update the drop-in is skipped (the built-in file of the same name wins) and never runs
again. The admin page says **In the repo** and names the exact file you can delete:

![Unreleased after the update: both drop-ins In the repo, each with the path of the file that can be deleted](images/19-in-the-repo-now.png)

## 10. Update the app UI without a restart

Bump `ui/VERSION` and push: the `ui-release` workflow publishes `ui-v0.1.5` with a `dist.zip`.
UI releases do not create a new add-on version. The admin page checks for a release when it opens
(Home Assistant also shows a notification) and offers **Update to ui-v0.1.5**, which swaps the
new build in while the add-on keeps running; the previous build is kept as `old`.

![App UI: running ui-v0.1.4, ui-v0.1.5 is out, with Update to ui-v0.1.5 and "no restart"; the Source field below](images/20-ui-update-available.png)

The app tells its own users too, who cannot install it themselves:

![The app in the panel with its update bar: a newer version of this app is out, an admin installs it in Setup](images/23-app-update-bar.png)

![App UI after the click: Now running ui-v0.1.5, up to date](images/21-ui-updated.png)

![The app on ui-v0.1.5, the update bar gone](images/22-app-ui-updated.png)

The add-on's log shows the swap (`ui-update: ui-v0.1.4 -> ui-v0.1.5`) and no new start.

## 11. Choose where the app UI comes from

**Source**, under App UI, is the add-on's `ui_version` option, saved through the Supervisor (the
add-on's Configuration tab shows the same value): `latest` follows new releases, a tag such as
`ui-v0.1.4` pins one, a `dist.zip` URL loads that build, and `bundled` serves no app UI. A
release or a URL loads at once, without a restart. Switching to or from `bundled` changes the
folder PocketBase serves, so the page asks for a restart:

![App UI after saving bundled: Restart needed, Saved, it takes effect when the add-on restarts, with Restart now](images/25-ui-source-bundled.png)

With `bundled`, the panel opens the admin page itself; set the source back to `latest` to serve
the app again.

![After the restart: No app UI is served, the panel opens on this page, Source bundled](images/09-panel-signed-in.png)

## Other ways to the same screens

- **Dashboard in its own tab** (the arrow next to Open dashboard):

  ![The PocketBase dashboard signed in as admin, showing the notes collection with the two seeded notes](images/10-dashboard-signed-in.png)

- **Update from the add-on page** when the store shows a new version:

  ![Update available for Catlab Bro](images/07-update-available.png)

  ![The update dialog with the changelog for 0.1.2 and 0.1.1](images/08-update-dialog.png)

## Deploy from your machine: `scripts/ha-deploy.mjs`

Steps 1, 2 and 4 in one command, from a checkout of the repository: it adds the repository if
Home Assistant does not have it, reloads the store, installs or updates the add-on, **starts** it,
and waits until PocketBase answers on the published port.

```sh
scripts/ha-deploy.mjs --ha http://homeassistant.local:8123            # install / update + start
scripts/ha-deploy.mjs --ha http://homeassistant.local:8123 --wait     # right after a git push
scripts/ha-deploy.mjs --ha http://homeassistant.local:8123 --logs     # + the log, passwords masked
```

`--wait` first waits until Home Assistant's store shows this checkout's version (`config.yaml`)
and the GHCR image for the host's architecture exists, so a push, the automatic release and the
update become one step. `--port N` publishes the API on another host port.

It talks to Home Assistant's websocket API as an admin user, with a **long-lived access token**:
your profile → **Security** → **Long-lived access tokens** → **Create token**. Keep it in a file
only you can read and never paste it anywhere else:

```sh
mkdir -p ~/.config/ha-deploy && pbpaste > ~/.config/ha-deploy/homeassistant.token && chmod 600 ~/.config/ha-deploy/homeassistant.token
```

(The file is named after the first part of the host name: `homeassistant.local` →
`homeassistant.token`. `--token-file` or `HA_TOKEN` point elsewhere.) Node 22 or newer.

## Starting over

**⋮ → Uninstall** deletes the add-on **and its data**: the database, the generated credentials
and the panel owner (tick the option to delete the configuration folder too, where drop-ins
live). The next install provisions new logins.

![The uninstall dialog: Catlab Bro and everything in its private data folder will be permanently deleted](images/01-uninstall-confirm.png)
