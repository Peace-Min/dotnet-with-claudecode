# Writing C# 7.3 for net472/net48

> Which C# language features are safe by default on .NET Framework 4.7.2-4.8 (C# 7.3) and which are not, plus how to verify BCL/NuGet API availability for net472 with HandMirrorMcp. Use when generating or editing code for an existing net472/net48 project to avoid emitting syntax or APIs the project cannot compile or run.

A net472/net48 project defaults to **C# 7.3** unless its csproj sets a higher
`<LangVersion>`. Detect the effective `LangVersion`; when unknown, target C# 7.3.
A newer Roslyn (VS 2019/2022) CAN compile a higher LangVersion against net472, but
never EMIT syntax the project does not allow.

## Safe on net472 + C# 7.3

- tuples and tuple deconstruction, `out var`
- pattern matching: `is Type x`, `switch` with `case Type x when ...`, `case null`
- local functions, expression-bodied members, `throw` expressions
- `nameof`, string interpolation, `$@"..."`
- `in` parameters, `ref readonly`, `ref` locals/returns, `readonly struct`
- `async`/`await`; `Span<T>`/`Memory<T>` via the `System.Memory` NuGet package
- digit separators, binary literals, `private protected`

## NOT available on C# 7.3 (do not emit unless LangVersion proves it)

| Feature | Introduced |
|---|---|
| nullable reference types (`#nullable`, `string?` on reference types) | C# 8 |
| `using` declarations, default interface members, ranges/indices (`^`, `..`) | C# 8 |
| static local functions, null-coalescing assignment `??=` | C# 8 |
| records, init-only setters, target-typed `new()`, top-level statements | C# 9 |
| `or`/`and`/`not` and relational patterns | C# 9 |
| file-scoped namespaces, global usings, `ImplicitUsings` | C# 10 |
| `record struct`, list patterns, raw string literals, primary constructors (non-record) | C# 11/12 |

> Nullable VALUE types (`int?`, `bool?` = `Nullable<T>`) are fine — they predate C# 7.
> Only nullable REFERENCE types (`object?`, `string?`) are the C# 8 feature to avoid.

### C# 7.3-safe rewrites of common modern syntax

```csharp
// C# 8+:  private DelegateCommand? _cmd;  _cmd ??= new DelegateCommand(Run);
// C# 7.3:
private DelegateCommand _cmd;
public DelegateCommand Cmd { get { return _cmd ?? (_cmd = new DelegateCommand(Run)); } }

// C# 9 target-typed new:  Lazy<T> x = new(() => ...);
// C# 7.3:
private static readonly Lazy<T> X = new Lazy<T>(() => new T());

// C# 9 `or` pattern:  if (p is "a" or "b")
// C# 7.3:
if (Equals(p, "a") || Equals(p, "b"))

// C# 10 file-scoped namespace -> block-scoped:
namespace MyApp { /* ... */ }
```

## BCL / NuGet API availability on net472

The net472/net48 BCL is the .NET Framework BCL, NOT the .NET (Core) BCL — many
modern overloads and types do not exist. Before calling an unfamiliar API:

- Use HandMirrorMcp `get_type_info` to confirm a type/member exists in the
  project's referenced assemblies, and `inspect_nuget_package_type` for NuGet
  package surfaces.
- A NuGet package needs a `net472`/`net48`/`netstandard2.0` asset to be usable —
  check the package's target frameworks (`inspect_nuget_package`).
- `analyze_csproj` to confirm the target framework and language version.

Do not assume a member exists because it exists on .NET 8+; verify for net472.
