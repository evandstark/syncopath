# Syncopath

A neurotically helpful macOS SwiftBar plugin for live monitoring your Syncthing folder status — with:

- Realtime sync status in the macOS menu bar
- Live menu bar icons: ✅ syncing, 📡 syncing, ⚠️ errors, ❌ stopped
- One-click Pause/Resume, Restart, and Web UI access
- Auto-restart if Syncthing crashes
- Sync progress %, remaining MB, file count
- Stale sync detection with push alerts
- Background `launchd` watchdog for off-menubar resilience

Because you’ve got **commitment issues**, and **Syncopath doesn’t trust you either**.

Prompt-assisted by ChatGPT, who refused to let the author vibe code into oblivion.

## Features

- Monitors a specific folder (default: `dev-sync`)
- Alerts you if sync hasn't completed in X minutes
- Automatically restarts Syncthing if it's not running
- Custom icons, menu actions, and notification integration
- Compatible with SwiftBar

## Prerequisites
- Syncthing running as a local service (`brew install syncthing && brew services start syncthing`)
- Syncthing using SSL on `8384`. Update `SYNCTHING_URL` if necesnotsary.
- The host CLI is `ARM64`. IDEs often use `i386` (Rosetta) for integrated CLI.
`jq` and `curl` (`brew install jq curl`)

## Setup

After cloning the repo:

```bash
cd syncopath
make install
```

## Customization

### Authentication
If your Syncthing GUI uses authentication, add your API key to AUTH_HEADER in `SyncthingDev.10s.sh`:

   ```bash
   AUTH_HEADER="X-API-Key: your_real_api_key_here"
   ```

### Host, Port, and SSL
Edit the following in the script to match your Syncthing folder setup:

In `Makefile`:

   ```bash
   SYNCTHING_URL ?= https://127.0.0.1:8384
   ```

In `SyncthingDev.10s.sh`:

    ```bash
    FOLDER_ID="dev-sync"
    ST_API="https://127.0.0.1:8384"
   ```

## Other Commands

### `make logs`
Tails Syncopath’s activity log `(~/.syncthing-dev-sync.log`) for sync events, warnings, and watchdog status.

### `make clean`
- Removes Syncopath logs and tracking files.
- Does not stop Syncthing or uninstall anything.

## License

MIT License. Feel free to fork and extend.

