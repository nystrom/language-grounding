# Programming language grounding

Coding agents often have trouble using obscure languages and libraries on which they
were not trained. They also have confusion with different language versions, different
toolchains.

This repo contains programming-language-specific Claude Code skills to ground agents
in language semantics.

## Install

```bash
# Install all skills
./install.sh

# Install a specific language
./install.sh python
```

Skills are stored hierarchically in `skills/` (e.g., `skills/python/semantics/SKILL.md`) and installed to `~/.claude/skills/` where Claude Code picks them up automatically.

## Python skills (3.9–3.13)

| Skill | Description |
|-------|-------------|
| `python/semantics` | Scoping (LEGB), closures, mutability, generators, MRO, dunder protocol |
| `python/types` | Type hint syntax by version, TypeVar, ParamSpec, Protocol, TypedDict, overloads; what to import from `typing` vs `typing_extensions` |
| `python/toolchain` | ruff, black, mypy, pyright, pyrefly — config, diagnostics, common fixes |
| `python/versions` | What changed in 3.9, 3.10, 3.11, 3.12, 3.13; migration rules |
| `python/sharp-edges` | Footguns: mutable defaults, late binding, `is` vs `==`, class vs instance vars |
| `python/errors` | Error taxonomy: TypeError, AttributeError, ImportError, KeyError, async pitfalls, and common misdiagnoses |
| `python/stdlib` | Standard library API reference: correct function names, signatures, what does NOT exist |
| `python/packages` | pip, uv, venv, pyproject.toml, requirements.txt, editable installs |

## Julia skills (1.6–1.11)

| Skill | Description |
|-------|-------------|
| `julia/semantics` | Multiple dispatch, method selection, scoping (hard vs soft), closures, macros, broadcasting, modules |
| `julia/types` | Type hierarchy, parametric types, Union types, where clauses, type stability, constructors |
| `julia/toolchain` | Pkg.jl, JuliaFormatter, JET.jl, Aqua.jl, Revise.jl, Cthulhu.jl, BenchmarkTools |
| `julia/versions` | What changed in 1.6–1.11; package extensions, native code caching, ScopedValues; compat bounds guide |
| `julia/sharp-edges` | Type instability from globals, soft scope, 1-based indexing, column-major arrays, integer overflow, broadcasting |
| `julia/errors` | Error taxonomy: MethodError, BoundsError, UndefVarError, InexactError, OverflowError, and common misdiagnoses |
| `julia/stdlib` | Base and standard library API reference: correct function names, mutation convention (!), what requires `using`, what is NOT in stdlib |
| `julia/packages` | Pkg.jl programmatic API — NEVER write UUIDs manually; add/rm/update/develop, Project.toml compat, environments |

## Evals

210 regression test cases measure how accurately Claude answers language-semantics questions, with and without the grounding skills.

### Setup

```bash
pip install anthropic pyyaml   # or: pip install -r evals/requirements.txt
export ANTHROPIC_API_KEY=sk-ant-...
```

### Run

```bash
# Compare with-skills vs without-skills (the main regression test)
python3 evals/run.py --compare

# Baseline only (no skills)
python3 evals/run.py --no-skills

# With skills only (default)
python3 evals/run.py

# Filter to a subset
python3 evals/run.py --compare --filter py.errors
python3 evals/run.py --compare --filter jl.pkg
python3 evals/run.py --compare --filter jl.

# Use a specific model
python3 evals/run.py --compare --model claude-sonnet-4-6
```

Results are saved as JSON in `evals/results/` (gitignored).

### Case locations

| Directory | Coverage |
|-----------|---------|
| `languages/python/evals/` | Python semantics, versions, sharp edges, abstention |
| `languages/julia/evals/` | Julia semantics, versions, sharp edges, abstention |
| `evals/cases/` | New skills: errors, stdlib, packages (Python + Julia) |

### Adding cases

Add a YAML file to `evals/cases/` with this structure:

```yaml
cases:
  - id: py.myskill.my_case          # unique ID, dot-separated
    skill: python/myskill
    topic: relevant_topic
    prompt: >
      Question text here.
    code: |
      # optional code block shown to the model
    # For output-prediction cases:
    choices:
      - "Option A"
      - "Option B"
    expected_output: "Option A"
    wrong_output_reason: >
      Why an agent without grounding picks the wrong answer.
    # OR for behavior-assertion cases:
    expected_behavior:
      must_not_say:
        - "forbidden phrase"
      must_say_one_of:
        - "required phrase"
```

## Design

Each skill answers one or more of these agent questions:
- Can I parse this?
- What does this do?
- Is this edit safe?
- Why did this fail?
- What is the idiomatic way to express this?
- What changed in this version?

Every skill includes a **"What an agent may/must not infer"** section to prevent
analogical hallucination — the agent pattern-matching to a different language's semantics.
