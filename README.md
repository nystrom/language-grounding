# Programming language grounding

Coding agents blur language versions and toolchains. They suggest syntax that
does not exist yet in the target interpreter — or that was removed — misremember
which release added a feature, and pattern-match one language's semantics onto
another. The result is code that looks plausible but is wrong for the version in
front of them.

This repo contains programming-language-specific Claude Code skills that ground
agents in precise, version-aware language semantics: what a construct actually
does, in which versions it exists, and where the footguns are.

## Install

```bash
# Install all language skills
./install.sh

# Install a specific language
./install.sh python
```

Each `skills/<lang>/` directory installs as a single skill named
`<lang>-grounding` (e.g. `python-grounding`) under `~/.claude/skills/`, where
Claude Code picks it up automatically. A language skill is a small router
`SKILL.md` plus a `references/` directory of topic files the router points to, so
the agent pulls only the topic it needs.

## Skills

| Skill | Versions | Topics |
|-------|----------|--------|
| `python-grounding` | 3.9–3.13 | semantics, types, stdlib, toolchain, versions, errors, sharp-edges, packages |
| `julia-grounding` | 1.6–1.13 | semantics, types, stdlib, toolchain, versions, errors, sharp-edges, packages |
| `javascript-grounding` | — | semantics, sharp-edges |
| `typescript-grounding` | 5.x–7.0 | semantics, types, sharp-edges, versions, toolchain |

### `python-grounding` references (3.9–3.13)

| Reference | Description |
|-----------|-------------|
| `semantics` | Scoping (LEGB), closures, late binding, mutability, identity, generators, MRO, dunder protocol |
| `types` | Type hint syntax by version, TypeVar, ParamSpec, Protocol, TypedDict, overloads; `typing` vs `typing_extensions` |
| `stdlib` | Standard library API reference: correct function names, signatures, what does NOT exist |
| `toolchain` | ruff, black, mypy, pyright, pyrefly — config, diagnostics, common fixes |
| `versions` | What changed in 3.9, 3.10, 3.11, 3.12, 3.13; migration rules |
| `errors` | Error taxonomy: TypeError, AttributeError, ImportError, KeyError, async pitfalls, common misdiagnoses |
| `sharp-edges` | Footguns: mutable defaults, late binding, `is` vs `==`, class vs instance vars |
| `packages` | pip, uv, venv, pyproject.toml, requirements.txt, editable installs |

### `julia-grounding` references (1.6–1.13)

| Reference | Description |
|-----------|-------------|
| `semantics` | Multiple dispatch, method selection, scoping (hard vs soft), closures, macros, broadcasting, modules |
| `types` | Type hierarchy, parametric types, Union types, where clauses, type stability, constructors |
| `stdlib` | Base and stdlib API reference: correct names, mutation convention (`!`), what requires `using`, what is NOT in stdlib |
| `toolchain` | Pkg.jl, JuliaFormatter, JET.jl, Aqua.jl, Revise.jl, Cthulhu.jl, BenchmarkTools |
| `versions` | What changed in 1.6–1.13; package extensions, native code caching, ScopedValues, redefinable types, FieldError; compat bounds |
| `errors` | Error taxonomy: MethodError, BoundsError, UndefVarError, InexactError, OverflowError, common misdiagnoses |
| `sharp-edges` | Type instability from globals, soft scope, 1-based indexing, column-major arrays, integer overflow, broadcasting |
| `packages` | Pkg.jl programmatic API — never write UUIDs by hand; add/rm/update/develop, Project.toml compat, environments |

### `javascript-grounding` references

Narrower coverage than Python and Julia — two topics so far.

| Reference | Description |
|-----------|-------------|
| `semantics` | Declarations (`var`/`let`/`const`), scoping, hoisting, closures, `this` binding, prototypes, event loop, promises, async/await, ESM vs CommonJS, coercion |
| `sharp-edges` | `typeof null`, `NaN`, `-0`, `==` coercion, `parseInt` radix, `var` hoisting, `this` loss, sparse arrays, floating point, `switch` fall-through, UTF-16 strings |

### `typescript-grounding` references (5.x–7.0)

| Reference | Description |
|-----------|-------------|
| `semantics` | Structural typing, type-vs-value space, control-flow narrowing, assignability, declaration merging, `this`, type erasure |
| `types` | Generics, variance, conditional types and `infer`, mapped types, template literal types, `unknown`/`never`, utility types |
| `sharp-edges` | `any` vs `unknown`, `as`/`!` assertions, enum quirks, `{}` vs `object`, array covariance, method bivariance, shallow `readonly`, index access |
| `versions` | 5.x milestones, the 6.0 option removals, and the 7.0 Go-native port; migration |
| `toolchain` | `tsc`/`tsgo`, `tsconfig` strictness and module options, type-check vs transpile, `typescript-eslint` |

### Upgrading from an earlier layout

Earlier versions installed one skill per topic (`python-semantics`,
`python-types`, …). Those directories are now obsolete; remove the stale ones:

```bash
rm -rf ~/.claude/skills/{python,julia,javascript}-{semantics,types,toolchain,versions,sharp-edges,errors,stdlib,packages}
```

## Evals

249 regression test cases measure how accurately Claude answers
language-semantics questions, with and without the grounding skills.

### Results

Run on `claude-haiku-4-5-20251001` (2026-07-11). Both conditions hit a usage
cap in the tail of the serial run and returned empty output on the remaining
cases (82 of 249 without-skills, 27 with-skills). Empty responses are counted
as failures, so the raw pass rates (68.7% vs 43.4%) overstate the effect — the
without-skills run simply errored more. The honest comparison is restricted to
the **163 cases where both conditions produced a real answer**:

| Condition | Passed | Rate |
|-----------|-------:|-----:|
| With grounding skills | 116 / 163 | **71.2%** |
| Without skills (baseline) | 104 / 163 | 63.8% |

**+7.4 points**, net of 15 cases fixed and 3 regressed. The gain concentrates in
version- and semantics-boundary topics, where analogical guessing fails:

| Skill topic | Without | With | Δ | n |
|-------------|--------:|-----:|--:|--:|
| julia/versions | 55% | 70% | **+15** | 33 |
| python-sharp-edges | 79% | 93% | **+14** | 28 |
| julia/sharp-edges | 71% | 79% | +7 | 14 |
| python-semantics | 70% | 73% | +4 | 56 |
| python-versions | 9% | 9% | 0 | 11 |
| python-types | 25% | 25% | 0 | 4 |
| julia/semantics | 92% | 92% | 0 | 12 |

The three regressions are float int/float comparison (`py.float.int_float_mixed_exact_compare`)
and two Julia version boundaries (`jl.111.filter_named_tuple`, `jl.112.waitany_requires_112`)
where the skill nudged the model toward a wrong specific claim.

Caveats: the usage cap truncated the run before the `typescript`, `javascript`,
`errors`, `stdlib`, and `packages` cases got a fair baseline, so those skills are
absent from this comparison. Rerun with `--compare` (ideally on a higher rate
limit, or filtered per language) for complete coverage.

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
python3 evals/run.py --compare --filter js.

# Use a specific model
python3 evals/run.py --compare --model claude-sonnet-4-6
```

The runner injects every language skill's `SKILL.md` and `references/*.md` as the
grounding context. Results are saved as JSON in `evals/results/` (gitignored).

### Case locations

| Directory | Coverage |
|-----------|---------|
| `languages/python/evals/` | Python semantics, versions, sharp edges, abstention |
| `languages/julia/evals/` | Julia semantics, versions, sharp edges, abstention |
| `languages/javascript/evals/` | JavaScript semantics and sharp edges |
| `languages/typescript/evals/` | TypeScript semantics, types, sharp edges, versions |
| `evals/cases/` | New skills: errors, stdlib, packages (Python + Julia) |

### Adding cases

Add a YAML file to `evals/cases/` with this structure:

```yaml
cases:
  - id: py.myskill.my_case          # unique ID, dot-separated
    skill: python-semantics         # topic label (display only), e.g. python-<topic>
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

Each language skill is a router `SKILL.md` that points to topic references. Each
reference answers one or more agent questions:

- Can I parse this?
- What does this do?
- Is this edit safe?
- Why did this fail?
- What is the idiomatic way to express this?
- What changed in this version?

Every reference includes a **"What an agent may/must not infer"** section to
prevent analogical hallucination — the agent pattern-matching to a different
language's semantics or a different version's feature set.
