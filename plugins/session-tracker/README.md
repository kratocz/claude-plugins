# session-tracker

A Claude Code plugin for starting and stopping time tracking sessions in **Toggl Track** or **Clockify**.

## Install

```
/plugin install session-tracker@kratocz
```

## Setup

Run once to configure your time tracking backend:

```
/setup-tracker
```

## Usage

```
/start Refactoring auth module
/stop
```

## Supported backends

- [Toggl Track](https://toggl.com/track/)
- [Clockify](https://clockify.me/)

## Config

Stored at `~/.claude/plugins/session-tracker/config.json`. Re-run `/setup-tracker` to change settings.
