# WPF Dev Pack - Configuration

WPF 지식은 WpfDevPackMcp MCP 서버가 온디맨드로 제공합니다(답변 전 검색).
커맨드 스킬은 슬래시로 호출합니다. 키워드 감지 훅은 없습니다.

> 본 파일은 `wpf-net472-airgap-dev-pack/.claude/CLAUDE.md`의 한국어 미러입니다. AI는 영문
> 원본을 읽으며, 본 파일은 사람을 위한 참고용입니다. 갱신은 영문 원본을
> 먼저 수정한 뒤 본 파일에 반영하세요.

---

## MCP 서버 (전부 로컬 / 오프라인)

이 포크는 자체 MCP 서버를 동봉하며 **온라인 MCP에 의존하지 않습니다**.
플러그인의 `.mcp.json`이 `bin/`의 로컬 실행파일로 기동하며
(`tools/build-local-bin.ps1`로 1회 빌드), 프로세스 시작 시 `dnx`/NuGet 해석이
없으므로 NuGet/`uv` 캐시를 정리해도 계속 기동됩니다.

| MCP Server | 동봉 | 용도 |
|---|---|---|
| **WpfDevPackMcp** | ✅ `bin/WpfDevPackMcp` | 로컬 WPF 지식 토픽 제공 (오프라인; 로컬 클론을 읽고 pull하지 않음) |
| **HandMirrorMcp** | ✅ `bin/HandMirrorMcp` | 코드 작성 전 정확한 namespace / API 시그니처 검증 |

### 오프라인 모드 (강제 규칙)

로컬 소스, 로컬 어셈블리, 로컬 NuGet 피드, 로컬 문서, 사전 설치된 도구만
사용합니다. `git pull`, 마켓플레이스 업데이트, `uvx git+https://…`, 공개 피드
대상 온라인 NuGet 검색/복원 등 네트워크 fetch를 암시적으로 수행하지 마세요.
정보가 부족하면 네트워크에 접근하지 말고 사용자에게 물어보세요.

### 제거된 온라인 의존성

**context7**, **microsoft-docs / Microsoft Learn**은 사용하지 않으며 필수가
아닙니다. 정확성 의존성으로 취급하거나 설치를 권하거나, 부재를 이유로 결과가
저하된다고 주장하지 마세요.

### 선택적 로컬 도구 (필수 아님)

일부 agent를 향상시키지만 없어도 플러그인은 완전히 동작합니다. 승인된 오프라인
패키지로만 설치하고 런타임에 네트워크로 가져오지 마세요.

| 도구 | 용도 | 부재 시 |
|---|---|---|
| **serena** | Semantic 코드 분석, 심볼 네비게이션 | Read/Grep/Glob으로 폴백. 원하면 전송한 사본으로 `uv` 설치. |
| **csharp-lsp** | C# LSP 코드 지능 | `wpf-code-reviewer`가 텍스트 분석으로 폴백. |

---

## MVVM Composition Style

이 포크는 모든 생성 코드에 **단 하나의 MVVM 스타일**을 사용합니다:
외부 MVVM 패키지 없이 net472/net48에서 컴파일되며 어떤 프로젝트에서도
동작하는 **의존성 없는 손수 작성(hand-rolled) MVVM**입니다.

- ViewModel은 손수 작성한 **`BindableBase : INotifyPropertyChanged`**
  (`SetProperty` / `RaisePropertyChanged`)를 상속합니다. Command는 손수 작성한
  **`RelayCommand` / `RelayCommand<T> : ICommand`**입니다.
- 프로젝트에 이러한 base 클래스가 없으면 **1회 생성**(예:
  `Mvvm/BindableBase.cs` + `Mvvm/RelayCommand.cs`)한 뒤 재사용합니다.
  `make-wpf-viewmodel` 스캐폴더가 부재 시 이를 emit합니다.
- **CommunityToolkit.Mvvm 사용 금지** — `ObservableObject`,
  `[ObservableProperty]`, `[RelayCommand]`, source generator 없음.
  **프레임워크 자동 감지 없음**(DevExpress/CTK/Prism sniffing 없음) — 항상
  손수 작성 형태를 emit합니다.
- View/ViewModel 와이어링은 프로젝트마다 명시적 메커니즘 하나를 사용합니다.
  `rules/view-viewmodel-wiring-handrolled.md` 참조. 기존 프로젝트가 이미
  사용 중인 것(자체 base 클래스, DataTemplate 매핑 등)은 **보존**합니다.

> **Prism**은 이미 Prism을 사용하는 프로젝트를 위한 명시적 opt-in으로만
> 유지되며 — 절대 기본값이 아닙니다.
> `rules/view-viewmodel-wiring-prism.md` 참조.

상세는 `rules/mvvm-constraints.md` 및 `rules/prohibitions.md` 참조.

---

## Essential (Post-Compact)

다음 규칙은 컨텍스트 압축 후에도 반드시 살아남아야 합니다. 이전 컨텍스트가
유실된 경우 이 섹션을 다시 읽으세요:

1. **대상은 .NET Framework 4.7.2–4.8** — 프레임워크, 프로젝트 포맷, 패키지 관리 방식, C# 버전을 절대 현대화하지 말 것; 기존 프로젝트 형태를 감지·보존. 기본 emit C#은 **7.3-safe** (`## Target Framework` 참조).
2. **오프라인 전용** — 로컬 소스/어셈블리/피드/문서와 사전 설치 도구만; 네트워크 fetch, `dnx`/`uvx`/온라인 NuGet 복원·검색 없음.
3. **MVVM은 의존성 없는 손수 작성** `BindableBase`/`RelayCommand` — CommunityToolkit 없음, 프레임워크 자동 감지 없음; base 클래스가 없으면 생성 (`rules/mvvm-constraints.md`).
4. **No System.Windows in ViewModel** — BCL 타입만 (`rules/mvvm-constraints.md`)
5. **모든 Freezable 객체 Freeze** — Brush, Pen, Geometry (`rules/freezable-performance.md`)
6. **Generic.xaml = MergedDictionaries 허브 전용** (`rules/resourcedictionary-patterns.md`)
7. **코드 작성 전 HandMirrorMcp(로컬)로 API 시그니처 검증**
8. **WPF 지식 토픽은 `WpfDevPackMcp get_wpf_topic(id)`로 조회** — `skills/`에서 로드하지 않음.

---

## Per-Project Language Preference

플러그인은 프로젝트별 응답 언어 환경설정을 지원하며,
`LanguagePreferenceLoader` SessionStart 훅이 매 새 대화 시작 시 이를
읽어 시스템 컨텍스트에 주입합니다.

- **설정**: `/wpf-net472-airgap-dev-pack:configuring-wpf-net472-airgap-dev-pack-language`를 실행해
  `.claude/wpf-net472-airgap-dev-pack.local.md`에 `language:` 필드(BCP-47 코드,
  예: `ko`, `en`, `ja`, `zh`)를 작성.
- **효과**: 다음 세션부터 훅이 시스템 컨텍스트에 해당 언어로 응답하도록
  지시문을 주입. SessionStart 훅은 세션 시작 시에만 발화하므로 현재
  세션에는 in-session 변경이 반영되지 않음.
- **범위**: wpf-net472-airgap-dev-pack 컨텍스트 내 사용자 응답에 적용. Skill 콘텐츠
  언어 정책(SKILL.md 본문, 코드 주석)은 영향 없음 — 영문 단일 유지.
- **오버라이드**: 사용자가 in-conversation으로 항상 오버라이드 가능
  ("respond in English" / "한글로 답해줘"). 훅은 세션 기본값만 설정.
- **되돌리기**: `.claude/wpf-net472-airgap-dev-pack.local.md` 삭제 또는 `language:`
  필드 제거. 훅은 아무것도 emit하지 않게 되고 플러그인 기본 언어
  동작이 적용됨.

이 파일은 개인용이며 저장소 `.gitignore`(`.claude/*.local.md`)가
처리합니다.

## Target Framework — .NET Framework 4.7.2–4.8 (net472/net48)

이 포크는 **.NET Framework 4.7.2–4.8** 기반의 **기존** Windows WPF 앱을
유지보수·확장합니다. 현대화하지 않습니다. 기본 대상은 `net472`/`net48`이며,
.NET (Core) `netX.0`이 아닙니다.

### 강제 가드레일 (최우선순위 — 컨텍스트 압축에서도 생존)

1. **프레임워크를 절대 현대화하지 말 것.** 사용자가 명시적으로 요청하지 않는 한
   `TargetFrameworkVersion` / `TargetFramework`를 올리거나, `netX.0`으로
   리타겟하거나, 프로젝트 포맷을 변환하지 마세요. 신규 프로젝트는 `net48`(요청 시
   `net472`)을 기본값으로 합니다.
2. **편집 전 기존 프로젝트 형태를 감지·보존:**
   - SDK 스타일 vs 비-SDK(레거시 MSBuild XML) `.csproj`
   - `PackageReference` vs `packages.config`
   - `app.config` + 어셈블리 **binding redirect**, 플랫폼 타깃
     (`AnyCPU`/`x86`/`x64`, `Prefer32Bit`), 기존 빌드 구성
3. **프로젝트의 실효 C# 언어 버전에 맞출 것.** 프레임워크만으로 C# 7.3을
   가정하지 마세요 — `net472` 프로젝트가 더 최신 Roslyn으로 컴파일될 수 있습니다.
   다만 프로젝트가 컴파일할 수 없는 구문은 절대 EMIT하지 마세요. net472에서
   `LangVersion`이 미상 또는 기본값이면 **C# 7.3**을 대상으로 합니다(아래 표).
   확신이 없으면 HandMirrorMcp `analyze_csproj` / `get_type_info`로 검증.
4. **MVVM composition 보존.** 프로젝트의 기존 View/ViewModel 와이어링과 base
   클래스를 유지합니다. 기본 생성 MVVM은 의존성 없는 손수 작성
   `BindableBase`/`RelayCommand`(`rules/mvvm-constraints.md`)입니다. 명시적
   요청이 없는 한 CommunityToolkit.Mvvm, Prism, Generic Host, 그 외 DI/MVVM
   프레임워크를 도입하지 마세요.
5. **오프라인 전용.** 로컬 어셈블리, 로컬 NuGet 피드, 승인된 로컬 문서만 사용.
   공개 피드 대상 복원 없음; `dnx`/`uvx`/온라인 NuGet 검색 없음.

### net472/net48에서 안전한 C# 언어 기능 (기본 C# 7.3)

csproj가 더 높은 `LangVersion`을 증명하지 않는 한 **C# 7.3**을 기본으로 합니다.

| 기능 | net472에서 기본 안전? |
|---|---|
| 튜플, `out var`, `is`/`switch` 패턴 매칭, 로컬 함수 | ✅ 예 (C# 7.x) |
| `async`/`await`, `in`/`ref readonly`, `Span<T>` (`System.Memory` 경유) | ✅ 예 |
| expression-bodied 멤버, `nameof`, 문자열 보간 | ✅ 예 |
| nullable reference types (`#nullable`, `?` 주석) | ❌ 아니오 (C# 8) |
| `using` 선언, default interface 멤버, range/index | ❌ 아니오 (C# 8) |
| record, init-only setter, target-typed `new`, top-level statement | ❌ 아니오 (C# 9) |
| file-scoped namespace, global using, `ImplicitUsings` | ❌ 아니오 (C# 10 / SDK 스타일) |

프로젝트가 더 높은 `LangVersion`을 설정하면 해당 기능을 사용할 수 있습니다 — 먼저 검증.

### 빌드 & 검증

- 솔루션의 확립된 **Visual Studio MSBuild** 툴체인으로 빌드합니다.
  `vswhere.exe`(또는 관리자가 제공한 고정 MSBuild 경로)로 탐색:
  `& $MSBuildPath .\Product.sln /m /t:Build /p:Configuration=Debug`.
- `dotnet build`는 지원이 입증된 솔루션에만 사용합니다. 공개 피드 대상 복원을
  **절대** 하지 말 것 — 승인된 로컬/내부 피드만 사용합니다.
- 클린 컴파일은 XAML을 인스턴스화하지 않습니다. 가능한 경우 대표 view/template이
  런타임에 로드되는지 검증하세요.

> 플러그인 자체 지원 런타임(훅, MCP)은 .NET 10을 사용합니다 — 이는 툴링
> 런타임으로, 개발 대상 앱의 net472/net48 **타깃**과 독립적입니다.

---

## 핵심 규칙

```
RULE 1: WPF/C#/.NET 질문 → 답하기 전 WpfDevPackMcp 토픽 검색 (search_wpf_topics → get_wpf_topic)
RULE 2: 복잡한 작업은 전문 agent에 위임
RULE 3: 커맨드 스킬 활성화 announce
RULE 4: 복수 매치 시 가장 구체적인 토픽/스킬 선택
RULE 5: wpf-architect는 분석 전 Requirements Interview 필수 수행
```

---

## Requirements Interview System

`wpf-architect` 호출 시 AskUserQuestion을 사용해 **적응형 경로 기반
인터뷰**를 수행:

| 경로 | 작업 유형 | 단계 | 초점 |
|------|-----------|------|------|
| **A** | 신규 프로젝트 생성 | 7 | concept → architecture → scale → complexity → libraries → feature areas |
| **B** | 분석/개선 | 5 | analysis goal → analysis mode → scope → output format |
| **C** | 기능 구현 | 5 | feature description → implementation approach → libraries → feature areas |
| **D** | 디버그/수정 | 4 | symptom → problem type → problem area |

**키워드 분석**: 자유 입력 단계(A-2, B-2, C-2, D-2)에서 키워드를 감지해
후속 단계의 기본값을 자동 설정.

상세 인터뷰 사양은 `agents/wpf-architect.md` 참조.

## 트리거 우선순위

1. **명시적 slash command** (`/wpf-net472-airgap-dev-pack:skill-name`) → 커맨드 스킬
2. **WPF 지식** → WpfDevPackMcp로 검색/조회 (`search_wpf_topics` → `get_wpf_topic`); `skills/.claude/CLAUDE.md` 참조
3. **컨텍스트 기반 추론** → 전문 agent에 위임

## 트리거 동작

**트리거 시:**
1. Announce: "wpf-net472-airgap-dev-pack: Activating `skill-name` skill."
2. 기본 MVVM은 의존성 없는 손수 작성 `BindableBase`/`RelayCommand`
   (`rules/mvvm-constraints.md`)입니다. 프로젝트가 이미 프레임워크를 사용 중이고
   사용자가 그것을 유지하는 경우에만 해당 프레임워크 경로를 따릅니다.
3. 콘텐츠 로드:
   - **지식 토픽** → `WpfDevPackMcp get_wpf_topic(id[, variant])`를 호출해 MCP에서 가져옴
   - **커맨드 스킬** → 슬래시 명령으로 호출 (`/wpf-net472-airgap-dev-pack:<skill-name>`)
   - **기본(손수 작성) 스킬** → SKILL.md
   - **Prism (opt-in, 이미 Prism을 쓰는 프로젝트에만)** → PRISM.md 있으면 그 파일, 없으면 SKILL.md
4. 가이드라인 및 프로젝트의 기존 컨벤션에 따라 코드 생성/수정

**Silent 적용** (announce 없음):
- `formatting-wpf-csharp-code` — `.cs` / `.xaml` 편집 시 `CodeFormatter` PostToolUse 훅이 자동 적용.

**복수 키워드:**
1. 가장 구체적인 것 우선 (예: "drawingcontext" > "performance")
2. 관련 skill은 병렬로 참조 가능
3. 충돌 시 사용자에게 확인

---

## 새 Skill 추가 시 — 필수 동반 갱신

**지식 토픽 추가** (WPF 지식, MCP를 통해 제공 — 플러그인 스킬이 아님):
1. `knowledge/<id>/TOPIC.md`(레포 루트, 플러그인 밖)에 토픽 콘텐츠를 작성합니다. **YAML frontmatter 없음.** 첫 번째 `# H1`이 제목이며, H1 바로 아래에 한 줄짜리 `> 요약` 블록인용을 작성합니다 — MCP 카탈로그(`TopicDocReader`)는 첫 번째 H1에서 제목을, 첫 번째 `>` 블록인용에서 요약을 읽습니다.
2. 라우터 수정 불필요, 플러그인 스킬 등록 불필요, 버전 범프 불필요, MCP 재빌드 불필요 — MCP 카탈로그가 새 디렉터리를 자동 발견하고 다음 `git pull` 시 `search_wpf_topics`로 노출됩니다.

**커맨드 스킬 추가** (슬래시 호출 가능한 플러그인 스킬, `skills/` 하위):

`skills/<skill-name>/SKILL.md`로 새 skill을 추가할 때 함께 갱신해야 하는 파일:

1. **`skills/.claude/CLAUDE.md`** — 잔류 커맨드 표에 행 추가.
2. **인접 기존 SKILL.md** — 주제가 겹치는 경우 새 skill로의 cross-link 추가 (`See [...](../skill-name/SKILL.md)`).
3. **Prism 9 분기가 필요한 skill** — `PRISM.md` 컴패니언 파일 작성 (`mvvm-framework.md` 참조).
4. **Foundation + Application 쌍 skill** — 두 skill을 별도로 만들고 상호 참조. Foundation skill은 메커니즘·일반 원칙을 다루고, Application skill은 구체 시나리오에 적용 (예: `preventing-dispatcher-deadlock` + `shutting-down-wpf-gracefully`).
