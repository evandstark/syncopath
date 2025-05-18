PLUGIN_DIR ?= $(HOME)/.swiftbar
PLUGIN_SCRIPT := SyncthingDev.10s.sh
PLIST_SRC := launchd/local.syncthing.watch.plist
PLIST_DEST := $(HOME)/Library/LaunchAgents/local.syncthing.watch.plist

.PHONY: all install swiftbar plugin plist clean logs

all: install

# Default Syncthing URL (can be overridden via `make SYNCTHING_URL=https://custom:port install`)
SYNCTHING_URL ?= https://127.0.0.1:8384

syncthing:
	@echo "→ Checking for Syncthing..."
	@if ! command -v syncthing >/dev/null 2>&1; then \
		echo "Installing Syncthing..."; \
		arch -arm64 brew install syncthing; \
	else \
		echo "Syncthing already installed."; \
	fi

	@brew services start syncthing

	@echo "→ Waiting for Syncthing to respond at $(SYNCTHING_URL)..."
	@TRIES=0; \
	while ! curl -sk --max-time 2 -o /dev/null -w "%{http_code}" $(SYNCTHING_URL) | grep -q "200"; do \
		sleep 1; TRIES=$$((TRIES+1)); \
		if [ $$TRIES -ge 15 ]; then \
			echo "❌ Syncthing failed to start or respond at $(SYNCTHING_URL)"; \
			echo "💡 Make sure the GUI is enabled and reachable with HTTPS."; \
			exit 1; \
		fi; \
	done

	@echo "✅ Syncthing is up and responding at $(SYNCTHING_URL)."


install: syncthing swiftbar plugin plist
	@echo "✅ All done. Open SwiftBar and point it to $(PLUGIN_DIR)"
	@echo "🚀 Syncopath is now live in your menu bar and your logs are being watched like a hawk."


swiftbar:
	@echo "→ Checking for SwiftBar..."
	@if ! command -v swiftbar >/dev/null 2>&1; then \
		echo "Installing SwiftBar..."; \
		brew install --cask swiftbar; \
	else \
		echo "SwiftBar already installed."; \
	fi

plugin:
	@echo "→ Setting up SwiftBar plugin..."
	@mkdir -p $(PLUGIN_DIR)
	@cp $(PLUGIN_SCRIPT) $(PLUGIN_DIR)/
	@chmod +x $(PLUGIN_DIR)/$(PLUGIN_SCRIPT)

plist:
	@echo "→ Installing LaunchAgent for background health checks..."
	@sed "s|/Users/YOUR_USERNAME|$(HOME)|g" $(PLIST_SRC) > $(PLIST_DEST)
	@launchctl unload -wF $(PLIST_DEST) >/dev/null 2>&1 || true
	@launchctl load -wF $(PLIST_DEST)
	@echo "LaunchAgent loaded. Logs at /tmp/syncthing-health.log"

logs:
	@echo "→ Tailing logs (Ctrl+C to stop)..."
	@tail -f /tmp/syncthing-health.log

clean:
	@echo "→ Uninstalling everything..."
	@launchctl unload -wF $(PLIST_DEST)
	@rm -f $(PLIST_DEST)
	@rm -f $(PLUGIN_DIR)/$(PLUGIN_SCRIPT)

install: swiftbar plugin plist
	@echo "✅ All done. Open SwiftBar and point it to $(PLUGIN_DIR)"
	@echo "🚀 Syncopath is now live in your menu bar and your logs are being watched like a hawk."

