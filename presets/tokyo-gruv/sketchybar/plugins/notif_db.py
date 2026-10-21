#!/usr/bin/env python3
# reads the macOS notification center and prints the latest slack / discord / messenger notifications
# one per line: app <tab> who <tab> text (newest first, already cut to fit the popup)
# arg 1 = unix time when messenger was last opened from the bar, older messenger stuff is skipped
# needs Full Disk Access for sketchybar, without it just prints "#nodb"

import os
import sys
import time
import sqlite3
import plistlib
from urllib.parse import quote

db_path = os.path.expanduser("~/Library/Group Containers/group.com.apple.usernoted/db2/db")

# bundle id -> name on the bar
# messenger has no mac app anymore, so it's firefox (filtered below)
apps = {
    "com.tinyspeck.slackmacgap": "slack",
    "com.hnc.discord": "discord",
    "org.mozilla.firefox": "messenger",
}

# messenger notifications older than this don't count as new
max_age = 12 * 3600
# notification center counts seconds from 2001, unix from 1970
apple_epoch = 978307200

sys.stdout.reconfigure(encoding="utf-8")

seen = 0
if len(sys.argv) > 1:
    try:
        seen = float(sys.argv[1])
    except ValueError:
        seen = 0


def short(s, n):
    s = " ".join(str(s).split())
    if len(s) > n:
        s = s[:n - 1] + "…"
    return s


try:
    con = sqlite3.connect("file:" + quote(db_path) + "?mode=ro", uri=True)
    rows = con.execute(
        "select a.identifier, r.data, r.delivered_date from record r "
        "join app a on a.app_id = r.app_id "
        "order by r.delivered_date desc limit 300"
    ).fetchall()
except Exception:
    print("#nodb")
    sys.exit(0)

now = time.time()
for bundle, data, delivered in rows:
    app = apps.get(str(bundle).lower())
    if app is None:
        continue

    try:
        req = plistlib.loads(data).get("req", {})
    except Exception:
        continue

    title = req.get("titl") or ""
    sub = req.get("subt") or ""
    body = req.get("body") or ""
    when = (delivered or 0) + apple_epoch

    if app == "messenger":
        # firefox shows notifications from every site, keep only messenger / facebook ones
        everything = str(req).lower()
        if "messenger" not in everything and "facebook" not in everything:
            continue
        if when < seen or now - when > max_age:
            continue

    text = body
    if sub:
        text = sub + " · " + body

    print(app + "\t" + short(title, 18) + "\t" + short(text, 44))
