# AI Lawbook (English edition)

A Claude Code plugin that enforces role-specific quality standards on AI agents in the form of law.
It ships AI Laws for twelve roles (developer, designer, product manager, marketer, writer, translator,
data analyst, researcher, customer support, educator, HR, and sales), the Answer AI Law for the language,
structure, and sentences of every answer, and `ai-lawmaker`, a skill that enacts and amends laws for your
own team.

When the agent breaks a law, it writes a confession to the local file `~/.claude/ai-lawbook/confessions.md`.
A SessionStart hook injects that ledger and the laws listed in the enforcement roster
(`~/.claude/ai-lawbook/enabled-laws`) into every session, condensed when they exceed 9,000 characters (6,000 for a
subagent); a SubagentStart hook does the same for every subagent. A UserPromptSubmit hook repeats the top offense in one
line each turn, and a guard hook enforces the machine-rule lines in the ledger (block, Korean check, secret
masking) on Bash calls and final answers.

The hooks read only those two local files, the law files in `~/.claude/skills` and inside this plugin, and
the content Claude Code hands them for the call being checked. They make no network requests and send no
data anywhere.

Install (one line on Claude Code 2.1.275 or later):

```text
/plugin install ai-lawbook-en --marketplace PixelGrove/ai-lawbook
```

License: from 1.4.0, MIT with the Commons Clause (free to use, change, and share; not for sale). Details,
installation, usage, and privacy: https://github.com/PixelGrove/ai-lawbook
