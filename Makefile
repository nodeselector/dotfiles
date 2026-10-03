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

## check-gui: compile and smoke-test macOS GUI automation
check-gui:
	./script/check-gui

## reload-gui: check, install, and reload macOS GUI automation
reload-gui:
	./script/reload-gui
