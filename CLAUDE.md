# Language Grounding

A collection of Claude Code skills that ground agents in language semantics, preventing analogical hallucination and version confusion.

## Commands

```bash
# Install all skills
./install.sh

# Install a specific language
./install.sh python
./install.sh julia

# Install multiple languages
./install.sh python julia
```

Each `skills/<lang>/` installs as one skill named `<lang>-grounding` at
`~/.claude/skills/<lang>-grounding/` — the whole directory (router `SKILL.md`
plus `references/`) is copied.

## Structure

Each language is a single skill: a router `SKILL.md` that points to per-topic
files under `references/`.

```
skills/
├── python/
│   ├── SKILL.md          # router: name python-grounding, indexes references
│   └── references/       # semantics, types, stdlib, toolchain,
│                         #   versions, errors, sharp-edges, packages
├── julia/
│   ├── SKILL.md          # router: name julia-grounding
│   └── references/       # same 8 topics as Python
└── javascript/
    ├── SKILL.md          # router: name javascript-grounding
    └── references/       # semantics, sharp-edges (narrower coverage)
languages/
├── python/evals/         # Eval cases for the Python skill
├── julia/evals/          # Eval cases for the Julia skill
└── javascript/evals/     # Eval cases for the JavaScript skill
```

## Adding a New Language

1. Create `skills/<lang>/references/<topic>.md` files for each topic
2. Create `skills/<lang>/SKILL.md` — a router with `name: <lang>-grounding`
   frontmatter and a table pointing to each `references/<topic>.md`
3. Add the language to `README.md` under Skills
4. `./install.sh <lang>` to verify installation works (auto-discovered — no
   change to `install.sh` needed)

## Skill Design Principles

Each reference answers agent questions: Can I parse this? What does this do? Is
this edit safe? Why did this fail? What is the idiomatic way?

Every reference must include a **"What an agent may/must not infer"** section to
block analogical hallucination from other languages and version confusion.
