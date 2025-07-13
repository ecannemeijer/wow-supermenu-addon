# Supermenu Damage & DPS Addon

A modern, modular World of Warcraft Classic AddOn for live group DPS tracking, inspired by Recount. Designed for clarity, transparency, and ease of use.

## Features

- **Live Group DPS Table**
  - Tracks and displays real-time DPS and total damage for all group/raid members.
  - Includes pet damage, attributed to the owner.
  - Class-colored names and bold highlight for your character.
  - Dynamic bar graph visualization, scaled to top damage.
  - Resizable, movable, and transparent window overlay.

- **Recount-Style UI**
  - Modern, clean look with flat, semi-transparent background.
  - Icon-based close, reset, and history toggle buttons.
  - Professional column and header alignment.
  - Minimum bar width for visibility, even at low damage.

- **History Feature**
  - Toggle between current session and history view.
  - History table shows last 10 dungeon/encounter runs.
  - Columns: #, Name (mob/boss/zone), DPS, Total Damage.
  - Bar graph and tooltips for each run.
  - Dungeon run log is capped at 200 entries for performance.

- **Reset Button**
  - Clears both real-time DPS and history log.

- **Automatic Combat Detection**
  - Resets timers and damage on combat start/end.
  - Tracks zone and mob/boss names for history.

- **Comprehensive Damage Tracking**
  - Includes all major damage event types:
    - SWING_DAMAGE, SPELL_DAMAGE, SPELL_PERIODIC_DAMAGE, RANGE_DAMAGE
    - DAMAGE_SHIELD, DAMAGE_SPLIT, ENVIRONMENTAL_DAMAGE
  - Pet and guardian damage is included and attributed to the owner.

- **Performance**
  - Efficient event handling and UI updates (throttled to 0.2s).
  - Minimal memory usage, even in large raids.

- **Classic API Compatible**
  - Works with WoW Classic and Season of Discovery.

## Usage

- `/supermenu` to open the main menu (see Supermenu.lua for slash commands).
- Click the parchment icon to toggle history.
- Click the gold coin icon to reset DPS and history.
- Drag the window or resize from the bottom-right corner.

## File Structure
- `DamageWindow.lua` — Main UI and table logic
- `DungeonTracking.lua` — Combat log event tracking and history
- `Supermenu.lua` — AddOn entry point and slash commands
- `Supermenu.toc` — AddOn manifest
- `Logs/DungeonRuns.log` — Saved run history

## Credits
- Inspired by Recount and Details! Damage Meter
- Developed by ecannemeijer

---

For bug reports or feature requests, open an issue on GitHub.