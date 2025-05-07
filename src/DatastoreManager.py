#!/usr/bin/env python3
"""
wipe_datastores.py
Delete every key in the chosen standard data stores of a universe
using Roblox Open Cloud (v1) REST endpoints.

Requires:
  • Python 3.8+
  • `pip install requests`
  • A Roblox Open Cloud API key with
        - "Read" AND "Write" permission
        - Datastore → Delete Entries
        - restricted to the datastores you're wiping
"""

from __future__ import annotations
import os
import sys
import time
import logging
from dotenv import load_dotenv
from typing import List, Optional

import requests

load_dotenv()

# ────────────────────── CONFIG ────────────────────── #

UNIVERSE_ID = os.getenv("ROBLOX_UNIVERSE_ID")  # e.g. "3310576216"
API_KEY     = os.getenv("ROBLOX_API_KEY")      # your x-api-key secret

STORE_NAMES: List[str] = [
    # "Themes",
    # "ThemeCodes",
    "PlayerBestDrawings",
    "Players",
    "TopPlays",
]

# Optional: limit + back-off
PAGE_LIMIT      = 100     # max keys per List-Entries call (100 is API max)
REQUEST_TIMEOUT = 10      # seconds
BACKOFF_SECONDS = 0.25    # pause after each page to avoid 429s

# ─────────────────── helper functions ─────────────────── #

BASE = "https://apis.roblox.com/datastores/v1/universes/{uid}/standard-datastores".format(
    uid=UNIVERSE_ID
)
HEADERS = {
    "x-api-key": API_KEY,
    # The v1 endpoints treat parameters as query-string, so
    # we can leave Content-Type out for GET / DELETE calls.
}

def list_keys(store: str, cursor: Optional[str] = None) -> dict:
    """Call List Entries for one datastore (optionally continuing from a cursor)."""
    params = {
        "datastoreName": store,
        "limit": PAGE_LIMIT,
    }
    if cursor:
        params["cursor"] = cursor

    url = f"{BASE}/datastore/entries"
    r = requests.get(url, headers=HEADERS, params=params, timeout=REQUEST_TIMEOUT)
    r.raise_for_status()
    return r.json()           # {"keys":[{"key":"…"}, …], "nextPageCursor": "…"}

def get_key_value(store: str, key: str) -> any:
    """GET an entry's value."""
    params = {
        "datastoreName": store,
        "entryKey":      key,
    }
    url = f"{BASE}/datastore/entries/entry"
    r = requests.get(url, headers=HEADERS, params=params, timeout=REQUEST_TIMEOUT)
    r.raise_for_status()
    # The response is the value itself (JSON, string, number, boolean)
    # For Roblox, it's often JSON, so we try to parse it.
    try:
        return r.json()
    except requests.exceptions.JSONDecodeError:
        return r.text # Or handle as appropriate if non-JSON is expected

def list_key_values(store: str, cursor: Optional[str] = None) -> dict:
    """Call List Entries for one datastore and retrieve values for each key."""
    key_listing_page = list_keys(store, cursor)
    entries_with_values = []

    keys_info = key_listing_page.get("keys", [])
    for key_info in keys_info:
        key = key_info["key"]
        try:
            value = get_key_value(store, key)
            entries_with_values.append({"key": key, "value": value})
        except requests.HTTPError as e:
            logging.warning(f"  • failed to get value for key '{key}': {e}")
            # Optionally, append with a placeholder or skip
            entries_with_values.append({"key": key, "value": None, "error": str(e)})


    return {
        "entries": entries_with_values,
        "nextPageCursor": key_listing_page.get("nextPageCursor")
    }

def delete_key(store: str, key: str) -> None:
    """DELETE an entry."""
    params = {
        "datastoreName": store,
        "entryKey":      key,
    }
    url = f"{BASE}/datastore/entries/entry"
    r = requests.delete(url, headers=HEADERS, params=params, timeout=REQUEST_TIMEOUT)
    # Success is "204 No Content"; anything else → raise
    if r.status_code != 204:
        r.raise_for_status()

# ─────────────────────── main flow ─────────────────────── #

def wipe_store(store: str) -> None:
    logging.info("▶ wiping datastore '%s'…", store)
    cursor = None
    total_deleted = 0

    while True:
        page = list_keys(store, cursor)
        keys = [k["key"] for k in page.get("keys", [])]

        if not keys:
            break  # no more data

        for k in keys:
            delete_key(store, k)
            total_deleted += 1

        logging.info("  • deleted %d keys so far", total_deleted)
        cursor = page.get("nextPageCursor")
        if not cursor:
            break                # reached final page

        time.sleep(BACKOFF_SECONDS)

    logging.info("✔ datastore '%s' is now empty (%d keys removed)", store, total_deleted)

def main() -> None:
    if not (UNIVERSE_ID and API_KEY):
        sys.exit("ERROR: set ROBLOX_UNIVERSE_ID and ROBLOX_API_KEY env vars first")

    logging.basicConfig(level=logging.INFO, format="%(message)s")
    for name in STORE_NAMES:
        try:
            wipe_store(name)
        except requests.HTTPError as e:
            logging.error("✖ failed on datastore '%s': %s", name, e)
        except KeyboardInterrupt:
            sys.exit("\nAborted by user")

    logging.info("🏁 all done")

# This is modifying production data, be very careful when running this script
# if __name__ == "__main__":
#     enable_wipe = input("Enable wipe? (y/n): ")
#     if enable_wipe == "y":
#         main()

entries = list_key_values("Themes")

for e in entries["entries"]:
    print(e["value"]["Name"] + " " + e["value"]["Difficulty"])
