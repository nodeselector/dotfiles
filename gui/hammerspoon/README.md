# Hammerspoon automation

## KVM-aware workspace 10

The personal Mac and work laptop share a Samsung Odyssey display and a ZSA
Moonlander through a TESmart KVM. The KVM emulates EDID and USB devices on its
inactive input, so macOS continues to report both the display and keyboard as
connected after switching to the other computer.

`moonlander-active.swift` distinguishes a real connection from the emulated
one. It sends the Moonlander's read-only Oryx `GET_PROTOCOL_VERSION` Raw HID
command (`0xfe`):

| Exit | Meaning |
|------|---------|
| `0` | The physical Moonlander responded; the personal Mac is selected |
| `1` | No response or no keyboard; the KVM is elsewhere or disconnected |
| `2` | The HID interface could not be opened or queried |

`kvm-workspace.lua` polls the helper and:

- places AeroSpace workspace 10 on the Odyssey when the personal input is active;
- places it on the built-in display after two inactive responses;
- keeps the cursor out of the logically connected Odyssey while it is inactive;
- safely treats a physically disconnected KVM as inactive.

The helper is compiled to `~/.local/bin/moonlander-active` by the Hammerspoon
`dot.yaml` install step.

## Development workflow

Run the macOS GUI smoke checks:

```sh
make check-gui
```

Compile the detector, copy changed dotfiles, and reload AeroSpace and
Hammerspoon:

```sh
make reload-gui
```

A normal `make setup` also installs the helper, but reloads are intentionally a
separate operation.

## Manual diagnostics

```sh
~/.local/bin/moonlander-active
echo $?

aerospace list-monitors --format '%{monitor-id}\t%{monitor-name}'
aerospace list-workspaces --all --format '%{workspace}\t%{monitor-name}'

/Applications/Hammerspoon.app/Contents/Frameworks/hs/hs -c \
  'return tostring(require("kvm-workspace").isPersonalInputActive())'
```

If Hammerspoon reports `nil`, it has not completed enough polls to establish a
state. Inactive detection normally takes about four seconds because failures
are deliberately confirmed twice.
