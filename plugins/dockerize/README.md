# dockerize — Claude Code plugin

Add Docker to an existing project: a multi-stage production-ready `Dockerfile`, a `.dockerignore`, and an optional `docker-compose.yml` with the services the project likely needs (Postgres, Redis, …).

## What it does

The skill `/dockerize` walks through:

1. **Detects the project type** (Node, Python, Go, Rust, JVM/Maven/Gradle, PHP, Ruby, Elixir, Dart/Flutter, .NET) by looking for marker files in the root.
2. **Generates a multi-stage Dockerfile** — a `builder` stage that compiles/installs deps, a slim `runtime` stage that copies only the build output. Uses a slim/alpine base image and runs the app as a non-root user.
3. **Generates `.dockerignore`** — same baseline approach as the `project-init` plugin: `.git`, `.DS_Store`, IDE folders, plus type-specific patterns (`node_modules/`, `__pycache__/`, `target/`, …) so the build context stays tiny.
4. **Asks whether to generate `docker-compose.yml`**, with a list of services it can pre-wire based on framework detection (Django/Rails → Postgres, Express/Next → Redis if cache code is detected, Spring Boot → Postgres, etc.). User picks which services to include.
5. **Detects ports** the app listens on (from `package.json`, `manage.py`, framework conventions, `EXPOSE` lines if any) and wires them in.
6. **Skips existing files** — never overwrites; if `Dockerfile`/`docker-compose.yml`/`.dockerignore` already exists, asks what to do.

## Install

Via the [kratocz marketplace](https://github.com/kratocz/claude-plugins):

```
/plugin marketplace add kratocz/claude-plugins
/plugin install dockerize@kratocz
```

## Requirements

- A project with a recognizable marker file (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, …)
- Docker installed locally if you want to verify the build (the skill doesn't run `docker build` itself)

## Usage

In your project root:

```
/dockerize
```

…or just say: "přidej Docker tomuhle projektu", "udělej mi Dockerfile + compose", "dockerize this".

## Related plugins

- [`project-init`](https://github.com/kratocz/project-init) — bootstrap a new project (`.gitignore`, `AGENTS.md`, `CLAUDE.md`, `README.md`, git init, GitHub remote). Shares the project-type detection patterns with this plugin.
