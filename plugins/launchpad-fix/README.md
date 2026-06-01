# launchpad-fix — Claude Code plugin

Find apps that exist in `/Applications` but don't appear in macOS Launchpad, re-register them with Launch Services, then reset the Dock.

## What it does

The skill `/launchpad-fix` walks through:

1. **Verifies macOS.** Refuses to run on Linux/Windows.
2. **Finds missing apps** — compares the `.app` bundles in `/Applications` against what Spotlight (`mdfind`) reports as registered Applications. The diff is the list of apps Launchpad doesn't know about. Handles both English (`kMDItemKind == 'Application'`) and Czech (`kMDItemKind == 'Aplikace'`) localization.
3. **Asks the user** which apps to re-register (default: all).
4. **Re-registers** each selected app via `lsregister -f "/Applications/<name>.app"`.
5. **Asks before resetting the Dock** (the reset closes and reopens Dock briefly, no data loss).
6. **Resets Launchpad** — `defaults write com.apple.dock ResetLaunchPad -bool true && killall Dock`.

## Install

Via the [kratocz marketplace](https://github.com/kratocz/claude-plugins):

```
/plugin marketplace add kratocz/claude-plugins
/plugin install launchpad-fix@kratocz
```

## Requirements

- macOS (tested on Sequoia/Tahoe — uses Launch Services tooling that has been stable for years)
- No `sudo` needed for `/Applications/*.app` registered by the user

## Usage

```
/launchpad-fix
```

…or just say: "některé aplikace mi chybí v Launchpadu", "fix my Launchpad", "Launchpad mi nezobrazuje X".
