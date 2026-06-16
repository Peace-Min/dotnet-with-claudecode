# WPF Dev Pack Skills — Routing

Knowledge topics are NO LONGER plugin skills. They live in
`knowledge/<id>/` (at the repo root, outside the plugin) and are served by the `WpfDevPackMcp` MCP
server. There is no keyword-router hook: the MCP server's own
instructions tell the agent to call `search_wpf_topics` (ranked over the
live catalog) and load hits with `get_wpf_topic` before answering WPF
questions. New topics are discovered automatically — nothing to register.

Only command skills remain under `skills/` and are slash-invocable:

| Keyword (intent) | Command skill |
|---|---|
| `create viewmodel`, `뷰모델 생성` | `make-wpf-viewmodel` |
| `create service`, `서비스 생성` | `make-wpf-service` |
| (explicit) | `make-wpf-project`, `make-wpf-custom-control`, `make-wpf-usercontrol`, `make-wpf-converter`, `make-wpf-behavior` |
| `chat client`, `LLM chat UI`, `채팅 클라이언트` | `make-wpf-chatclient` (one-button full client) |
| (explicit, chat components) | `make-wpf-markdown-presenter`, `make-wpf-chat-bubble-template`, `make-wpf-chatclient-factory`, `make-wpf-chat-orchestrator` |
| (auto) C#/XAML formatting | `formatting-wpf-csharp-code` |
| `feedback` (maintainer) | `collecting-wpf-net472-airgap-dev-pack-feedback` |
| `language` | `configuring-wpf-net472-airgap-dev-pack-language` |
| `repo path`, MCP unconfigured | `set-repo-path` |
| `repo branch`, knowledge branch | `set-repo-branch` |
| `managed flag`, stop MCP git reset | `set-repo-managed` |
| `show config`, MCP state/path/branch | `show-wpf-net472-airgap-dev-pack-config` |

To add a knowledge topic: create `knowledge/<id>/TOPIC.md`
(NO frontmatter — first `# H1` is the title; put a one-line `> summary`
blockquote directly under the H1; the MCP catalog reads both from the body).
No router edit, no plugin skill, no version bump, no MCP rebuild — the
catalog auto-discovers it and the server picks it up on the next local rescan
(`refresh_wpf_knowledge`); offline, this is a disk rescan with no network.

---

### HandMirror MCP — .NET API Verification (local, offline)

`HandMirrorMcp` is a LOCAL bundled MCP server. It inspects assemblies and NuGet
packages already on disk, so it needs no network — making it the **primary**
defense against hallucinated APIs in this offline fork (there is no context7 /
Microsoft Learn to fall back on).

**Trigger condition**: before writing or changing code that calls any .NET /
NuGet API whose exact namespace, type, or signature you are not fully certain of
— especially `net472`/`net48` API availability and DevExpress / third-party
assemblies already referenced by the target solution.

**Verification rules:**

```
WHEN unsure about a .NET API or package surface:
  USE HandMirrorMcp to verify against the LOCAL assemblies/packages:
    - inspect_nuget_package: List namespaces/types in a NuGet package
    - inspect_nuget_package_type: Get exact method signatures
    - search_nuget_packages: Search packages by keyword
    - get_type_info: Inspect local assembly (.dll/.exe) types
    - explain_build_error: Diagnose CS/NU build errors
    - analyze_csproj: Analyze project file for issues
```

**Usage scenarios:**
- Confirm an API/type actually exists in the project's target framework (net472/net48)
- Verify API name casing accuracy in NuGet packages (e.g., SQLite vs Sqlite)
- Identify correct namespaces for extension methods
- Inspect DevExpress / third-party assemblies already referenced by the solution
- Check API breaking changes across package versions
- Diagnose build errors (CS0246, NU1605, etc.) and recommend already-available packages
