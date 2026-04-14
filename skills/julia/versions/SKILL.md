---
name: julia/versions
description: Julia version differences reference for coding agents. Covers what changed in Julia 1.6 through 1.11 — new syntax, semantic changes, standard library additions, deprecations, and performance improvements. Use when code targets a specific Julia version, or when upgrading a package's compat bounds.
origin: language-grounding
---

# Julia Version Differences: 1.6–1.11

Julia's LTS (Long Term Support) line is **1.10** as of 2024. New packages should target `julia = "1.9"` or `"1.10"` for good package extension support; targeting `"1.6"` sacrifices access to many improvements.

---

## Julia 1.6 (LTS until 2024)

Released March 2021. Long-term support release; many packages use it as their minimum.

### Key Changes

**Precompilation improvements:** precompile statements dramatically reduce load times. Packages can declare `precompile(f, (ArgTypes...))` to force compilation at package load.

**`Pkg` workspace improvements:** better handling of `develop`ed packages and local path dependencies.

**`Base.Threads.@spawn` stabilized:** creates a `Task` that runs on any available thread. Before 1.6, threading support was experimental.

```julia
t = Threads.@spawn begin
    compute_something()
end
result = fetch(t)
```

**String interpolation in regex:** `Regex("prefix_$(name)_suffix")` works correctly.

**`isless` for `nothing`:** `nothing` is now `isless` than any non-`nothing` value, enabling `sort` on `Union{T, Nothing}` arrays.

### What 1.6 Lacks

- Package extensions (added in 1.9)
- `@lock` macro (added in 1.7)
- Heap-allocated closures optimization (improved in 1.8)
- Native code caching (added in 1.9)

---

## Julia 1.7

Released November 2021.

### Key Changes

**`@lock` macro:**
```julia
lk = ReentrantLock()
@lock lk begin
    # critical section
end
# equivalent to: lock(lk); try ... finally unlock(lk) end
```

**`Base.@kwdef` (stabilized):** generates a keyword-argument constructor for structs:
```julia
Base.@kwdef struct Options
    verbose::Bool = false
    timeout::Int = 30
    name::String = "default"
end

Options()                          # all defaults
Options(verbose=true, timeout=60)  # keyword args
```

**Threaded garbage collection improvements:** reduced GC pause times in multi-threaded programs.

**`Iterators.flatmap`:**
```julia
Iterators.flatmap(x -> [x, x^2], [1, 2, 3])
# [1, 1, 2, 4, 3, 9]
```

**New random number generators:** `Xoshiro` replaces `MersenneTwister` as the default. Xoshiro is faster and has better statistical properties.

---

## Julia 1.8

Released August 2022.

### Key Changes

**`const` fields in mutable structs:**
```julia
mutable struct Config
    const name::String   # cannot be reassigned after construction
    value::Int           # can be reassigned
end
```

**`@inline` and `@noinline` in more positions:** can now annotate calls, not just definitions:
```julia
result = @inline f(x)    # hint to inline this specific call
```

**`ScopedValues` precursor:** groundwork for dynamic scoping features that arrived in 1.11.

**`StyledStrings` (experimental):** annotated strings with styling metadata.

**Better error messages:** more context for `MethodError`, improved display of type signatures.

**`Tuple` allocation improvements:** small tuples avoid heap allocation more reliably.

---

## Julia 1.9

Released May 2023. Major release for package load times.

### Key Changes

**Package image caching (native code):** compiled native code is cached between sessions. Package load times reduced by 10–100× for packages with significant compilation. This is the single biggest quality-of-life improvement in recent Julia history.

**Package extensions (`weakdeps` / `extdeps`):** optional code activated when specific packages are available:
```toml
# Project.toml
[weakdeps]
DataFrames = "a93c6f00-e57d-5684-b466-afe8fa294f37"

[extensions]
MyPkgDataFramesExt = "DataFrames"
```
Replaces `Requires.jl`. Extension modules live in `ext/`.

**`Codeunits` access:** `codeunits(s)` returns a vector-like view of string bytes without copying.

**`@assume_effects`:** allows annotating functions with semantic assumptions for compiler optimization:
```julia
Base.@assume_effects :pure function f(x::Int)
    x * 2   # compiler can constant-fold calls with literal arguments
end
```

Effects: `:pure`, `:foldable`, `:nothrow`, `:terminates_globally`, `:notaskstate`, `:inaccessiblememonly`, `:consistent`, `:effect_free`.

**`Iterators.cycle` with a count:**
```julia
Iterators.cycle([1, 2, 3], 2)   # [1, 2, 3, 1, 2, 3]
```

---

## Julia 1.10 (Current LTS)

Released December 2023. Current long-term support release.

### Key Changes

**Parallel precompilation:** multiple packages precompile in parallel during `Pkg.instantiate()`. Dramatically reduces first-install time.

**`--project=@.` default behavior stabilized:** running `julia --project=@.` uses the closest `Project.toml` found in the current directory or any parent.

**`Base.Threads.@threads :static` and `:dynamic`:**
```julia
@threads :static for i in 1:n   # static: fixed assignment of iterations to threads
    ...
end

@threads :dynamic for i in 1:n  # dynamic: work-stealing scheduler
    ...
end
```
`:dynamic` is generally better for uneven workloads.

**`LazyString`:**
```julia
@warn lazy"Value is $x"   # string is only constructed if the warning is shown
```
Avoids allocating log message strings when the log level is suppressed.

**`pkgversion(M)`:** returns the version of a module's package:
```julia
pkgversion(MyPackage)   # returns VersionNumber
```

**`eachrsplit`:**
```julia
eachrsplit("a.b.c", "."; limit=2)   # ["a.b", "c"] — split from the right
```

### What 1.10 Lacks

- `ScopedValues` (added in 1.11)
- Memory layout improvements for arrays (added in 1.11)

---

## Julia 1.11

Released October 2024.

### Key Changes

**`ScopedValues.jl` (stdlib):** dynamic scoping via a task-local context. Values propagate into spawned tasks.

```julia
using Base.ScopedValues

const REQUEST_ID = ScopedValue{String}()

with(REQUEST_ID => "req-123") do
    # REQUEST_ID[] is "req-123" here and in any tasks spawned inside
    process_request()
end
# REQUEST_ID[] is not set here
```

**New array memory layout:** more efficient internal representation for arrays, especially for small arrays. Programs allocating many small arrays benefit automatically.

**`public` keyword:** marks names as part of a package's public API without exporting them. `using` does not bring them into scope, but they are not considered internal:
```julia
module MyPkg

export foo          # brought into scope by `using MyPkg`
public bar          # public but not auto-imported; access as MyPkg.bar

function foo() ... end
function bar() ... end
function _internal() ... end

end
```

**`Base.Cartesian.@nif`** and related macro improvements for generated code.

**Improved `show` for types:** type display is more compact and consistent.

---

## Version Compatibility Matrix

| Feature | 1.6 | 1.7 | 1.8 | 1.9 | 1.10 | 1.11 |
|---------|-----|-----|-----|-----|------|------|
| `@spawn` (stable) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `@lock` | — | ✓ | ✓ | ✓ | ✓ | ✓ |
| `@kwdef` (stable) | — | ✓ | ✓ | ✓ | ✓ | ✓ |
| `const` struct fields | — | — | ✓ | ✓ | ✓ | ✓ |
| Package extensions | — | — | — | ✓ | ✓ | ✓ |
| Native code caching | — | — | — | ✓ | ✓ | ✓ |
| Parallel precompilation | — | — | — | — | ✓ | ✓ |
| `@threads :dynamic` | — | — | — | — | ✓ | ✓ |
| `ScopedValues` | — | — | — | — | — | ✓ |
| `public` keyword | — | — | — | — | — | ✓ |

---

## `[compat]` Bounds Guide

The `[compat]` entry in `Project.toml` uses Julia's semver-like bounds. A single version number means "compatible with this minor series":

| Entry | Meaning |
|-------|---------|
| `julia = "1.6"` | `>= 1.6, < 2` |
| `julia = "1.9"` | `>= 1.9, < 2` (enables package extensions) |
| `julia = "1.10"` | `>= 1.10, < 2` (current LTS) |
| `julia = "1.6, 1.7"` | `>= 1.6, < 1.7` OR `>= 1.7, < 2` (unusual) |

For packages:
| Entry | Meaning |
|-------|---------|
| `DataFrames = "1"` | `>= 1.0, < 2` |
| `DataFrames = "0.21"` | `>= 0.21, < 0.22` |
| `DataFrames = "0.21, 1"` | `>= 0.21, < 0.22` OR `>= 1, < 2` |

**0.x packages:** each minor version is a separate compatibility series. `"0.21"` does not include `0.22`.

---

## Migration Notes

### 1.6 → 1.9

- Replace `Requires.jl` conditional loading with package extensions.
- Add `precompile` workload (`PrecompileTools.jl`) to improve load times further.

### 1.9 → 1.10

- Replace bare `@threads for` with `@threads :dynamic for` for uneven workloads.
- Bump `[compat]` to `"1.10"` to use parallel precompilation.

### 1.10 → 1.11

- Consider `ScopedValues` for request-scoped or task-scoped context (replaces thread-local patterns).
- Add `public` annotations for names that are part of the API but should not be auto-imported.

---

## What an Agent May Safely Infer

- Package extensions require Julia 1.9+; code using `weakdeps` will not load on 1.8 or earlier.
- `const` fields in `mutable struct` require Julia 1.8+.
- Native code caching (fast second load) is a 1.9+ feature.
- `@kwdef` is public API from Julia 1.7+.

## What an Agent Must Not Infer Without Evidence

- That a package's `[compat]` bound reflects the minimum actually required — it may be set conservatively.
- That `Requires.jl` is still the right approach — check Julia version before recommending it.
- That `Base.@kwdef` is available on 1.6 — it exists but was `Base.@kwdef` (not re-exported) and is considered internal before 1.7.

## What Requires Whole-Program Analysis

- Whether raising a package's minimum Julia version breaks downstream dependents.
- Whether a package extension would resolve a load-time dependency conflict.
