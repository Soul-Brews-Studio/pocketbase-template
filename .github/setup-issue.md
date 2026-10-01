This repository was created from the PocketBase backend template. Work through this list once to
turn it into your project; an AI coding agent can do it for you (see the bottom).

## Checklist

- [ ] **Name it:** `scripts/rename.sh "<Project Name>" <slug> "<one-line purpose>"`
      (slug: lowercase letters, digits, underscores)
- [ ] **README:** rewrite the intro for this project
- [ ] **Schema:** replace the example `notes` collection in `pb_migrations/` with your own
      collections and owner rules (pattern in `AGENTS.md` → *Add a collection*)
- [ ] **Tests:** matching checks in `scripts/e2e.mjs`
- [ ] **Regenerate:** `scripts/export-collections.sh` and `scripts/sync-addon.sh`
- [ ] **Verify:** `scripts/local-e2e.sh` → `LOCAL E2E: ALL PASS`, `python3 scripts/privacy_check.py`
- [ ] **Run it:** `docker compose up --build -d`, logins in `docker compose logs` (shown once)
- [ ] Optional: install as a Home Assistant add-on (README → *Home Assistant add-on*)

## Let an AI do it

Open the repo in Claude Code, Codex or another coding agent and say:

> Set up this template for my project, following AGENTS.md. Work on issue #__ISSUE__.

It will ask for the project name, purpose and data model first. Answer here or in the chat.

## Never commit

`pb_data/`, `.env`, `initial-credentials.txt`: the logins and data of your running server.
Do not paste the generated passwords into this issue.

---
Opened automatically by `.github/workflows/init.yml`. Close it when the checklist is done.
