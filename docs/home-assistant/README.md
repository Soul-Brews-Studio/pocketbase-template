# Tutorial: install your backend on Home Assistant

A repo made from this template is also a Home Assistant add-on store. This walkthrough installs
one, **Catlab Bro** (`nazt/catlab-bro`, created from the template), on a real Home Assistant OS
host, then opens its sidebar panel, which signs you in to the PocketBase dashboard.

Recorded on Home Assistant OS with Supervisor 2026.9, PocketBase v0.40.4 and catlab-bro 0.1.0 →
0.1.2. Unrelated sidebar entries are blurred; passwords and the QR code are redacted.

**Before you start**

- The repository is **public** and the init workflow has run once: it named the project, gave it
  its own host port, pointed the README buttons at the repo and set `image:` to the prebuilt
  GHCR image.
- The `addon-image` workflow is green and the image pulls without a login:
  `curl -s "https://ghcr.io/token?scope=repository:<owner>/amd64-addon-<slug>:pull"` must return a
  token. GHCR packages can start out private; if so, set each package to **Public** once
  (GitHub → Packages → package → Package settings → Change visibility).

## 1. Add the repository

Click **Add the repository to my Home Assistant** in the repo's README, or go to
**Settings → Add-ons → Add-on store → ⋮ → Repositories** and paste the repository URL. Then open
the add-on from the store.

If you change the repository later (a new version, or you deleted and re-created it), use
**⋮ → Check for updates** in the store: Supervisor keeps its own copy until then.

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

## 4. Start

Click **Start**. Home Assistant does not start an add-on after installing it; after this first
time, **Start on boot** keeps it running.

![Catlab Bro running, with Stop and Restart](images/05-started.png)

## 5. Read the log once

The **Log** tab shows the first-start banner: the admin login, the app login (random passwords,
printed **once**), the API base on the published port, and where the credentials are kept
(`/data/initial-credentials.txt`, mode 600). Copy the passwords somewhere safe now. Later starts
only say where the file is.

![The log: Mode: Home Assistant add-on, the credentials banner with passwords redacted, PocketBase listening on 8090](images/06-log-banner.png)

## 6. Open the sidebar panel

Click **Catlab Bro** in the sidebar. The panel asks the add-on for a session through Home
Assistant's ingress: **signed in to Home Assistant = signed in to PocketBase**, no password.

- The **first** Home Assistant user to open the panel claims the add-on; any other user is refused
  afterwards. Ingress is open to every Home Assistant user, not only admins, so the add-on does
  not trust "came through ingress" alone. To allow other users, list their ids in the
  `ha_user_ids` option (or delete `/data/ha-owner` to claim it again).
- **Set up an app** shows the API base, the app login and a one-tap setup link
  (`catlab-bro://setup?u=…&e=…&p=…`) as a QR code. It contains the app password: it is only shown
  in this signed-in panel.

![The panel: signed in as the admin, Open dashboard, and Set up an app with the API base, app login and a redacted QR code](images/09-panel-signed-in.png)

## 7. Open the dashboard

PocketBase's dashboard does not allow itself to be shown inside another page, so **Open
dashboard ↗** opens it in its own tab, already signed in. The two starter notes come from
`pocketbase/seed/notes.json`, loaded once on the first start.

![The PocketBase dashboard signed in as admin, showing the notes collection with the two seeded notes](images/10-dashboard-signed-in.png)

## 8. Update to a new version

Push a change with a higher `version:` in the add-on's `config.yaml`; `addon-image` publishes the
new image. In Home Assistant use **⋮ → Check for updates** in the store; the add-on page then
offers **Update** with the changelog.

![Update available for Catlab Bro](images/07-update-available.png)

![The update dialog with the changelog for 0.1.2 and 0.1.1](images/08-update-dialog.png)

The update pulled 0.1.2 and restarted the add-on in 18 seconds. Data in `/data` (the database,
the credentials, the panel owner) is kept.

## Starting over

**⋮ → Uninstall** deletes the add-on **and its data**: the database, the generated credentials
and the panel owner. The next install provisions new logins.

![The uninstall dialog: Catlab Bro and everything in its private data folder will be permanently deleted](images/01-uninstall-confirm.png)
