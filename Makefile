default: help

## help: prints this help message
help:
	@echo "Usage: \n"
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' |  sed -e 's/^/ /'

## bootstrap: install punch and setup everything (first-time setup)
bootstrap:
	./script/bootstrap

## setup: link and install dotfiles
setup:
	./script/setup

## setup-link: link dotfiles only (no installs)
setup-link:
	./script/setup --link-only

## backup-defaults: export curated macOS defaults
backup-defaults:
	@mkdir -p prefs/defaults
	@while IFS= read -r domain || [ -n "$$domain" ]; do \
		domain=$$(echo "$$domain" | sed 's/#.*//;s/^[[:space:]]*//;s/[[:space:]]*$$//'); \
		[ -z "$$domain" ] && continue; \
		echo "Exporting $$domain..."; \
		defaults export "$$domain" "prefs/defaults/$$domain.plist" 2>/dev/null || echo "  skipped (not found)"; \
	done < prefs/domains.txt
	@echo "Done. Review with: plutil -p prefs/defaults/<domain>.plist"

## backup-prefs: export curated defaults + mackup backup
backup-prefs: backup-defaults
	@command -v mackup >/dev/null && mackup backup --force || echo "mackup not installed"

## restore-prefs-dry: preview what restore would do
restore-prefs-dry:
	@echo "Would restore these plists:"
	@ls -1 prefs/defaults-safe/*.plist 2>/dev/null | xargs -n1 basename | sed 's/\.plist$$//'
	@echo "\nRun 'make restore-prefs' to apply."

## restore-prefs: restore tracked defaults + mackup (destructive)
restore-prefs:
	@for plist in prefs/defaults-safe/*.plist; do \
		domain=$$(basename "$$plist" .plist); \
		echo "Importing $$domain..."; \
		defaults import "$$domain" "$$plist"; \
	done
	@echo "Restarting affected services..."
	@killall Dock Finder SystemUIServer 2>/dev/null || true
	@command -v mackup >/dev/null && mackup restore --force || true

## promote-default: track a plist in version control (PLIST=domain REASON="why")
promote-default:
	@[ -n "$(PLIST)" ] || (echo "Usage: make promote-default PLIST=com.apple.dock REASON=\"...\"" && exit 1)
	@[ -n "$(REASON)" ] || (echo "Usage: make promote-default PLIST=com.apple.dock REASON=\"...\"" && exit 1)
	@[ -f "prefs/defaults/$(PLIST).plist" ] || (echo "Not found: prefs/defaults/$(PLIST).plist — run make backup-defaults first" && exit 1)
	cp "prefs/defaults/$(PLIST).plist" "prefs/defaults-safe/$(PLIST).plist"
	@DATE=$$(date +%Y-%m-%d); yq -i ".\"$(PLIST)\".promoted = \"$$DATE\" | .\"$(PLIST)\".reason = \"$(REASON)\"" prefs/defaults.lock.yaml
	@echo "Promoted $(PLIST) to defaults-safe/"

## validate-prefs: check defaults-safe matches lockfile
validate-prefs:
	@actual=$$(ls -1 prefs/defaults-safe/*.plist 2>/dev/null | xargs -n1 basename | sed 's/\.plist$$//' | sort); \
	locked=$$(yq -r 'keys | .[]' prefs/defaults.lock.yaml 2>/dev/null | sort); \
	if [ "$$actual" = "$$locked" ]; then echo "✓ defaults-safe matches lockfile"; \
	else echo "✗ mismatch:"; diff <(echo "$$actual") <(echo "$$locked"); exit 1; fi

## test-prefs: run bats tests for prefs tooling
test-prefs:
	bats prefs/test/
