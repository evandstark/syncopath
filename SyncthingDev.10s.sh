#!/bin/bash

# <swiftbar.icon>https://raw.githubusercontent.com/evandstark/syncopath/main/icon.png</swiftbar.icon>
# <swiftbar.title>Syncopath</swiftbar.title>
# <swiftbar.desc>Live Syncthing monitor with progress, auto-heal, alerts, and background watchdog</swiftbar.desc>
# <swiftbar.refreshOnOpen>true</swiftbar.refreshOnOpen>
# <swiftbar.version>4.0</swiftbar.version>
# <swiftbar.author>Evan + ChatGPT</swiftbar.author>
# <swiftbar.author.github>evandstark</swiftbar.author.github>
# <swiftbar.dependencies>jq, curl</swiftbar.dependencies>


ST_API="https://127.0.0.1:8384"
FOLDER_ID="dev-sync"
AUTH_HEADER="X-API-Key: xW4G5nk24poFVsS3UPhd5fjUwjYPjd7W"
TRACK_FILE="$HOME/.syncthing-dev-last-sync"
LOG_FILE="$HOME/.syncthing-dev-sync.log"
STALE_LIMIT_MINUTES=60
ICON_SYNCING="📡"
ICON_IDLE="✅"
ICON_WARN="⚠️"
ICON_DOWN="❌"

function log {
  echo "$(date '+%F %T') — $1" >> "$LOG_FILE"
}

function notify {
  osascript -e "display notification \"$1\" with title \"Syncthing Dev\""
}

NOW_EPOCH=$(date +%s)

# 1. Check if Syncthing is running
if ! pgrep -x "syncthing" > /dev/null; then
  echo "Syncthing: $ICON_DOWN"
  echo "---"
  echo "Syncthing was not running. Attempting restart..."
  notify "Syncthing not running. Restarting..."
  log "Syncthing not detected — restarting"
  brew services restart syncthing >/dev/null 2>&1
  sleep 5
  echo "Restart issued. Refreshing..."
  exit 0
fi

# 2. Get folder sync status
STATUS=$(curl -s -H "$AUTH_HEADER" "$ST_API/rest/db/status?folder=$FOLDER_ID" | jq -r '.state')
GLOBAL_STATS=$(curl -s -H "$AUTH_HEADER" "$ST_API/rest/stats/folder?folder=$FOLDER_ID")
PAUSED=$(curl -s -H "$AUTH_HEADER" "$ST_API/rest/config" | jq -r --arg id "$FOLDER_ID" '.folders[] | select(.id==$id) | .paused')

# 3. Compute sync progress
IN_SYNC_BYTES=$(echo "$GLOBAL_STATS" | jq -r '."globalBytes"')
NEED_BYTES=$(echo "$GLOBAL_STATS" | jq -r '."needBytes"')
NEED_FILES=$(echo "$GLOBAL_STATS" | jq -r '."needFiles"')
BYTES_REMAINING=${NEED_BYTES:-0}
PROGRESS=$(( (IN_SYNC_BYTES - BYTES_REMAINING) * 100 / (IN_SYNC_BYTES + 1) ))
HUMAN_MB_LEFT=$(printf "%.2f" "$(echo "$BYTES_REMAINING / 1048576" | bc -l)")

# 4. Track last sync time
LAST_SYNC_EPOCH=0
[ -f "$TRACK_FILE" ] && LAST_SYNC_EPOCH=$(cat "$TRACK_FILE")

if [[ "$STATUS" == "idle" ]]; then
  echo "$NOW_EPOCH" > "$TRACK_FILE"
  notify "Syncthing: Sync complete." && log "Sync completed."
elif [[ "$STATUS" == "syncing" ]]; then
  notify "Syncthing: Sync started..." && log "Syncing..."
fi

# 5. Stale check
if [[ "$LAST_SYNC_EPOCH" -ne 0 ]]; then
  DIFF_MIN=$(( (NOW_EPOCH - LAST_SYNC_EPOCH) / 60 ))
  if (( DIFF_MIN >= STALE_LIMIT_MINUTES )); then
    notify "Sync hasn't completed in $DIFF_MIN minutes!"
    log "WARNING: Sync stale for $DIFF_MIN minutes."
  fi
fi

# 6. Icon logic
case "$STATUS" in
  "syncing") TOP_ICON="$ICON_SYNCING ($PROGRESS%)" ;;
  "idle") TOP_ICON="$ICON_IDLE" ;;
  *) TOP_ICON="$ICON_WARN" ;;
esac

# 7. Menu Bar Output
echo "Syncthing: $TOP_ICON"
echo "---"
echo "Status: $STATUS"
echo "Paused: $PAUSED"
echo "Progress: $PROGRESS% (${HUMAN_MB_LEFT}MB left)"
echo "Files Remaining: $NEED_FILES"
[[ "$STATUS" == "idle" ]] && echo "Last Sync: $DIFF_MIN minutes ago"
echo "---"

if [[ "$PAUSED" == "true" ]]; then
  echo "▶️ Resume Sync | bash='curl' param1='-X' param2='POST' param3=$ST_API/rest/folder/resume?folder=$FOLDER_ID param4='-H' param5='$AUTH_HEADER' terminal=false refresh=true"
else
  echo "⏸ Pause Sync | bash='curl' param1='-X' param2='POST' param3=$ST_API/rest/folder/pause?folder=$FOLDER_ID param4='-H' param5='$AUTH_HEADER' terminal=false refresh=true"
fi

echo "Open Web UI | href=$ST_API"
echo "Restart Syncthing | bash='brew' param1='services' param2='restart' param3='syncthing' terminal=false refresh=true"
echo "Quit SwiftBar | bash='killall' param1='SwiftBar' terminal=false"
