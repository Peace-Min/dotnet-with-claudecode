[🇺🇸 English](./README.md)

# dotnet-with-claudecode

Claude Code를 활용한 .NET 개발 튜토리얼

## 개요

이 저장소는 Claude Code를 사용한 .NET/WPF 개발을 위한 스킬, 규칙, 에이전트 설정을 제공합니다.

## 콘텐츠

### [wpf-net472-airgap-dev-pack](./wpf-net472-airgap-dev-pack)

WPF 개발을 위한 Claude Code 플러그인.

## 요구사항 (폐쇄망 PC)

- **Claude Code**
- **.NET 10 RTM SDK (10.0.300+)** — C# 훅 실행 + 로컬 MCP 빌드 (preview SDK는 기동 시 크래시하는 MCP 바이너리를 만듭니다)
- **NuGet 접근** — 부트스트랩 시 도구 벤더링용 승인된 내부 피드(또는 nuget.org 1회). 부트스트랩 후 *런타임* 해석은 없음
- **Visual Studio MSBuild** — 대상 net472/net48 솔루션 빌드용

`wpf-net472-airgap-dev-pack`은 **오프라인**입니다: 자체 MCP 서버
(`WpfDevPackMcp`, `HandMirrorMcp`)를 동봉하며 **온라인 MCP가 필요 없습니다** —
`context7`·`microsoft-docs`/Microsoft Learn은 **사용하지 않습니다**. `serena`·
`csharp-lsp`는 *선택적* 로컬 도구입니다.

## 빠른 시작 (폐쇄망)

```bash
git clone <내부미러>/dotnet-with-claudecode.git   # 또는 Peace-Min/dotnet-with-claudecode
cd dotnet-with-claudecode
pwsh ./setup.ps1            # 1회: bin/(MCP 서버 + XamlStyler) 빌드 + 지식 경로 설정
claude --plugin-dir ./wpf-net472-airgap-dev-pack
```

git은 clone 시 스크립트를 자동 실행하지 않으므로 `setup.ps1`이 유일한 부트스트랩
단계입니다. 런타임은 전부 로컬/오프라인 — `dnx`·NuGet 해석·`git pull` 없음.

전체 문서: [`wpf-net472-airgap-dev-pack/README.ko.md`](./wpf-net472-airgap-dev-pack/README.ko.md).

### 대안: 로컬 마켓플레이스로 설치

```bash
/plugin marketplace add Peace-Min/dotnet-with-claudecode
/plugin install wpf-net472-airgap-dev-pack@dotnet-net472-airgap-plugins
```

(폐쇄망에서 자동 업데이트는 비활성 유지 — 외부에서 빌드한 번들을 전송해 업데이트)

## Git Hooks 설정

이 저장소에는 `wpf-net472-airgap-dev-pack`의 자동 버전 업데이트를 위한 공유 git hooks가 포함되어 있습니다.

### Git Hooks 설치

저장소 클론 후 다음 중 하나를 실행하세요:

```bash
# 방법 1: 직접 설정
git config core.hooksPath .githooks

# 방법 2: 설치 스크립트 사용 (Windows PowerShell)
.\.githooks\install.ps1

# 방법 2: 설치 스크립트 사용 (Linux/Mac)
./.githooks/install.sh
```

### Hook 동작

- **pre-push**: `wpf-net472-airgap-dev-pack/` 디렉토리 변경사항 푸시 시 자동으로 패치 버전 업데이트 (`plugin.json`과 `README.md` 제외)

## 기여

기여를 환영합니다! [CONTRIBUTING.md](.github/CONTRIBUTING.md)를 참조하세요.

## 라이선스

이 프로젝트는 [MIT 라이선스](LICENSE) 하에 배포됩니다.

## 저자

- **christian289** - [GitHub](https://github.com/christian289)
