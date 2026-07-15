# Language Grounding

A collection of Claude Code skills that ground agents in language semantics, preventing analogical hallucination and version confusion.

## Installation

Claude Code automatically discovers and loads these skills when running inside this repository.

To install them globally for all projects:
```bash
# Copy all skills to your global Claude skills directory
cp -r .claude/skills/* ~/.claude/skills/

# Or symlink them:
ln -s "$(pwd)/.claude/skills/"* ~/.claude/skills/
```

## Structure

Each language is a single skill: a router `SKILL.md` that points to per-topic
files under `references/`.

```
.claude/skills/
├── python-grounding/
│   ├── SKILL.md          # router: name python-grounding, indexes references
│   └── references/       # semantics, types, stdlib, toolchain,
│                         #   versions, errors, sharp-edges, packages
├── julia-grounding/
│   ├── SKILL.md          # router: name julia-grounding
│   └── references/       # same 8 topics as Python
├── javascript-grounding/
│   ├── SKILL.md          # router: name javascript-grounding
│   └── references/       # semantics, sharp-edges (narrower coverage)
└── typescript-grounding/
    ├── SKILL.md          # router: name typescript-grounding
    └── references/       # semantics, types, sharp-edges, versions, toolchain
languages/
├── python/evals/         # Eval cases for the Python skill
├── julia/evals/          # Eval cases for the Julia skill
├── javascript/evals/     # Eval cases for the JavaScript skill
└── typescript/evals/     # Eval cases for the TypeScript skill
```

## Adding a New Language

1. Create a new directory `.claude/skills/<lang>-grounding/`
2. Create references under `.claude/skills/<lang>-grounding/references/<topic>.md` files for each topic
3. Create `.claude/skills/<lang>-grounding/SKILL.md` — a router with `name: <lang>-grounding`
   frontmatter and a table pointing to each `references/<topic>.md`
4. Add the language to `README.md` under Skills

## Skill Design Principles

Each reference answers agent questions: Can I parse this? What does this do? Is
this edit safe? Why did this fail? What is the idiomatic way?

Every reference must include a **"What an agent may/must not infer"** section to
block analogical hallucination from other languages and version confusion.
