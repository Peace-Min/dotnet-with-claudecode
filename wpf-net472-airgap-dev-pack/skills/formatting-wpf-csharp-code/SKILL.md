---
description: Formats WPF XAML and C# code using XamlStyler and dotnet format. Generates Settings.XamlStyler and .editorconfig files automatically. Use when code formatting or style cleanup is needed.
user-invocable: false
---

# WPF and C# Code Formatting

Applies consistent code style to XAML and C# files.

---

## 1. Required Tools

### XamlStyler (XAML) — local, vendored

XAML is formatted by the locally vendored XamlStyler at
`${CLAUDE_PLUGIN_ROOT}/bin/XamlStyler/xstyler.exe`, built once by
`tools/build-local-bin.ps1` / `setup.ps1`. **No `dnx`, no NuGet resolution at
runtime.** If `bin/XamlStyler/` is missing, run the bootstrap (`setup.ps1`).

### dotnet format (C#)

Included with the .NET SDK. Run with `--no-restore` (no NuGet resolution).

---

## 2. Configuration Files

### Settings.XamlStyler

Copy from template to workspace root if `Settings.XamlStyler` doesn't exist.

**Template location**: `templates/Settings.XamlStyler`

**Key settings**:
- `AttributesTolerance: 1` - Allow up to 1 attribute on same line
- `KeepFirstAttributeOnSameLine: true` - Keep first attribute on element line

### .editorconfig

Copy from template to workspace root if `.editorconfig` doesn't exist.

**Template location**: `templates/.editorconfig`

**Key settings**:
- Indentation: 4 spaces
- Line ending: CRLF (Windows)
- Max line length: 120

---

## 3. Formatting Commands

### XAML Formatting (local xstyler)

```bash
# Format single file
"${CLAUDE_PLUGIN_ROOT}/bin/XamlStyler/xstyler.exe" -f "{file.xaml}" -c "{workspace}/Settings.XamlStyler"

# Format a directory recursively
"${CLAUDE_PLUGIN_ROOT}/bin/XamlStyler/xstyler.exe" -d "{workspace}" -r -c "{workspace}/Settings.XamlStyler"
```

**xstyler Options**:
- `-d`: Target directory
- `-f`: Target file
- `-r`: Recursive processing
- `-c`: Configuration file path

### C# Formatting

```bash
# Format entire solution
dotnet format "{solution.sln}" --no-restore

# Format specific project only
dotnet format "{project.csproj}" --no-restore

# Format single file
dotnet format "{project.csproj}" --include "{file.cs}" --no-restore
```

**Options**:
- `--no-restore`: Skip NuGet restore (faster)
- `--include`: Target specific file

---

## 4. Workflow

### Full Formatting

```
Task Progress:
- [ ] Step 1: Check if Settings.XamlStyler exists, create if not
- [ ] Step 2: Check if .editorconfig exists, create if not
- [ ] Step 3: Run the vendored `xstyler.exe` for XAML formatting
- [ ] Step 4: Run dotnet format for C# formatting
```

### Per-file Formatting (Hook Usage)

```
- When .xaml file modified: Run bin/XamlStyler/xstyler.exe (CodeFormatter hook)
- When .cs file modified: Run dotnet format --no-restore (CodeFormatter hook)
```

---

## 5. Notes

- **Check git status**: Verify uncommitted changes before formatting
- **Binary exclusion**: bin/, obj/ folders automatically excluded
- **Encoding**: UTF-8 with BOM maintained (Visual Studio compatible)

---

## 6. References

- [XamlStyler GitHub](https://github.com/Xavalon/XamlStyler)
- [dotnet format Documentation](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-format)
- [.editorconfig Specification](https://editorconfig.org/)
