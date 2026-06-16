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
| `7f58eff` | Bootstrap | `setup.ps1` (one command after clone) + `hooks/BootstrapCheck.cs`; auto-configure knowledge path to the clone; fix the MCP config-dir mismatch (`~/.wpf-dev-pack-mcp` → fork name) that had broken set-repo-path |
| `20a847e` | #6 Generators | Remove the 5 .NET 10 / Extensions.AI chat skills + routing/README cleanup |
| `0c38b53` | #6 Generators | make-wpf-viewmodel + make-wpf-project → hand-rolled MVVM + SDK-style net48 (verified builds); Prism variants reframed opt-in/net472 |
| `4309a56` | #6 Generators | make-wpf-service/usercontrol → hand-rolled; CodeFormatter → vendored xstyler.exe (no dnx); converter-patterns C#-7.3-safe |
| `270adf6` | #7 Knowledge | Add `implementing-handrolled-mvvm` topic; repoint topic-id refs in agents/README/topics |
| `02be46a` | #7 Knowledge | Remove the CTK topic + the Extensions.AI/LLM-chat cluster (5 topics); fix dangling refs |
| `9a82fef` | #7 Knowledge | Add 3 net472 legacy topics; reconcile DI/collectionview topics (61 topics total) |
| `9630520` | #10 Agents | De-CTK agent bodies (wpf-mvvm-expert full rewrite, data-binding/code-reviewer/architect) + README → hand-rolled |
| `54c57c2` | Docs | Sync Korean mirrors (README.ko, .claude.ko/CLAUDE.md) + TERMINOLOGY(.ko); version badge 1.0.0 / Peace-Min |
| `bc468d1` | #8 Docs | Repo-root README offline quick-start; deployment & verification guide |

### Key mechanism note
Installed plugins do **not** auto-load `.claude/CLAUDE.md` or `.claude/rules` — only
skills, agents, and hooks deliver context. So the hard guardrails ship as a SessionStart
hook (`Net472GuardrailsLoader.cs`), mirroring the existing `WpfAuthoringRulesLoader.cs`.

### Verification performed
- **WpfDevPackMcp:** builds (net10) and starts; `tools/list` returns all 4 tools
  (`list/get/search/refresh_wpf_topics`). Full startup confirmed via a net9.0 proxy build
  because this machine has only the **.NET 10 preview.5** runtime, which lacks the net10-RTM
  `System.Text.Json` API that `Microsoft.Extensions.AI` needs. On RTM 10.0.300+ the net10 build runs.
- **Bootstrap:** `setup.ps1` run end-to-end under Windows PowerShell 5.1 — it published
  WpfDevPackMcp, installed HandMirrorMcp + XamlStyler from NuGet (shims `handmirror.exe`
  / `xstyler.exe`), and wrote `config.json` (repoPath = clone). `BootstrapCheck.cs`
  correctly prints the bootstrap command when `bin/` is missing and is silent once built.
- **Net472GuardrailsLoader / MvvmViolationDetector:** run-verified via `dotnet run`
  (bare `dotnet file.cs` is unsupported on preview.5 but works on RTM). MvvmViolationDetector
  correctly flags `CommunityToolkit.Mvvm` and `System.Windows.*` in a ViewModel.

---

## 4. Remaining TODO

### #6 — Generators (`make-wpf-*`) ✅ DONE (`20a847e`, `0c38b53`, `4309a56`)
- Removed the 5 .NET 10 / Extensions.AI chat skills.
- `make-wpf-viewmodel` / `make-wpf-project` rewritten for hand-rolled MVVM + SDK-style net48 (build-verified).
- `make-wpf-service` / `make-wpf-usercontrol` de-CTK'd; CodeFormatter uses the vendored `xstyler.exe`.
- Residual modern-C# in converter/custom-control/behavior examples is corrected at generation time by the `Net472GuardrailsLoader` hook (C# 7.3-safe enforced every session).

### #7 — Knowledge ✅ DONE (`270adf6`, `02be46a`, `9a82fef`)
- Created `implementing-handrolled-mvvm`; removed the CTK topic + the Extensions.AI/LLM-chat cluster (5 topics) with ref fixes; added 3 net472 legacy topics (legacy projects, VS-MSBuild build, C# 7.3); reconciled DI/collectionview. 61 topics.

### #10 — Agent/README de-CTK ✅ DONE (`9630520`)
- wpf-mvvm-expert fully rewritten to hand-rolled (C# 7.3); data-binding/code-reviewer/architect de-CTK'd; code-formatter drops the [ObservableProperty] rule + uses xstyler.exe; README highlights/quick-start/tables → hand-rolled.

### Korean mirrors ✅ DONE (`54c57c2`)
- `README.ko.md`, `.claude.ko/CLAUDE.md`, `docs/TERMINOLOGY(.ko).md` synced to the English net472/hand-rolled/offline source; version badge 1.0.0 / Peace-Min.

### #8 — Bundle + verification ✅ DOC DONE (`bc468d1`)
- Repo-root README offline quick-start; [deployment & verification guide](2026-06-16-net472-airgap-deployment-guide.md) (prerequisites, BOM, offline NuGet feed, verification checklist, troubleshooting).
- **Remaining (needs the actual air-gapped machine):** run the blocked-network verification matrix on an RTM 10.0.300+ PC and record evidence (hashes/SBOM/license manifest for the transfer bundle).

### Out of scope (noted)
- Repo-root `.claude/rules/dotnet/**` are the maintainer's general .NET dev config (inherited from upstream, not shipped in the plugin); they still describe CTK/latest-.NET. Reconciling them is separate from the net472 plugin deliverable.

---

## 5. Setting up a clone (closed network)

The target PC has the .NET 10 RTM SDK, Claude Code, NuGet access, and VS MSBuild,
so it builds everything itself — no pre-built binary transfer needed. git cannot
auto-run a script on clone, so the setup is **one command**:

```powershell
git clone <internal-remote>/dotnet-with-claudecode.git
cd dotnet-with-claudecode
pwsh ./setup.ps1          # or: powershell -ExecutionPolicy Bypass -File ./setup.ps1
claude --plugin-dir ./wpf-net472-airgap-dev-pack
```

`setup.ps1` verifies the RTM SDK, runs `tools/build-local-bin.ps1` (publishes
WpfDevPackMcp + vendors HandMirrorMcp/XamlStyler into `bin/`), and writes
`~/.wpf-net472-airgap-dev-pack-mcp/config.json` pointing the knowledge MCP at the
clone (no `set-repo-path` needed). A SessionStart hook (`BootstrapCheck.cs`)
reminds the user to run it if `bin/` is missing. Re-run only after pulling new commits.

Underlying build options: `pwsh ./wpf-net472-airgap-dev-pack/tools/build-local-bin.ps1
-Source <feed> -SelfContained -XamlStylerVersion <v>`.

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
