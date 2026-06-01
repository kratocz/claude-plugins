# mikrotik-audit

A Claude Code plugin for **read-only security audits of Mikrotik RouterOS devices** via SSH. Detects signs of compromise: VPNFilter IoCs, CVE-2018-14847 (Winbox RCE), Meris, scheduler/script persistence, DNS hijacking, rogue users, exfiltration tunnels, exposed management services.

## Install

```
/plugin install mikrotik-audit@kratocz
```

If you haven't added the marketplace yet:

```
/plugin marketplace add kratocz/claude-plugins
```

## Requirements

- SSH access to your Mikrotik router(s) with **key authentication** (no password prompts).
- Ideally a dedicated read-only user on the router (group `read`) with your public key installed via `/user ssh-keys import`.

## Usage

Ask Claude Code in natural language:

> Check my Mikrotik routers for signs of compromise.

Claude will ask for SSH targets (or read them from project docs like `infrastructure/mikrotik-routers.md`), run the audit collector, and produce a structured report with 🚨 **CRITICAL** / ⚠️ **WARN** / ℹ️ **INFO** / ✅ **OK** findings.

You can also invoke the collector directly:

```
mikrotik-audit router1 router2
mikrotik-audit --out /tmp/audit admin@192.168.0.1
mikrotik-audit admin@192.168.0.1:2222
```

Output lands in `./audit-results/<timestamp>/` with per-target dumps and a heuristic `summary.md`.

## What it checks

| Section | Covers |
|---|---|
| `system` | RouterOS version (CVE-2018-14847), identity, license, uptime |
| `users` | Accounts, SSH keys, groups, active sessions |
| `scripts` | ⚠️ Scheduler and scripts — most common persistence vector |
| `services` | SOCKS (VPNFilter IoC), UPnP, Telnet, FTP, Winbox, Cloud |
| `firewall` | Filter, NAT, mangle, raw, address lists |
| `network` | Interfaces, DNS (hijacking), routes, DHCP |
| `tunnels` | L2TP, PPTP, OpenVPN, SSTP, Wireguard, GRE, EoIP, IPIP |
| `wifi` | SSIDs, security profiles |
| `files` | Suspicious `.rsc` / `autorun` files |
| `logs` | Failed logins, critical/error events |
| `snmp` | Default communities |
| `tool` | bandwidth-server, RoMON, mac-server |
| `certs` | Root CAs, management certs |

## Security

- **Read-only.** The script and skill do not modify any router configuration. All commands are `print`-only RouterOS queries. Recommended fixes are reported, never executed.
- **No password prompts.** SSH runs with `BatchMode=yes`; authentication is strictly key-based.
- **No exfiltration.** Raw dumps contain sensitive network information and stay on your local machine. The skill never uploads them to third-party services.

## Author

Petr Kratochvíl · [krato.cz](https://krato.cz/)

## License

MIT
