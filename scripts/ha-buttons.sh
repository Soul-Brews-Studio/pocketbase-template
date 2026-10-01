#!/usr/bin/env bash
# Point the Home Assistant links at this repository: `url:` in repository.yaml and the two
# "My Home Assistant" buttons in README.md (add the repository / open the add-on).
#   scripts/ha-buttons.sh https://github.com/<owner>/<repo>
# Home Assistant names a store add-on <first 8 hex of sha1(repository URL)>_<slug>, so the
# "open the add-on" link changes with the repository URL and the add-on slug. Idempotent;
# the init workflow runs it on the first push.
set -euo pipefail
url="${1:?usage: scripts/ha-buttons.sh https://github.com/<owner>/<repo>}"; url="${url%/}"; url="${url%.git}"
here="$(cd "$(dirname "$0")/.." && pwd)"; cd "$here"
slug="$(sed -n 's/^ADDON_SLUG=//p' project.env | tail -n 1)"
id="$(printf '%s' "$url" | python3 -c 'import hashlib,sys; print(hashlib.sha1(sys.stdin.read().encode()).hexdigest()[:8])')_$slug"
enc="$(python3 -c 'import sys,urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$url")"

if grep -q '^url:' repository.yaml; then
  sed -E "s|^url:.*|url: $url|" repository.yaml > repository.yaml.tmp && mv repository.yaml.tmp repository.yaml
else
  printf 'url: %s\n' "$url" >> repository.yaml
fi

block="<!-- ha-buttons -->
[![Add the repository to my Home Assistant](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=$enc)
[![Open the add-on in my Home Assistant](https://my.home-assistant.io/badges/supervisor_addon.svg)](https://my.home-assistant.io/redirect/supervisor_addon/?addon=$id&repository_url=$enc)
<!-- /ha-buttons -->"
BLOCK="$block" python3 - <<'PY'
import os, re
p = "README.md"; s = open(p, encoding="utf-8").read(); b = os.environ["BLOCK"]
if "<!-- ha-buttons -->" in s:
    s = re.sub(r"<!-- ha-buttons -->.*?<!-- /ha-buttons -->", lambda m: b, s, flags=re.S)
else:  # after the title line and its badges
    lines = s.split("\n"); i = 1
    while i < len(lines) and (lines[i].strip() == "" or lines[i].startswith(("[![", "!["))): i += 1
    lines[i:i] = [b, ""]; s = "\n".join(lines)
open(p, "w", encoding="utf-8").write(s)
PY
echo "Home Assistant links -> $url (add-on $id)"
