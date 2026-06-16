# wpf-net472-airgap-dev-pack — Fork Progress & TODO

Status report for the air-gapped net472/net48 fork of `wpf-dev-pack`.

- **Repo:** `Peace-Min/dotnet-with-claudecode`
- **Branch:** `feat/net472-airgap-fork` (pushed)
- **Baseline:** upstream `christian289/dotnet-with-claudecode` `wpf-dev-pack` v1.7.4 (`cf27bbe`)
- **Plan of record:** [`docs/plans/2026-06-15-wpf-net472-airgap-fork-handoff.md`](2026-06-15-wpf-net472-airgap-fork-handoff.md)
- **Last updated:** 2026-06-16 (Asia/Seoul)

---

## 1. Objective (recap)

Turn the upstream plugin (latest .NET, CommunityToolkit by default, some online-MCP
dependencies) into a private fork for an **air-gapped Windows PC** that develops
**existing .NET Framework 4.7.2–4.8 (net472/net48)** WPF apps:

1. **Local MCP only** — no `dnx`/NuGet resolution at runtime; servers run from `bin/`.
2. **No online MCP** — context7 / Microsoft Learn excluded; no "missing MCP" warnings.
3. **No CommunityToolkit.Mvvm** — dependency-free hand-rolled MVVM.
4. **net472/net48 specialization** — never modernize; preserve the existing project shape.

---

## 2. Locked decisions

| Topic | Decision |
|---|---|
| Plugin name | `wpf-net472-airgap-dev-pack` (also the slash namespace) |
| Marketplace id | `dotnet-net472-airgap-plugins` |
| Develop where | This internet PC (`C:\Users\CEO\Desktop\wpf-plugin`); bundle is transferred to the closed PC |
| WpfDevPackMcp | Build from `mcp/` source → local exe; offline by default (`WPFDEVPACK_OFFLINE=1`) |
| HandMirrorMcp | Keep; vendor from NuGet via `dotnet tool install --tool-path` (not `dnx` at runtime) |
| XamlStyler | Vendor locally (`bin/XamlStyler`); keep auto-format |
| MVVM | Always hand-rolled `BindableBase` + `RelayCommand`; **no DevExpress/framework detection**; create base classes if absent |
| RelayCommand | CommandManager auto-requery (classic) |
| Prism | Opt-in alternative only — never default, never auto-introduced |
| Build SDK | **.NET 10 RTM 10.0.300+** required (a preview SDK yields MCP binaries that crash at startup) |

---

## 3. Work completed (branch `feat/net472-airgap-fork`)

| Commit | Task | Summary |
|---|---|---|
| `d21c5dc` | #1 Identity | Rename plugin dir + all references; fork repo/version/marketplace/keywords; LICENSE keeps upstream + adds fork copyright |
| `af425ad` | #2 Local MCP | `.mcp.json` → local exe launch; WpfDevPackMcp offline gate; `tools/build-local-bin.ps1`; disabled git-pull refresh |
| `6517e82` | #3 Online deps | Remove context7/Microsoft Learn from agents; delete McpDependencyChecker + HandMirrorReminder hooks; offline-mode docs |
| `d0f85fb` | #4 net472 guardrails | CLAUDE.md Target-Framework section; `hooks/Net472GuardrailsLoader.cs` SessionStart hook (enforced for installed users) |
| `3ab9603` | #5 Hand-rolled MVVM | Rewrite mvvm-constraints / prohibitions / wiring rules; MvvmViolationDetector flags CTK; fix a latent CS8803 |
| `8990f8b` | #5 follow-up | Fix stale `view-viewmodel-wiring-communitytoolkit` references in agents/TERMINOLOGY |

### Key mechanism note
Installed plugins do **not** auto-load `.claude/CLAUDE.md` or `.claude/rules` — only
skills, agents, and hooks deliver context. So the hard guardrails ship as a SessionStart
hook (`Net472GuardrailsLoader.cs`), mirroring the existing `WpfAuthoringRulesLoader.cs`.

### Verification performed
- **WpfDevPackMcp:** builds (net10) and starts; `tools/list` returns all 4 tools
  (`list/get/search/refresh_wpf_topics`). Full startup confirmed via a net9.0 proxy build
  because this machine has only the **.NET 10 preview.5** runtime, which lacks the net10-RTM
  `System.Text.Json` API that `Microsoft.Extensions.AI` needs. On RTM 10.0.300+ the net10 build runs.
- **Net472GuardrailsLoader / MvvmViolationDetector:** run-verified via `dotnet run`
  (bare `dotnet file.cs` is unsupported on preview.5 but works on RTM). MvvmViolationDetector
  correctly flags `CommunityToolkit.Mvvm` and `System.Windows.*` in a ViewModel.

---

## 4. Remaining TODO

### #6 — Generators (`make-wpf-*`) + remove .NET 10-only skills
- `make-wpf-viewmodel`: emit hand-rolled `BindableBase`/`RelayCommand` (create `Mvvm/` if absent); drop CTK.
- `make-wpf-project` (+ `PRISM.md`): generate `net48`/`net472` projects (offer non-SDK + `packages.config`), C# 7.3-safe; not `net10.0-windows`.
- `make-wpf-usercontrol`, `make-wpf-custom-control`, `make-wpf-converter`, `make-wpf-service`, `make-wpf-behavior`: net472/C# 7.3-safe output; inspect the solution first.
- Remove or defer the .NET 10 / Extensions.AI chat skills: `make-wpf-chatclient`, `make-wpf-chatclient-factory`, `make-wpf-chat-orchestrator`, `make-wpf-chat-bubble-template`, `make-wpf-markdown-presenter` (and their routing-table rows in `skills/.claude/CLAUDE.md`).

### #7 — Knowledge audit + net472 topics
- Create `implementing-handrolled-mvvm` topic (referenced by MvvmViolationDetector + agents).
- Reconcile/replace CTK & modern topics (`implementing-communitytoolkit-mvvm`, `hosting-extensions-ai-chatclient-in-wpf-mvvm`, `configuring-dependency-injection`, …).
- Add legacy topics: non-SDK `.csproj`, `packages.config` offline restore, `app.config` + binding redirects, VS MSBuild discovery (`vswhere`), x86/x64/AnyCPU/`Prefer32Bit`, designer build actions, `Dispatcher`/STA/COM interop/P/Invoke, net472 API availability checks.

### #8 — Build, transfer bundle (BOM), verification matrix
- Run `tools/build-local-bin.ps1` on an **RTM 10.0.300+** machine; confirm both MCP servers start after a NuGet/`uv` cache cleanup.
- Assemble the offline bundle: .NET SDK 10.0.300+, net472/48 Developer Pack, VS Build Tools + `vswhere.exe`, vendored MCP exes, local NuGet folder feed, hashes/versions/licenses manifest.
- Execute the handoff doc's verification matrix on a network-blocked machine; record evidence.

### Deferred — Korean-mirror docs sync
English is authoritative. Still to mirror: `README.ko.md` (offline sections), `.claude.ko/CLAUDE.md`
(MVVM Composition + .NET version + Essential), `docs/TERMINOLOGY.ko.md`. Also a fuller
`TERMINOLOGY.md` rework (it still frames composition around CTK/Prism paths).

---

## 5. How to build the local executables

On a machine with internet (or an approved internal feed) and the **RTM** SDK:

```powershell
cd wpf-net472-airgap-dev-pack
pwsh ./tools/build-local-bin.ps1
# -> bin/WpfDevPackMcp (from ../mcp), bin/HandMirrorMcp, bin/XamlStyler
# options: -Source <feed>  -SelfContained  -XamlStylerVersion <v>  -AllowPreviewSdk
```

`bin/` is git-ignored; it is produced at bundle-prep time and transferred into the closed network.

---

## 6. Next-session opening prompt

```text
Continue the wpf-net472-airgap-dev-pack fork on branch feat/net472-airgap-fork.
Read docs/plans/2026-06-16-net472-airgap-fork-progress.md (this file) and the
handoff doc. Tasks #1–#5 are done and committed. Start Task #6: rewrite the
make-wpf-* generators to emit net472/net48 + C#-7.3-safe code with hand-rolled
BindableBase/RelayCommand, and remove/defer the .NET 10 chat/streaming skills.
Do not modernize; do not reintroduce CommunityToolkit.
```
