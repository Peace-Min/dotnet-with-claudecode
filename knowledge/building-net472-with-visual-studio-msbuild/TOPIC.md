# Building net472/net48 with Visual Studio MSBuild

> Build existing .NET Framework 4.7.2-4.8 WPF solutions with the solution's own Visual Studio MSBuild toolchain, discovered via vswhere.exe, and restore packages only from approved local/internal feeds (never public NuGet). Use when compiling or verifying a net472/net48 app in a closed network.

Legacy net472 WPF solutions build best with **Visual Studio MSBuild**, not
necessarily `dotnet build`. SDK-style net472 projects can use `dotnet build`;
legacy non-SDK projects should use VS MSBuild.

## 1. Discover MSBuild with vswhere

`vswhere.exe` ships with Visual Studio at
`%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe`.

```powershell
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$msbuild = & $vswhere -latest -requires Microsoft.Component.MSBuild `
    -find MSBuild\**\Bin\MSBuild.exe | Select-Object -First 1
# e.g. C:\Program Files\Microsoft Visual Studio\2022\...\MSBuild\Current\Bin\MSBuild.exe
```

If `vswhere` is absent, use an administrator-provided fixed MSBuild path.

## 2. Build

```powershell
& $msbuild ".\Product.sln" /m /t:Build /p:Configuration=Debug /p:Platform="Any CPU"
```

- `/m` — parallel build. `/t:Rebuild` to force a clean rebuild.
- `/p:Configuration=Debug|Release`, `/p:Platform="Any CPU"|x86|x64` — match the
  solution's configurations.
- `/p:RestorePackagesConfig=true` (or run NuGet restore first) for `packages.config`
  projects.

## 3. Restore — offline only

- **`packages.config`**: restore into the solution's `packages/` folder from an
  approved local folder feed or internal NuGet server. Never restore from
  `api.nuget.org`.

  ```powershell
  & nuget.exe restore ".\Product.sln" -Source "C:\offline-nuget" -PackagesDirectory ".\packages"
  ```

- **`PackageReference`**: `& $msbuild ".\Product.sln" /t:Restore /p:RestoreSources="C:\offline-nuget"`,
  or configure a `nuget.config` whose only `<packageSources>` is the local feed
  (with `<clear />` to disable nuget.org).

```xml
<!-- nuget.config: offline feed only -->
<configuration>
  <packageSources>
    <clear />
    <add key="local" value="C:\offline-nuget" />
  </packageSources>
</configuration>
```

## 4. Runtime is not compile-time

A clean compile does NOT instantiate XAML. A ControlTemplate / resource error
surfaces only when the template is applied to a live control. After building,
run the app (and exercise representative views/dialogs) to catch
`StaticResourceHolder`, `MC4111`, and other apply-time failures.

## Notes

- The plugin's own hooks/MCP run on .NET 10 — that is the tooling runtime, not the
  build toolchain for the net472 app.
- For build errors, use HandMirrorMcp `explain_build_error` / `analyze_csproj`.
