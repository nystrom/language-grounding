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

Skills are copied from `skills/<lang>/<topic>/SKILL.md` to `~/.claude/skills/<lang>-<topic>/SKILL.md`.

## Structure

```
skills/
├── python/
│   ├── semantics/    # Scoping, closures, mutability, MRO, generators
│   ├── types/        # Type hints by version, TypeVar, Protocol
│   ├── toolchain/    # ruff, mypy, pyright, pyrefly
│   ├── versions/     # What changed in 3.9–3.13
│   └── sharp-edges/  # Footguns: mutable defaults, late binding, etc.
└── julia/
    ├── semantics/    # Multiple dispatch, scoping, macros, broadcasting
    ├── types/        # Parametric types, type stability, where clauses
    ├── toolchain/    # Pkg.jl, JET.jl, Revise.jl, BenchmarkTools
    ├── versions/     # What changed in 1.6–1.11
    └── sharp-edges/  # Type instability, soft scope, column-major arrays
languages/
├── python/           # Reference material for Python skill authoring
└── julia/            # Reference material for Julia skill authoring
```

## Adding a New Language

1. Create `skills/<lang>/` with subdirectories per topic
2. Each topic needs a `SKILL.md` — the install script picks up all `SKILL.md` files recursively
3. Add the language to `README.md` with a skill table
4. `./install.sh <lang>` to verify installation works

## Skill Design Principles

Each skill answers agent questions: Can I parse this? What does this do? Is this edit safe? Why did this fail? What is the idiomatic way?

Every skill must include a **"What an agent may/must not infer"** section to block analogical hallucination from other languages.
