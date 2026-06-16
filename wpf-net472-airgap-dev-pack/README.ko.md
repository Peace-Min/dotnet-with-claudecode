[🇺🇸 English](./README.md)

<div align="center">

# 🎨 wpf-net472-airgap-dev-pack

### Claude Code를 위한 최고의 WPF 개발 도구 키트

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/Peace-Min/dotnet-with-claudecode)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![.NET](https://img.shields.io/badge/.NET_SDK-10.0.300+-purple.svg)](https://dotnet.microsoft.com/)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin-orange.svg)](https://claude.ai)

**14개 스킬** · **10개 전문 에이전트** · **2개 MCP 서버**

[설치](#-설치) · [빠른 시작](#-빠른-시작) · [기능](#-기능) · [문서](#-문서)

---

</div>

## ✨ 하이라이트

> **MVVM**: 의존성 없는 **직접 구현(hand-rolled) MVVM** — `BindableBase`
> (`INotifyPropertyChanged`) + `RelayCommand` / `RelayCommand<T>` (`ICommand`)를
> **net472/net48 (C# 7.3)** 기준으로 컴파일합니다. **CommunityToolkit 미사용**,
> 프레임워크 자동 감지 없음. 프로젝트에 베이스 클래스가 없으면 생성기가 만들어 주고,
> 자체 베이스 클래스가 있으면 그것을 재사용합니다. 와이어링은 실용적입니다 — 코드비하인드
> `DataContext`, implicit `DataTemplate`, DI 중 프로젝트가 이미 쓰는 방식에 맞춥니다.
> Prism은 이미 Prism을 쓰는 프로젝트(net472에서 7.2/8.1)를 위한 **opt-in** 대안으로만
> 남습니다. [`.claude/rules/mvvm-constraints.md`](./.claude/rules/mvvm-constraints.md) 및
> [`.claude/rules/prohibitions.md`](./.claude/rules/prohibitions.md)를 참고하세요.

<table>
<tr>
<td width="50%">

### 🤖 AI 기반 개발
- 다양한 WPF 작업을 위한 **10개 전문 에이전트**
- **세션 모델 그대로 사용** — 에이전트가 현재 모델을 상속
- **MCP 기반 지식 제공** — WpfDevPackMcp가 답변 전 검색(search-before-answer)
- **Prism** 컴패니언 파일 (opt-in, 기존 Prism 프로젝트용)

</td>
<td width="50%">

### 🛠️ 완벽한 도구 키트
- **14개 커맨드 스킬** + MCP로 온디맨드 제공되는 WPF 지식
- **모범 사례** 내장

</td>
</tr>
<tr>
<td width="50%">

### 📚 로컬 지식 (오프라인)
- **WpfDevPackMcp**가 로컬 클론에서 WPF 토픽을 제공 (네트워크 없음)
- **HandMirrorMcp**가 로컬 어셈블리/NuGet 기준으로 API를 검증
- **Serena**로 시맨틱 코드 분석 (선택, 로컬)

</td>
<td width="50%">

### ⚡ 고성능
- **DrawingContext** 렌더링 패턴
- **가상화** 전략
- **메모리 최적화** 기법

</td>
</tr>
</table>

---

## 📦 설치

### 빠른 시작 (폐쇄망 — 권장)

폐쇄망 PC에서 (.NET 10 RTM SDK, Claude Code, NuGet 접근, VS MSBuild가 갖춰져 있어야 합니다):

```bash
git clone <사내-내부-원격>/dotnet-with-claudecode.git
cd dotnet-with-claudecode
pwsh ./setup.ps1          # 최초 1회: bin/ 빌드(MCP 서버 + XamlStyler) + 지식 경로 설정
claude --plugin-dir ./wpf-net472-airgap-dev-pack
```

`setup.ps1`은 단일 부트스트랩 단계입니다 (git은 clone 시 스크립트를 자동 실행할 수 없습니다). 새 커밋을 pull한 뒤에만 다시 실행하면 됩니다. 런타임에는 모든 것이 로컬/오프라인입니다 — `dnx`도, NuGet 해석도, `git pull`도 없습니다. `bin/`이 아직 빌드되지 않았다면 SessionStart 훅이 알려 줍니다.

> `pwsh`가 없나요? Windows PowerShell 5.1에서도 동작합니다: `powershell -ExecutionPolicy Bypass -File ./setup.ps1`.

### 마켓플레이스에서 설치

```bash
# 1단계: 마켓플레이스 추가 (최초 1회)
/plugin marketplace add Peace-Min/dotnet-with-claudecode

# 2단계: 플러그인 설치
/plugin install wpf-net472-airgap-dev-pack@dotnet-net472-airgap-plugins
```

### 로컬 설치

```bash
claude --plugin-dir ./wpf-net472-airgap-dev-pack
```

### 업데이트 (폐쇄망)

자동 업데이트는 **꺼져 있어야 하며 계속 꺼진 상태를 유지해야 합니다**. 망 외부에서 새로
빌드한 번들을 전달받아서만 업데이트하세요 — 플러그인이나 마켓플레이스가 스스로 pull하게
두지 마세요.

```bash
# 승인된 새 번들을 적용한 뒤, (선택적으로) 로컬에서 재설치:
claude --plugin-dir ./wpf-net472-airgap-dev-pack
```

> **참고:** 서드파티 마켓플레이스는 기본적으로 자동 업데이트가 비활성화되어 있습니다. 비활성화 상태를 유지하세요.

### 요구사항

| 요구사항 | 버전 | 비고 |
|----------|------|------|
| .NET SDK | **10.0.300+ (RTM)** | C# 훅을 실행하고 로컬 MCP 서버를 빌드합니다. *프리뷰* .NET 10 SDK는 시작 시 크래시하는 MCP 바이너리를 생성하므로 — RTM SDK를 사용하세요. |
| Claude Code | 최신 | - |
| uv | 최신 | **선택** — Serena를 로컬에서 실행하기로 선택한 경우에만 |

> **대상 프레임워크 vs 지원 SDK**: .NET SDK 10.0.300+는 **플러그인을 실행할 뿐입니다** (훅 + 로컬 MCP 빌드).
> 이 포크가 생성·유지보수하는 WPF 코드는 **.NET Framework 4.7.2–4.8 (`net472`/`net48`)**을 대상으로 하며, 지원 SDK와는 독립적입니다.

### MCP 서버 (로컬 / 오프라인)

이 포크는 **MCP 서버를 번들로 제공하며 온라인 MCP를 전혀 요구하지 않습니다.** 승인된
피드에 접근 가능한 머신에서 번들 준비 시 한 번만 빌드하면, 이후에는 시작 시 `dnx`/NuGet
해석 없이 `bin/`에서 실행됩니다:

```powershell
pwsh ./tools/build-local-bin.ps1
# bin/WpfDevPackMcp (../mcp에서)를 빌드하고 HandMirrorMcp + XamlStyler.Console을 vendoring
```

| MCP 서버 | 번들 | 용도 |
|---|---|---|
| **WpfDevPackMcp** | ✅ `bin/WpfDevPackMcp` | 로컬 WPF 지식 토픽 (오프라인; 로컬 클론을 읽으며 pull하지 않음) |
| **HandMirrorMcp** | ✅ `bin/HandMirrorMcp` | 로컬 어셈블리 & NuGet 기준으로 네임스페이스/시그니처 검증 |

**제거된 온라인 종속성:** `context7`와 `microsoft-docs` / Microsoft Learn은 **사용하지
않으며 필요하지도 않습니다**. 플러그인은 이들을 확인하지 않고, 없어도 품질이 저하되지
않습니다.

**선택적 로컬 도구** (플러그인은 이들 없이도 완전히 동작합니다 — 승인된 오프라인 패키지에서만
설치하고, 런타임에 가져오지 마세요):

| 도구 | 용도 | 없을 경우 |
|---|---|---|
| [**serena**](https://github.com/oraios/serena) | 시맨틱 코드 분석, 심볼 네비게이션 | 에이전트가 Read/Grep/Glob로 폴백합니다. 사용한다면 `uv`로 직접 설치하세요 (Claude Code 플러그인 경로가 아님 — [Attention 안내](https://oraios.github.io/serena/02-usage/030_clients.html#claude-code) 참고). |
| [**csharp-lsp**](https://github.com/razzmatazz/csharp-language-server) | C# LSP (정의, 참조, 진단) | `wpf-code-reviewer`가 텍스트 분석으로 폴백합니다. |

---

## 🚀 빠른 시작

### 새 WPF 프로젝트 생성

```bash
# net472/net48 + 직접 구현(hand-rolled) MVVM (기본)
/wpf-net472-airgap-dev-pack:make-wpf-project MyApp

# Prism (opt-in; 기존 Prism 프로젝트)
/wpf-net472-airgap-dev-pack:make-wpf-project MyApp --prism
```

### 컴포넌트 생성

```bash
# CustomControl
/wpf-net472-airgap-dev-pack:make-wpf-custom-control MyButton Button

# UserControl
/wpf-net472-airgap-dev-pack:make-wpf-usercontrol SearchBox

# Converter
/wpf-net472-airgap-dev-pack:make-wpf-converter BoolToVisibility

# Behavior
/wpf-net472-airgap-dev-pack:make-wpf-behavior SelectAllOnFocus TextBox
```

### 도움 요청

```
"고성능 차트 컨트롤은 어떻게 만드나요?"
"이 ViewModel을 MVVM 관점에서 검토해주세요"
"대용량 데이터셋을 위해 이 렌더링 코드를 최적화해주세요"
```

---

## 🎯 요구사항 인터뷰 시스템

`wpf-architect`를 호출하면 **적응형 경로 기반 인터뷰**가 정확한 요구사항을 파악합니다:

### 작동 방식

```
Step 1: 작업 유형 선택
   ├─→ 경로 A: 새 프로젝트 생성 (7단계)
   ├─→ 경로 B: 기존 분석/개선 (5단계)
   ├─→ 경로 C: 기능 구현 (5단계)
   └─→ 경로 D: 디버깅/수정 (4단계)
```

각 경로는 자유 입력 단계에서 **키워드 분석**을 통해 후속 단계의 기본값을 자동 설정합니다.

### 인터뷰 경로

| 경로 | 작업 유형 | 단계 | 초점 |
|------|-----------|:----:|------|
| **A** | 새 프로젝트 생성 | 7 | 컨셉 → 아키텍처 → 규모 → 복잡도 → 라이브러리 → 기능 영역 |
| **B** | 분석/개선 | 5 | 분석 목표 → 분석 모드 → 범위 → 출력 형식 |
| **C** | 기능 구현 | 5 | 기능 설명 → 구현 방식 → 라이브러리 → 기능 영역 |
| **D** | 디버깅/수정 | 4 | 문제 증상 → 문제 유형 → 문제 영역 |

### 예시 플로우 (경로 A)

```
User: "WPF로 차트 앱 만들고 싶어요"

wpf-architect: [A-1] 어떤 앱인가요? 컨셉을 설명해주세요.
   → User: "실시간 주식 차트 대시보드"
   (키워드 감지: "차트", "실시간" → LiveCharts2, 성능 기본값 자동 설정)

wpf-architect: [A-2] 아키텍처 패턴은?
   → User 선택: "직접 구현(hand-rolled) MVVM"

wpf-architect: [A-3] 프로젝트 규모는?
   → User 선택: "중간 (5-15개 View)"

wpf-architect: [A-5] 서드파티 라이브러리?
   → 자동 추천: LiveCharts2 ✓, WPF-UI (선택)

결과: LiveCharts2 + DrawingContext 스킬 + wpf-performance-optimizer 활성화
```

---

## 🧠 지식 제공 방식

wpf-net472-airgap-dev-pack은 키워드 감지 훅을 **사용하지 않습니다**. WPF 지식은 **WpfDevPackMcp** MCP 서버가 온디맨드로 제공합니다 — 서버 자체의 instructions가 에이전트에게 WPF/C#/.NET 질문에 **답하기 전 토픽 카탈로그를 검색**하도록 지시합니다.

### 작동 방식

1. **질문**: WPF/C#/.NET 질문을 하거나 커맨드 스킬/에이전트를 호출합니다.
2. **검색**: 에이전트가 `WpfDevPackMcp search_wpf_topics`로 카탈로그를 검색하고 `get_wpf_topic`으로 적합한 토픽을 로드합니다.
3. **에이전트**: 복잡한 다단계 작업은 전문 에이전트가 처리합니다.

> ~50개 지식 토픽은 레포의 `knowledge/<id>/TOPIC.md`에 순수 마크다운으로 존재하며 실시간으로 조회됩니다 — 편집에 플러그인 재빌드나 버전 범프가 필요 없습니다. [`/wpf-net472-airgap-dev-pack:set-repo-path`](#-설정)를 한 번 실행해 서버가 읽을 로컬 클론 경로를 지정하세요.

### 토픽 예시 (MCP로 제공)

| 질문 주제 | 토픽 |
|-----------|------|
| CustomControl 작성 | `authoring-wpf-controls` |
| 직접 구현(hand-rolled) MVVM | `implementing-handrolled-mvvm` |
| DrawingContext 렌더링 | `rendering-with-drawingcontext` |
| 고성능 렌더링 | `rendering-wpf-high-performance` |

복잡한 작업에는 전문 에이전트가 추천됩니다 (예: 렌더링은 `wpf-performance-optimizer`, 아키텍처 검토는 `wpf-architect`).

### 커맨드 스킬 vs 지식

- **커맨드 스킬** (`/wpf-net472-airgap-dev-pack:<name>`) — 슬래시로 호출하는 생성기/플러그인 운영 도구 (14개 번들; 아래 **스킬 & 지식** 참조).
- **지식 토픽** — WpfDevPackMcp가 제공하는 참조 콘텐츠로, 세션 스킬 목록에 올라가지 않습니다 (세션 컨텍스트 비용 없음).

---

## 🎯 기능

### 🤖 전문 에이전트

> 모든 에이전트는 현재 세션 모델을 그대로 사용합니다. 모델 전환은 `/model` 명령으로 수행하세요 (예: Opus 1M ↔ Sonnet ↔ Haiku).

| 에이전트 | 전문 분야 |
|----------|-----------|
| 🏗️ **wpf-architect** | 전략적 아키텍처 및 설계 결정 |
| 🎨 **wpf-control-designer** | CustomControl 구현 |
| 📐 **wpf-xaml-designer** | XAML 스타일 및 템플릿 |
| 🔄 **wpf-mvvm-expert** | MVVM 패턴 (직접 구현, hand-rolled) |
| 🔗 **wpf-data-binding-expert** | 복잡한 바인딩 및 유효성 검사 |
| ⚡ **wpf-performance-optimizer** | 렌더링 및 성능 |
| 🔍 **wpf-code-reviewer** | 코드 품질 분석 |
| 🔎 **wpf-code-auditor** | 전체 코드베이스 패턴 & 일관성 감사 |
| 📝 **code-formatter** | C# 서식 및 스타일 |
| 🔧 **serena-initializer** | 프로젝트 설정 |

### 🔌 MCP 서버

| 플러그인 | MCP 서버 | 용도 |
|---------|----------|------|
| **HandMirrorMcp** | HandMirrorMcp | .NET 어셈블리/NuGet 검사 (번들, 로컬) |
| **WpfDevPackMcp** | WpfDevPackMcp | 로컬 저장소 클론에서 제공하는 WPF 지식 토픽 (번들, 로컬) |
| _(선택, `uv`)_ | **serena** | 시맨틱 코드 분석 (선택, 로컬) |
| _(선택)_ | **csharp-lsp** | C# LSP 코드 인텔리전스 (선택, 로컬) |

> 번들된 두 MCP 서버는 모두 네트워크 없이 `bin/`에서 실행됩니다. `context7`와 `microsoft-docs` / Microsoft Learn은 **사용하지 않습니다**. Serena / csharp-lsp는 선택 사항입니다 — 위의 [MCP 서버 (로컬 / 오프라인)](#mcp-서버-로컬--오프라인) 섹션을 참고하세요.

### 📚 스킬 & 지식

> **v1.7.0부터**, ~50개의 WPF *지식* 토픽(MVVM, 렌더링, 스레딩, 스타일링,
> 서드파티 라이브러리, .NET 공통, Prism 9 컴패니언, 테스트 등)은 **더 이상
> 플러그인 스킬로 번들되지 않습니다**. 이들은 **WpfDevPackMcp** MCP 서버가
> `get_wpf_topic` / `search_wpf_topics`로 온디맨드 제공하며, 서버 자체의
> instructions가 답변 전 검색하도록 에이전트에게 지시합니다. 덕분에 세션
> 스킬 목록에서 빠져(세션 컨텍스트 비용 없음) 있으면서도 순수 마크다운으로
> 편집 가능합니다.
> [`mcp/README.md`](../mcp/README.md)와 [`/wpf-net472-airgap-dev-pack:set-repo-path`](#-설정)를
> 참고하세요.

플러그인은 **14개 커맨드 스킬**(슬래시 호출)을 번들합니다:

<details>
<summary><b>🏗️ 스캐폴딩 (7개 스킬)</b></summary>

| 스킬 | 설명 |
|------|------|
| `make-wpf-project` | MVVM/DI 포함 WPF 프로젝트 스캐폴딩 |
| `make-wpf-custom-control` | CustomControl 생성 |
| `make-wpf-usercontrol` | UserControl 생성 |
| `make-wpf-converter` | IValueConverter 생성 |
| `make-wpf-behavior` | Behavior<T> 생성 |
| `make-wpf-viewmodel` | ViewModel + View + DI + DataTemplate 매핑 생성 |
| `make-wpf-service` | 서비스 인터페이스 + 구현 + DI 등록 |

</details>

<details>
<summary><b>🎨 코드 품질 (1개 스킬)</b></summary>

| 스킬 | 설명 |
|------|------|
| `formatting-wpf-csharp-code` | C# / XAML 서식 & 스타일 (편집 시 CodeFormatter 훅이 자동 적용) |

</details>

<details>
<summary><b>🔧 플러그인 운영 (6개 스킬)</b></summary>

| 스킬 | 설명 |
|------|------|
| `collecting-wpf-net472-airgap-dev-pack-feedback` | 익명화된 피드백 문서 수집 (추후 반영용) |
| `configuring-wpf-net472-airgap-dev-pack-language` | 프로젝트별 응답 언어 설정 (`.claude/wpf-net472-airgap-dev-pack.local.md`) |
| `set-repo-path` | WpfDevPackMcp가 지식을 읽어올 로컬 저장소 클론 경로 설정 |
| `set-repo-branch` | WpfDevPackMcp가 추적할 git 브랜치 설정 (`config.json`) |
| `set-repo-managed` | 서버 관리 플래그(`state.json`) 설정 — 파괴적/비파괴적 refresh 제어 |
| `show-wpf-net472-airgap-dev-pack-config` | WpfDevPackMcp `config.json` / `state.json` 경로·값 표시 |

</details>

---

## 📁 플러그인 구조

```
wpf-net472-airgap-dev-pack/
├── 📁 .claude-plugin/
│   └── plugin.json           # 플러그인 매니페스트
├── 📁 agents/                 # 10개 전문 에이전트
│   ├── wpf-architect.md
│   ├── wpf-code-auditor.md
│   ├── wpf-code-reviewer.md
│   ├── wpf-control-designer.md
│   ├── wpf-xaml-designer.md
│   ├── wpf-mvvm-expert.md
│   ├── wpf-data-binding-expert.md
│   ├── wpf-performance-optimizer.md
│   ├── code-formatter.md
│   └── serena-initializer.md
├── 📁 skills/                 # 14개 커맨드 스킬
├── 📁 hooks/                  # 이벤트 훅
├── 📄 .mcp.json               # MCP 설정 (HandMirrorMcp + WpfDevPackMcp)
├── 📄 README.md
└── 📄 LICENSE
```

---

## 🔧 설정

### Serena MCP 설정

> ⚠️ **필수**: Serena를 사용하려면 [uv](https://docs.astral.sh/uv/)를 설치하세요.

```bash
# Serena 로컬 테스트
uvx --from git+https://github.com/oraios/serena serena start-mcp-server
```

### C# LSP (IntelliSense용 필수)

```bash
claude /install-plugin csharp-lsp
```

---

## 📖 문서

### 공식 참고 자료

- 📘 [WPF Samples (Microsoft)](https://github.com/microsoft/WPF-Samples)
- 📗 [WPF Graphics & Multimedia](https://learn.microsoft.com/dotnet/desktop/wpf/graphics-multimedia/)
- 📙 [Claude Code Plugin Spec](https://code.claude.com/docs/en/plugins-reference)

### 아키텍처 참고

- [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) - 에이전트 기반 오케스트레이션 패턴

---

## 🤝 기여

기여를 환영합니다! Pull Request를 자유롭게 제출해주세요.

---

## 📄 라이선스

MIT 라이선스 - 자세한 내용은 [LICENSE](LICENSE)를 참조하세요.

---

<div align="center">

**Made with ❤️ by vincent lee**

[⬆ 맨 위로](#-wpf-net472-airgap-dev-pack)

</div>
