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
import uuid  # Add this import for UUID generation

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

def update_topplays() -> None:
    """
    Scan all entries in TopPlays, update points based on difficulty,
    sort by points, keep top 3, and save back to the datastore.
    Also ensures each topplay has a uuid.
    """
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    logging.info("▶ Updating TopPlays entries...")
    
    store_name = "TopPlays"
    cursor = None
    total_updated = 0
    
    # Define difficulty multipliers
    difficulty_multipliers = {
        "easy": 1,
        "medium": 2,
        "hard": 3
    }
    
    while True:
        try:
            # Get a page of entries
            page = list_keys(store_name, cursor)
            keys = [k["key"] for k in page.get("keys", [])]
            
            if not keys:
                break  # no more data
            
            logging.info(f"Processing batch of {len(keys)} keys")
            
            for key in keys:
                try:
                    # Get the entry value (list of TopPlays)
                    topplays = get_key_value(store_name, key)
                    
                    if not isinstance(topplays, list):
                        logging.warning(f"Entry {key} is not a list, skipping")
                        continue
                    
                    # Update points based on difficulty and ensure each topplay has a uuid
                    for play in topplays:
                        # Add UUID if missing
                        if 'uuid' not in play:
                            play['uuid'] = str(uuid.uuid4())
                            logging.info(f"Added UUID {play['uuid']} to a topplay for {key}")
                        
                        difficulty = play.get('theme_difficulty', 'medium').lower()
                        multiplier = difficulty_multipliers.get(difficulty, 1)
                        play['points'] = play['score'] * multiplier
                    
                    # Sort by points in descending order
                    topplays.sort(key=lambda x: x.get('points', 0), reverse=True)
                    
                    # Keep only top 3
                    topplays = topplays[:3]
                    
                    # Save back to the datastore
                    update_key(store_name, key, topplays)
                    
                    total_updated += 1
                    
                except Exception as e:
                    logging.error(f"Error processing key {key}: {e}")
                
                # Add a small delay between individual key updates
                time.sleep(0.5)
            
            logging.info(f"Updated {total_updated} keys so far")
            
            cursor = page.get("nextPageCursor")
            if not cursor:
                break  # reached final page
            
            # Add a delay between pages to avoid rate limits
            time.sleep(2)
            
        except requests.HTTPError as e:
            logging.error(f"HTTP error during batch processing: {e}")
            # Back off for a longer period if we hit rate limits
            if e.response.status_code == 429:
                logging.info("Rate limit hit, waiting 30 seconds...")
                time.sleep(30)
            else:
                raise
    
    logging.info(f"✔ TopPlays update complete. Updated {total_updated} entries.")

def update_key(store: str, key: str, value: any) -> None:
    """Update an entry with a new value."""
    params = {
        "datastoreName": store,
        "entryKey": key,
    }
    url = f"{BASE}/datastore/entries/entry"
    headers = HEADERS.copy()
    headers["Content-Type"] = "application/json"
    
    r = requests.post(url, headers=headers, params=params, json=value, timeout=REQUEST_TIMEOUT)
    r.raise_for_status()

def update_theme_summaries() -> None:
    """
    Scan all themes in the Themes datastore, create a theme summary for each one.
    Store the list of summaries in the Themes datastore under the key "all_theme_summaries".
    """
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    logging.info("▶ Scanning all themes and creating summaries...")
    
    source_store_name = "Themes"
    target_store_name = "Themes"
    cursor = None
    total_themes = 0
    theme_summaries = []
    
    # First, scan all themes and create summaries
    while True:
        try:
            # Get a page of themes
            page = list_keys(source_store_name, cursor)
            keys = [k["key"] for k in page.get("keys", [])]
            
            if not keys:
                break  # no more data
            
            logging.info(f"Processing batch of {len(keys)} themes")
            
            for key in keys:
                try:
                    # Get the theme data
                    theme = get_key_value(source_store_name, key)
                    
                    if not isinstance(theme, dict):
                        logging.warning(f"Entry {key} is not a valid theme dictionary, skipping")
                        continue
                    
                    # Create a theme summary (similar to makeThemeSummary in the Lua code)
                    theme_summary = {
                        "uuid": theme.get("uuid"),
                        "Name": theme.get("Name"),
                        "Description": theme.get("Description", "")[:300],  # Limit description to 300 chars
                        "CreatedBy": theme.get("CreatedBy"),
                        "TotalPlayCount": theme.get("TotalPlayCount", 0),
                        "CreatedAt": theme.get("CreatedAt"),
                        "Duration": theme.get("Duration"),
                        "Difficulty": theme.get("Difficulty"),
                        "Likes": theme.get("Likes", 0),
                        "Code": theme.get("Code")
                    }
                    
                    theme_summaries.append(theme_summary)
                    total_themes += 1
                    logging.info(f"  • Processed theme: {theme.get('Name', 'Unknown')} ({theme.get('uuid', 'No UUID')})")
                    
                except Exception as e:
                    logging.error(f"Error processing theme key {key}: {e}")
                
                # Add a small delay between individual theme processing
                time.sleep(0.5)
            
            logging.info(f"Processed {total_themes} themes so far")
            
            cursor = page.get("nextPageCursor")
            if not cursor:
                break  # reached final page
            
            # Add a delay between pages to avoid rate limits
            time.sleep(BACKOFF_SECONDS)
            
        except requests.HTTPError as e:
            logging.error(f"HTTP error during batch processing: {e}")
            # Back off for a longer period if we hit rate limits
            if e.response.status_code == 429:
                logging.info("Rate limit hit, waiting 30 seconds...")
                time.sleep(30)
            else:
                raise
    
    # Now store the list of theme summaries in the target datastore
    if theme_summaries:
        try:
            # Use a fixed key for the list of summaries
            list_key = "all_theme_summaries"
            
            # Store the list in the target datastore
            update_key(target_store_name, list_key, theme_summaries)
            
            logging.info(f"✔ Successfully stored {len(theme_summaries)} theme summaries to {target_store_name}")
        except Exception as e:
            logging.error(f"Error storing theme summaries: {e}")
    else:
        logging.info("No themes found to summarize.")

def main() -> None:
    if not (UNIVERSE_ID and API_KEY):
        sys.exit("ERROR: set ROBLOX_UNIVERSE_ID and ROBLOX_API_KEY env vars first")

    logging.basicConfig(level=logging.INFO, format="%(message)s")
    
    # Add option to run the update_topplays function
    action = input("Select action (1: Wipe datastores, 2: Update TopPlays, 3: Update Theme Summaries): ")
    
    if action == "1":
        enable_wipe = input("Enable wipe? (y/n): ")
        if enable_wipe == "y":
            for name in STORE_NAMES:
                try:
                    wipe_store(name)
                except requests.HTTPError as e:
                    logging.error("✖ failed on datastore '%s': %s", name, e)
                except KeyboardInterrupt:
                    sys.exit("\nAborted by user")
    
    elif action == "2":
        confirm = input("Update TopPlays points calculation? (y/n): ")
        if confirm == "y":
            update_topplays()
    
    elif action == "3":
        confirm = input("Update theme summaries in ThemeSummaries datastore? (y/n): ")
        if confirm == "y":
            update_theme_summaries()
    
    logging.info("🏁 all done")

if __name__ == "__main__":
    main()
