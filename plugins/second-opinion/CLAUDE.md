# CLAUDE.md

## Project overview

`second-opinion` is a Claude Code plugin that sends the current conversation topic to Gemini and GPT for a second opinion, without leaving the Claude Code session.

## Structure

```
second-opinion/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest (name, version, author)
├── skills/
│   └── second-opinion/
│       └── SKILL.md             # Skill definition — invoked via /second-opinion
├── README.md
└── CLAUDE.md
```

## Key files

- **`skills/second-opinion/SKILL.md`** — defines the `/second-opinion` skill. Claude reads this when the skill is invoked and follows its instructions: builds a prompt from conversation context and runs `gemini` / `codex` CLI tools via stdin.

## How the skill works

The skill is a manually invoked [Claude Code skill](https://docs.anthropic.com/en/docs/claude-code/skills). It uses `allowed-tools: [Bash]` to run the external CLI tools.

Prompt assembly and context summarization is handled by Claude itself at runtime — no bash scripts needed.

## Adding support for a new model

1. Add a new `--modelname` flag to the SKILL.md instructions
2. Document the corresponding CLI command and stdin format
3. Update README.md with the new flag
