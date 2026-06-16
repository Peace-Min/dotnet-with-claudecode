# Working with legacy .NET Framework 4.7.2-4.8 projects

> Detect and preserve the shape of an existing net472/net48 WPF solution before editing: non-SDK (legacy MSBuild XML) vs SDK-style `.csproj`, `packages.config` vs `PackageReference`, `app.config` + assembly binding redirects, and platform target (AnyCPU/x86/x64, Prefer32Bit). Use when adding code to an existing .NET Framework WPF app — never modernize the project shape unless asked.

This fork maintains **existing** net472/net48 apps. Before touching a project,
read its `.csproj` and detect its style, then keep adding files in that style.

## 1. Non-SDK (legacy) vs SDK-style csproj

**Legacy non-SDK** — starts with an XML declaration and
`<Project ToolsVersion="..." xmlns="http://schemas.microsoft.com/developer/msbuild/2003">`,
imports `Microsoft.CSharp.targets`, lists every `<Compile Include="...">` explicitly,
and has `<Reference>` items. This is what Visual Studio's "WPF App (.NET Framework)"
template produces. Do **not** auto-convert it to SDK-style.

```xml
<Project ToolsVersion="15.0" DefaultTargets="Build"
         xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup>
    <TargetFrameworkVersion>v4.7.2</TargetFrameworkVersion>
    <OutputType>WinExe</OutputType>
    <Platform Condition=" '$(Platform)' == '' ">AnyCPU</Platform>
  </PropertyGroup>
  <ItemGroup>
    <Reference Include="PresentationCore" />
    <Reference Include="PresentationFramework" />
    <Reference Include="WindowsBase" />
  </ItemGroup>
  <ItemGroup>
    <Compile Include="MainWindow.xaml.cs"><DependentUpon>MainWindow.xaml</DependentUpon></Compile>
    <Page Include="MainWindow.xaml"><Generator>MSBuild:Compile</Generator><SubType>Designer</SubType></Page>
  </ItemGroup>
  <Import Project="$(MSBuildToolsPath)\Microsoft.CSharp.targets" />
</Project>
```

> In a legacy project you must **add new files to the `.csproj`** (`<Compile>`,
> `<Page>`, `<Resource>`) — they are not globbed. Forgetting this means the file
> compiles in the IDE but not from the command line, or XAML build actions are wrong.

**SDK-style targeting net472/net48** — `<Project Sdk="Microsoft.NET.Sdk">` with
`<TargetFramework>net48</TargetFramework>` + `<UseWPF>true</UseWPF>`. Files are
globbed (no explicit `<Compile>`). Both styles are valid; **match the project**.

## 2. packages.config vs PackageReference

- **`packages.config`** (legacy): a separate file lists `<package id="..." version="..." targetFramework="net472" />`.
  References resolve from the solution's `packages/` folder. NuGet restore must
  use this folder feed; restore from an **approved local/internal feed** only.
- **`PackageReference`** (in the csproj): `<PackageReference Include="..." Version="..." />`.
  SDK-style projects use this; some legacy projects were migrated to it.

Add a package in the **same style** the project already uses. Do not migrate
`packages.config` ⇄ `PackageReference` unless asked.

## 3. app.config + assembly binding redirects

A net472 app usually has an `app.config` with `<runtime><assemblyBinding>` binding
redirects that unify transitive dependency versions. Preserve and update these when
adding packages — a missing/incorrect `bindingRedirect` causes a runtime
`FileLoadException` ("the located assembly's manifest definition does not match").

```xml
<runtime>
  <assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1">
    <dependentAssembly>
      <assemblyIdentity name="Newtonsoft.Json" publicKeyToken="30ad4fe6b2a6aeed" culture="neutral" />
      <bindingRedirect oldVersion="0.0.0.0-13.0.0.0" newVersion="13.0.0.0" />
    </dependentAssembly>
  </assemblyBinding>
</runtime>
```

## 4. Platform target

Check `<PlatformTarget>` / `<Platform>` (AnyCPU / x86 / x64) and `<Prefer32Bit>`.
WPF apps depending on native or 32-bit-only COM interop are often `x86` (or AnyCPU
+ `Prefer32Bit`). Keep the existing platform target; changing it can break native/COM
loads.

## Checklist before editing an existing project

- [ ] Non-SDK or SDK-style? (add files accordingly)
- [ ] `packages.config` or `PackageReference`? (add packages in that style)
- [ ] `app.config` binding redirects present? (update when adding packages)
- [ ] Platform target (AnyCPU/x86/x64, Prefer32Bit)? (preserve)
- [ ] Effective C# `LangVersion`? (emit only what it compiles — default C# 7.3)
