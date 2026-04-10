# 프로젝트 컨텍스트

Planner, Generator, Evaluator가 **반드시 먼저 읽어야 하는** 프로젝트 고정 요구사항.
이 파일에 적힌 내용은 사용자 프롬프트보다 우선한다.

---

## 대상 프로젝트

- **앱 이름**: ReactionTimeChecker
- **번들 ID**: com.nahun.ReactionTimeChecker
- **앱 콘셉트**: 반응속도 테스트 앱. 핵심 키워드는 **"재미"**. 사용자가 자신의 반응속도를 측정하고, 등급과 캐릭터를 부여받아 친구에게 공유하는 즐거운 경험을 제공한다.
- **최소 타겟 iOS**: 17.0
- **Swift 버전**: Swift 6 (엄격 동시성 필수)
- **UI 프레임워크**: SwiftUI 100% (UIKit 사용 금지)

---

## 디자인 시스템 (필수)

**`TopDesignSystem` SPM 패키지를 사용한다.**
- URL: `https://github.com/KimNahun/TopDesignSystem.git`
- 색상, 타이포그래피, 컴포넌트를 절대 자체 구현하지 마라.

```swift
import TopDesignSystem
```

### 테마 설정

앱 루트에서 `.airbnb` 테마를 적용한다 (WarmVibrant + SystemScale, 소비자/소셜 앱에 적합).

```swift
ContentView()
    .designTheme(.airbnb)
```

### 색상 사용 방법

```swift
// View에서 palette 접근
@Environment(\.designPalette) var palette

// 사용 예시
Text("hello").foregroundStyle(palette.textPrimary)
Rectangle().fill(palette.success)   // 초록 (#00C805) — GO 화면에 사용
Rectangle().fill(palette.error)     // 빨강 (#C13515) — 대기/실격 화면에 사용
Rectangle().fill(palette.background) // 배경
```

### 테스트 화면 색상 매핑 (고정)

| 상태 | 색상 토큰 | 용도 |
|------|----------|------|
| waiting (대기) | `palette.error` | 긴장감 (빨강 계열) |
| green (GO!) | `palette.success` | 반응 신호 (밝은 초록) |
| cheated (실격) | `palette.error` | 실격 처리 (빨강 — 잘못됨을 명확히) |
| countdown | `palette.surface` | 카운트다운 준비 |
| home/result | `palette.background` | 기본 배경 |

### 사용 가능한 주요 컴포넌트

```swift
// 버튼
PillButton(title: "시작", action: { })          // 52pt 캡슐형
RoundedActionButton(title: "다시 하기", action: { })  // 48pt 둥근 버튼
OutlineButton(title: "공유", action: { })       // 테두리 버튼

// 카드
SurfaceCard(elevation: .raised) { content }
GlassCard { content }

// 피드백
view.bottomToast(isPresented: $show, message: "...", style: .error)

// 타이포그래피
.font(.ssLargeTitle)    // 42pt Bold — ms 숫자 표시용
.font(.ssTitle1)        // 36pt Bold
.font(.ssTitle2)        // 20pt Semibold — 섹션 제목
.font(.ssBody)          // 16pt Regular — 본문
.font(.ssFootnote)      // 14pt Regular — 보조 텍스트
.font(.ssCaption)       // 12pt Regular — 캡션

// 스페이싱
DesignSpacing.xs    // 8pt
DesignSpacing.sm    // 12pt
DesignSpacing.md    // 16pt
DesignSpacing.lg    // 24pt
DesignSpacing.xl    // 32pt

// 코너 반경
DesignCornerRadius.md   // 12pt
DesignCornerRadius.lg   // 16pt
DesignCornerRadius.pill // 9999pt

// 애니메이션
view.gentleSpring(value: someState)
Button { }.buttonStyle(.pressScale)
```

**하드코딩 절대 금지**: `Color(red:green:blue:)`, `Color("name")`, `.font(.system(size:))` 직접 사용 금지.

---

## 아키텍처 요구사항

### 고정 요구사항

- MVVM: View → ViewModel → Service 단방향 의존
- 모든 ViewModel: `@MainActor` + `@Observable`
- 가변 상태를 가진 Service: `actor`
- **순수 계산만 하는 Service (가변 상태 없음): `struct` 허용** — actor 강제 금지
- 모든 Model: `struct` + `Sendable`
- HomeView는 ViewModel 없음 — `@State var selectedRounds: Int = 5`로 충분

### 앱 전체 흐름 관리 (AppPhase)

`ReactionTimeCheckerApp.swift`가 `AppPhase`를 `@State`로 소유하고, 화면 전체를 switch로 교체한다.
NavigationStack, sheet, fullScreenCover 사용 금지 — 모든 화면 전환은 AppPhase 교체로 처리한다.

```swift
// Models/AppPhase.swift
enum AppPhase: Sendable {
    case home
    case testing(rounds: Int)
    case result(session: TestSession)
}

// ReactionTimeCheckerApp.swift
@main struct ReactionTimeCheckerApp: App {
    @State private var phase: AppPhase = .home

    var body: some Scene {
        WindowGroup {
            switch phase {
            case .home:
                HomeView(phase: $phase)
                    .designTheme(.airbnb)
            case .testing(let rounds):
                TestView(rounds: rounds, phase: $phase)
                    .designTheme(.airbnb)
            case .result(let session):
                ResultView(session: session, phase: $phase)
                    .designTheme(.airbnb)
            }
        }
    }
}
```

---

## 핵심 기능 요구사항

### 기능 1: 반응속도 테스트

- **홈**: 라운드 수(5회 / 10회) 선택 → 시작 버튼 탭 → `.testing(rounds:)` phase로 전환
- **카운트다운**: "3 → 2 → 1 → GO!" 카운트다운 (각 1초). 이 상태에서 탭은 무시.
- **대기(waiting)**: `palette.error` 배경. "준비..." 텍스트. 1.0~5.0초 무작위 딜레이.
- **GO(green)**: `palette.success` 배경. 즉시 탭!
- **기록(recorded)**: 탭 시점 ms 기록. 다음 라운드 또는 완료.
- **완료**: N회 유효 기록 완료 → `.result(session:)` phase로 전환.

### 기능 2: 부정 탭 감지 (실격 처리)

- `waiting` 상태에서 탭 → 즉시 실격 처리
- `countdown` 상태에서 탭 → **무시** (카운트다운 준비 중 탭은 자연스러운 행동이므로 실격 처리하지 않음)
- 실격된 라운드는 **유효 라운드로 카운트하지 않음** (재시도 필요)
- 재시도 시 cheated attempt는 `ReactionAttempt(isCheated: true)`로 기록은 하되, N회 카운트에서 제외
- UI: `palette.error` 배경 + 실격 메시지 + **"다시 하기" 버튼**
- "다시 하기" 탭 → 같은 라운드 번호에서 카운트다운부터 재시작
- **실격 횟수 제한 없음** — 유효 N회를 채울 때까지 계속 진행
- 결과 화면에서 총 실격 횟수를 별도 표기

### 기능 3: 결과 화면

측정 완료 후 결과 화면에 표시:
- **내 평균 반응속도** (ms, 유효 시도만)
- **최고 기록** (가장 빠른 유효 시도)
- **최악 기록** (가장 느린 유효 시도)
- **총 실격 횟수** (cheated count)
- **다른 사람들의 평균** (하드코딩):
  - 일반인 평균: 250ms
  - 게이머 평균: 200ms
  - 운동선수 평균: 180ms
- **상위 몇 %인지** (내 평균 기준 백분위)

### 기능 4: 등급 시스템 (재미 핵심!)

상위 % 기준으로 10%씩 분기:

| 상위 % | 등급명 | 이모지 | 한 줄 설명 |
|--------|--------|--------|------------|
| 1~10% | 반응속도의 신 | ⚡️ | "당신은 번개보다 빠릅니다" |
| 11~20% | 닌자 | 🥷 | "닌자도 당신 앞엔 느림보" |
| 21~30% | 사이보그 | 🤖 | "인간의 한계를 넘었군요" |
| 31~40% | 치타 | 🐆 | "지구상 가장 빠른 동물급" |
| 41~50% | 토끼 | 🐰 | "평균 이상의 빠른 손" |
| 51~60% | 일반인 | 🧑 | "평범하지만 나쁘지 않아요" |
| 61~70% | 나무늘보 주니어 | 🦥 | "조금 더 집중해봐요..." |
| 71~80% | 거북이 | 🐢 | "느려도 괜찮아요, 꾸준히!" |
| 81~90% | 달팽이 | 🐌 | "달팽이도 당신보다 빠릅니다" |
| 91~100% | 화석 | 🪨 | "혹시 자고 계셨나요...?" |

### 기능 5: 공유 버튼 (MVP — 액션 없음)

- 결과 화면에 `OutlineButton(title: "결과 공유하기")` 표시
- **현재 버전에서 버튼 액션은 비워둔다 (`action: { }`)** — 추후 구현 예정
- 버튼 아래 `Text("공유 기능은 곧 추가됩니다").font(.ssCaption)` 표시

---

## 반응 시간 측정 정밀도

- 탭 시점에 즉시 `CACurrentMediaTime()`으로 시간을 기록한다.
- `actor` 메서드를 `await`하는 도중 발생하는 스케줄링 지연을 방지하기 위해, **탭 감지는 View의 `.onTapGesture`에서 즉시** `let tapTime = CACurrentMediaTime()`을 찍고, 이 값을 ViewModel에 전달한다.
- ReactionTestService는 `startTime: Double`을 `CACurrentMediaTime()`으로 기록하며, ViewModel이 `tapTime`을 전달하면 차이를 ms로 계산한다.

```swift
// View
.onTapGesture {
    let tapTime = CACurrentMediaTime()
    Task { await viewModel.handleTap(at: tapTime) }
}

// TestViewModel
func handleTap(at tapTime: Double) async {
    guard state == .green else {
        // 부정 탭 처리
        return
    }
    let ms = await testService.calculateMs(tapTime: tapTime)
    // ...
}

// ReactionTestService (actor)
private var startTime: Double = 0
func markGreen() async {
    startTime = CACurrentMediaTime()
}
func calculateMs(tapTime: Double) async -> Int {
    return Int((tapTime - startTime) * 1000)
}
```

---

## 백분위 계산 기준 데이터 (StatisticsService)

`StatisticsService`는 가변 상태가 없으므로 `struct`로 구현한다.

```swift
struct StatisticsService: StatisticsServiceProtocol {
    // 선형 보간 기반 연속 백분위 계산
    // ms가 낮을수록 상위 % (상위 1% = 최고)
    private let anchors: [(ms: Int, percentile: Double)] = [
        (100, 0.5),
        (150, 1.0),
        (175, 5.0),
        (190, 10.0),
        (205, 20.0),
        (220, 30.0),
        (235, 40.0),
        (250, 50.0),
        (265, 60.0),
        (280, 70.0),
        (300, 80.0),
        (330, 90.0),
        (400, 99.0),
    ]

    func calculatePercentile(averageMs: Int) -> Int {
        // anchors 사이를 선형 보간해서 연속적인 값 반환
        // 예: 197ms → 15% (190~205 사이 보간)
    }

    func determineGrade(percentile: Int) -> Grade {
        // percentile 기준 등급 반환
    }
}
```

---

## 파일 구조

```
output/
├── App/
│   └── ReactionTimeCheckerApp.swift      # @main, AppPhase 소유
├── Views/
│   ├── Home/
│   │   └── HomeView.swift               # @State selectedRounds만 사용 (ViewModel 없음)
│   ├── Test/
│   │   ├── TestView.swift               # 상태 UI + .onChange 햅틱
│   │   └── TestComponents.swift         # ShakeEffect, CountdownView 등
│   ├── Result/
│   │   ├── ResultView.swift             # 결과 + 등급 + 공유 버튼(placeholder)
│   │   └── GradeCardView.swift
│   └── Components/
│       └── RoundSelectorView.swift
├── ViewModels/
│   ├── Test/
│   │   └── TestViewModel.swift
│   └── Result/
│       └── ResultViewModel.swift
├── Models/
│   ├── AppPhase.swift                   # AppPhase enum
│   ├── TestSession.swift
│   ├── ReactionAttempt.swift
│   ├── Grade.swift
│   └── ReactionError.swift
└── Services/
    ├── ReactionTestService.swift        # actor (startTime 가변 상태 있음)
    └── StatisticsService.swift          # struct (순수 계산, 가변 상태 없음)
```

---

## Xcode 프로젝트 통합

이 프로젝트는 `PBXFileSystemSynchronizedRootGroup`을 사용하므로, **`ReactionTimeChecker/` 폴더에 파일을 복사하면 Xcode가 자동으로 빌드 대상에 포함한다.**

> **전제**: Xcode에서 `ReactionTimeChecker.xcodeproj`를 먼저 생성하고, TopDesignSystem SPM 패키지를 추가한 상태여야 한다.

### Generator 완료 후 실행할 통합 명령어

```bash
PROJECT_ROOT="/Users/haesuyoun/Desktop/NahunPersonalFolder/ReactionTimeChecker"
OUTPUT="$PROJECT_ROOT/harness/output"
TARGET="$PROJECT_ROOT/ReactionTimeChecker"

mkdir -p "$TARGET/App" "$TARGET/Models" "$TARGET/Services" \
         "$TARGET/ViewModels/Test" "$TARGET/ViewModels/Result" \
         "$TARGET/Views/Home" "$TARGET/Views/Test" "$TARGET/Views/Result" "$TARGET/Views/Components"

[ -d "$OUTPUT/App" ] && cp -fR "$OUTPUT/App/"* "$TARGET/App/"
cp -fR "$OUTPUT/Models/"* "$TARGET/Models/"
cp -fR "$OUTPUT/Services/"* "$TARGET/Services/"
cp -fR "$OUTPUT/ViewModels/"* "$TARGET/ViewModels/"
cp -fR "$OUTPUT/Views/"* "$TARGET/Views/"

echo "Xcode 통합 완료."
```

### 통합 후 수동 작업 (개발자가 Xcode에서 직접)

```
1. TopDesignSystem SPM 추가:
   Xcode → File → Add Package Dependencies → https://github.com/KimNahun/TopDesignSystem.git

2. URL Scheme 등록 (공유 기능 구현 시점에 처리):
   Target → Info → URL Types → "reactiontime" 추가
```
