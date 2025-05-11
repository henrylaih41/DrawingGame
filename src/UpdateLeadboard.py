"""
Scans a datastore named 'Players', then copies each player's 'TotalPoints' into
a Roblox MemoryStore SortedMap using Open Cloud (v1) REST endpoints.

Requirements:
  • Python 3.8+
  • `pip install requests python-dotenv`
  • Roblox Open Cloud API key with:
      - Datastore (Read, Delete)
      - MemoryStore (Write)
"""

import os
import sys
import time
import logging
from dotenv import load_dotenv
from typing import Optional

import requests

load_dotenv()

# ────────────────────── CONFIG ────────────────────── #

UNIVERSE_ID = os.getenv("ROBLOX_UNIVERSE_ID")
API_KEY = os.getenv("ROBLOX_API_KEY")

PLAYER_DATASTORE_NAME = "Players"
MEMORYSTORE_SORTED_MAP_NAME = "TopPointsV2"

# API endpoints
DATASTORE_BASE = f"https://apis.roblox.com/datastores/v1/universes/{UNIVERSE_ID}/standard-datastores"
MEMORYSTORE_BASE = "https://apis.roblox.com/memory-store/v1"

# Request limits and headers
REQUEST_TIMEOUT = 10
PAGE_LIMIT = 100
BACKOFF_SECONDS = 0.25
HEADERS = {"x-api-key": API_KEY, "Content-Type": "application/json"}

# ────────────────────── Helpers ────────────────────── #

def list_keys(store: str, cursor: Optional[str] = None) -> dict:
    params = {"datastoreName": store, "limit": PAGE_LIMIT}
    if cursor:
        params["cursor"] = cursor

    url = f"{DATASTORE_BASE}/datastore/entries"
    r = requests.get(url, headers=HEADERS, params=params, timeout=REQUEST_TIMEOUT)
    r.raise_for_status()
    return r.json()

def get_key_value(store: str, key: str) -> any:
    params = {"datastoreName": store, "entryKey": key}
    url = f"{DATASTORE_BASE}/datastore/entries/entry"
    r = requests.get(url, headers=HEADERS, params=params, timeout=REQUEST_TIMEOUT)
    r.raise_for_status()
    return r.json()

def memorystore_update_sorted_map(map_name: str, key: str, value: int, sortKey: int) -> None:
    url = f"{MEMORYSTORE_BASE}/sorted-maps/{map_name}/entries/entry"
    params = {"universeId": UNIVERSE_ID}
    data = {"key": key, "value": value, "sortKey": sortKey}

    r = requests.post(url, headers=HEADERS, params=params, json=data, timeout=REQUEST_TIMEOUT)
    r.raise_for_status()

# ────────────────────── Main Logic ────────────────────── #

def packValue(userId, playerName, points) -> dict:
    return {
        "uid": userId,
        "name": playerName,
        "points": points
    }

def scan_and_copy_players() -> None:
    logging.info("▶ scanning datastore '%s' and copying to MemoryStore '%s'", PLAYER_DATASTORE_NAME, MEMORYSTORE_SORTED_MAP_NAME)
    
    cursor = None
    total_processed = 0

    while True:
        page = list_keys(PLAYER_DATASTORE_NAME, cursor)
        keys = [k["key"] for k in page.get("keys", [])]

        if not keys:
            break

        for player_key in keys:
            try:
                player_data = get_key_value(PLAYER_DATASTORE_NAME, player_key)
                total_points = player_data.get("TotalPoints")
                player_id = player_key.split("_")[1]
                value = packValue(player_id, player_data.get("Name"), total_points)
                if isinstance(total_points, int):
                    memorystore_update_sorted_map(MEMORYSTORE_SORTED_MAP_NAME, player_key, value, sortKey=total_points)
                    total_processed += 1
                    logging.info("  • copied player '%s' with TotalPoints=%d", player_key, total_points)
                    print(value)
                else:
                    logging.warning("  • player '%s' missing valid 'TotalPoints'", player_key)

            except requests.HTTPError as e:
                logging.error("  ✖ failed to process key '%s': %s", player_key, e)

        cursor = page.get("nextPageCursor")
        if not cursor:
            break

        time.sleep(BACKOFF_SECONDS)

    logging.info("✔ completed: %d players copied", total_processed)

# ────────────────────── Entry Point ────────────────────── #

def main() -> None:
    if not (UNIVERSE_ID and API_KEY):
        sys.exit("ERROR: ROBLOX_UNIVERSE_ID and ROBLOX_API_KEY must be set")

    logging.basicConfig(level=logging.INFO, format="%(message)s")

    try:
        scan_and_copy_players()
    except KeyboardInterrupt:
        sys.exit("\nAborted by user")

    logging.info("🏁 all done")

if __name__ == "__main__":
    main()