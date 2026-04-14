---
name: julia/types
description: Julia type system reference for coding agents. Covers the type hierarchy, abstract vs concrete types, parametric types, Union types, where clauses, type stability, method dispatch and specialization, and common type annotations. Use when writing type signatures, diagnosing type instability, or reasoning about dispatch.
origin: language-grounding
---

# Julia Type System Reference

Julia's type system is central to its performance model. Type instability — when the compiler cannot determine a concrete return type — is the primary cause of poor Julia performance.

---

## Type Hierarchy

Every type in Julia has exactly one supertype. The hierarchy is a tree rooted at `Any`.

```
Any
├── Number
│   ├── Real
│   │   ├── AbstractFloat
│   │   │   ├── Float16, Float32, Float64, BigFloat
│   │   ├── Integer
│   │   │   ├── Signed: Int8, Int16, Int32, Int64, Int128, BigInt
│   │   │   ├── Unsigned: UInt8, UInt16, UInt32, UInt64, UInt128
│   │   │   └── Bool
│   │   └── Rational, Irrational
│   └── Complex
├── AbstractString → String
├── AbstractChar → Char
├── AbstractArray{T,N}
├── Tuple
├── Nothing
├── Missing
└── ...
```

- **Abstract types** cannot be instantiated; they group concrete types.
- **Concrete types** can be instantiated; they cannot be subtyped.
- `Int` is an alias for the platform-native integer width (Int64 on 64-bit systems).

---

## Declaring Types

### Concrete Struct

```julia
struct Point
    x::Float64
    y::Float64
end

Point(1.0, 2.0)   # constructor; fields are immutable after construction
```

### Mutable Struct

```julia
mutable struct Counter
    count::Int
end

c = Counter(0)
c.count += 1   # legal
```

### Abstract Type

```julia
abstract type Shape end

struct Circle <: Shape
    radius::Float64
end

struct Rectangle <: Shape
    width::Float64
    height::Float64
end
```

`<:` means "is a subtype of". It is also used as a binary operator for subtype checks: `Int <: Number` is `true`.

### Primitive Type

```julia
primitive type MyBits 32 end   # 32-bit primitive type
```

Rarely needed outside of defining numeric types.

---

## Parametric Types

Types can be parameterized by other types (or values):

```julia
struct Pair{A, B}
    first::A
    second::B
end

p = Pair{Int, String}(1, "hello")
p = Pair(1, "hello")   # type parameters inferred from constructor arguments
```

### Parametric Abstract Types

```julia
abstract type AbstractStack{T} end

struct VectorStack{T} <: AbstractStack{T}
    data::Vector{T}
end
```

### Type Parameters Are Invariant

`Vector{Int}` is **not** a subtype of `Vector{Number}`, even though `Int <: Number`. This is invariance.

```julia
Vector{Int} <: Vector{Number}   # false
Vector{Int} <: Vector{<:Number} # true — covariant constraint
```

The `<:T` syntax in type context means "any subtype of T".

---

## `where` Clauses

Used in method signatures and type aliases to introduce type variables:

```julia
function sum_elements(v::Vector{T}) where T <: Number
    s = zero(T)
    for x in v
        s += x
    end
    return s
end
```

Multiple type variables:

```julia
function zip_apply(f::F, xs::Vector{T}, ys::Vector{S}) where {F, T, S}
    return [f(x, y) for (x, y) in zip(xs, ys)]
end
```

### Value Type Parameters

Types can be parameterized by values (integers are the common case):

```julia
struct StaticArray{T, N}
    data::NTuple{N, T}
end

StaticArray{Float64, 3}((1.0, 2.0, 3.0))
```

`NTuple{N, T}` is `Tuple{T, T, ..., T}` with N elements.

---

## Union Types

`Union{A, B}` is a type whose values may be of type `A` or `B`:

```julia
x::Union{Int, String} = 1
x = "hello"   # legal

# Common pattern: nullable
y::Union{Int, Nothing} = nothing
y = 42
```

**`Union{}`** (empty union) is the bottom type — no value has this type. It is the return type of functions that never return (e.g., `error`, `throw`).

### Small `Union` Optimization

Julia specially optimizes `Union{T, Nothing}` and `Union{T, Missing}` — they are represented without boxing when T is a bits type. This makes nullable integers efficient.

---

## Type Stability

A function is **type-stable** if the return type can be determined from the types of the arguments alone (not their values). Type instability forces dynamic dispatch and heap allocation.

```julia
# Type-unstable: return type depends on value of x, not just its type
function f(x::Int)
    if x > 0
        return x          # Int
    else
        return "negative"  # String
    end
end
# return type is Union{Int, String} — unstable

# Type-stable version
function f(x::Int)
    if x > 0
        return x
    else
        return -x
    end
end
# return type is always Int
```

### Diagnosing Type Instability

```julia
@code_warntype f(1)   # shows inferred types; red/yellow = unstable
```

Common causes:
- Returning different concrete types in different branches
- Accessing a global variable of non-const type
- Containers with element type `Any` (e.g., `Vector{Any}`)
- `getfield` on a struct with `Any`-typed fields

### Global Variable Instability

Non-`const` globals are always type-unstable because their type can change:

```julia
x = 1   # global; type could be anything

function uses_global()
    return x + 1   # type-unstable: x could be any type
end

const y = 1   # const: type is fixed at Int

function uses_const()
    return y + 1   # type-stable
end
```

**Fix:** declare globals `const`, or pass them as function arguments.

---

## Type Annotations in Functions

Type annotations constrain which methods apply:

```julia
function f(x::T, y::T) where T   # x and y must have the same type
    ...
end

function g(x::AbstractFloat)     # any float subtype
    ...
end

function h(x)                    # no constraint; dispatches on Any
    ...
end
```

**Annotations do not make code faster** unless they enable dispatch or allow the compiler to specialize. The compiler infers types regardless of annotations. Annotations only restrict which method is selected.

**Exception:** field type annotations in structs do improve performance because they fix the field's type:

```julia
struct Fast
    x::Float64   # always Float64; field access is fast
end

struct Slow
    x            # could be anything; field access requires dynamic lookup
end
```

---

## Type Introspection

```julia
typeof(x)          # concrete type of x
supertype(T)       # immediate supertype of T
subtypes(T)        # direct concrete subtypes of T (from loaded code)
T <: S             # true if T is a subtype of S
isa(x, T)          # true if x is an instance of T (x isa T also works)
fieldnames(T)      # names of fields in struct T
fieldtypes(T)      # types of fields in struct T
```

---

## Constructors

### Outer Constructors

Defined outside the struct; just regular methods of the type's name:

```julia
struct Point
    x::Float64
    y::Float64
end

Point(x::Int, y::Int) = Point(Float64(x), Float64(y))   # outer constructor
```

### Inner Constructors

Defined inside the struct; replace the default constructor:

```julia
struct PositiveInt
    value::Int

    function PositiveInt(v::Int)
        v > 0 || throw(ArgumentError("must be positive"))
        return new(v)   # new() is only available inside the struct definition
    end
end
```

`new(args...)` constructs the object without calling any constructor — only available inside `struct` bodies.

---

## Abstract Interface Pattern

Julia has no formal interface mechanism, but the standard pattern is:

```julia
abstract type AbstractAnimal end

# Document the required interface:
# - name(a::AbstractAnimal)::String
# - sound(a::AbstractAnimal)::String

struct Dog <: AbstractAnimal
    name::String
end

name(d::Dog) = d.name
sound(d::Dog) = "woof"

function describe(a::AbstractAnimal)
    println("$(name(a)) says $(sound(a))")
end
```

**Traits (Tim Holy trait trick):** for orthogonal capabilities not expressible through type hierarchy, use a trait type:

```julia
abstract type IterableTrait end
struct IsIterable <: IterableTrait end
struct NotIterable <: IterableTrait end

iterability(::Type) = NotIterable()
iterability(::Type{<:AbstractArray}) = IsIterable()

function process(x)
    return process(iterability(typeof(x)), x)
end
process(::IsIterable, x) = [item for item in x]
process(::NotIterable, x) = [x]
```

---

## `isbits` and `isimmutable`

```julia
isbitstype(T)    # true if T is an immutable concrete type with no references
isbits(x)        # isbitstype(typeof(x))
isimmutable(x)   # true if x is not a mutable struct
```

`isbitstype` types (e.g., `Int`, `Float64`, `Point`) are stack-allocated or unboxed in arrays — no heap allocation.

---

## What an Agent May Safely Infer

- `Int <: Number` is true; `Vector{Int} <: Vector{Number}` is false (invariance).
- Non-`const` global variables cause type instability in functions that reference them.
- A `struct` (without `mutable`) has immutable fields after construction.
- `Union{T, Nothing}` is the standard nullable type; it is efficiently represented.

## What an Agent Must Not Infer Without Evidence

- That type annotations on function arguments speed up code — they only constrain dispatch.
- That `subtypes(T)` returns all subtypes — only those from currently loaded modules.
- That a function is type-stable without running `@code_warntype`.
- That a struct can be subtyped — concrete structs cannot; only abstract types can be subtyped.

## What Requires Whole-Program Analysis

- Whether all call sites pass compatible types to a parametric function.
- Whether a Union type in a return position causes downstream type instability.
- Whether two method definitions are ambiguous (requires seeing all loaded methods).
