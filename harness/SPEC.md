# ReactionTimeChecker

## 개요

ReactionTimeChecker는 iOS 사용자가 자신의 반응속도를 밀리초 단위로 측정하고, 전 세계 사용자 분포 기준의 백분위에 따라 10가지 재미있는 캐릭터 등급(번개신, 닌자, 치타, 나무늘보, 화석 등)을 부여받는 소셜 캐주얼 앱이다. 긴장감 넘치는 "빨강 대기 → 초록 GO" 의 원초적 경험과, 결과 화면에서 이모지·애니메이션·햅틱이 순차 공개되는 드라마틱한 연출이 핵심이다. 등급과 한 줄 설명("달팽이도 당신보다 빠릅니다")은 친구들에게 자랑하거나 장난을 치고 싶게 만드는 바이럴 포인트다.

## 타겟 플랫폼

- iOS 17.0 이상
- Swift 버전: Swift 6 (엄격한 동시성)
- UI 프레임워크: SwiftUI 100% (UIKit 금지)
- 디자인 시스템: TopDesignSystem SPM (`.airbnb` 테마 — WarmVibrant + SystemScale)
- 최소 디바이스: iPhone (세로 고정)
- 필요 권한: 없음 (공유 기능은 placeholder이므로 URL Scheme만 추후 등록)
- 네트워크: 없음 (모든 통계는 하드코딩된 앵커 데이터로 로컬 계산)

---

## 아키텍처

### 레이어 구조 (고정)

```
output/
├── App/
│   └── ReactionTimeCheckerApp.swift      # @main, AppPhase 소유, .designTheme(.airbnb)
├── Views/
│   ├── Home/
│   │   └── HomeView.swift               # @State selectedRounds만 사용 (ViewModel 없음)
│   ├── Test/
│   │   ├── TestView.swift               # 상태 UI + .onChange 햅틱
│   │   └── TestComponents.swift         # ShakeEffect, CountdownView, RoundProgressView 등
│   ├── Result/
│   │   ├── ResultView.swift             # 결과 + 등급 + 공유 버튼 placeholder
│   │   └── GradeCardView.swift          # 등급 카드 (이모지·이름·설명 순차 공개)
│   └── Components/
│       └── RoundSelectorView.swift      # 5회 / 10회 세그먼트 선택
├── ViewModels/
│   ├── Test/
│   │   └── TestViewModel.swift          # @MainActor @Observable
│   └── Result/
│       └── ResultViewModel.swift        # @MainActor @Observable (순차 공개 타이머 소유)
├── Models/
│   ├── AppPhase.swift                   # enum AppPhase: Sendable
│   ├── TestSession.swift                # struct TestSession: Sendable (평균·최고·최악·실격수)
│   ├── ReactionAttempt.swift            # struct ReactionAttempt: Sendable (ms, isCheated)
│   ├── Grade.swift                      # enum Grade (10 등급, 이모지·이름·설명)
│   └── ReactionError.swift              # enum ReactionError: Error, Sendable
└── Services/
    ├── ReactionTestService.swift        # actor (startTime 가변 상태)
    └── StatisticsService.swift          # struct (순수 계산, 가변 상태 없음)
```

### 동시성 경계

- **View**: `@MainActor struct` (SwiftUI 기본). `import SwiftUI` 허용.
- **ViewModel**: `@MainActor final class` + `@Observable`. `import SwiftUI` 금지 (Foundation + Observation만). UI 타입(Color/Font) 직접 사용 금지.
- **Service (가변 상태)**: `actor ReactionTestService`. `startTime: Double` 보관. `markGreen()`/`calculateMs(tapTime:)` 제공.
- **Service (순수 계산)**: `struct StatisticsService: StatisticsServiceProtocol, Sendable`. 가변 상태 없음 → `actor` 강제 금지.
- **Model**: `struct` + `Sendable` 준수. `AppPhase`, `TestSession`, `ReactionAttempt`, `Grade` 모두 `Sendable`.
- **Protocol 기반 DI**: `ReactionTestServiceProtocol`, `StatisticsServiceProtocol` 선언 후 ViewModel 이니셜라이저에서 주입. 테스트 대체 가능.
- **금지 사항**: `DispatchQueue`, `@Published`, `ObservableObject`, `Timer.scheduledTimer`, `Date()` 기반 시간 측정, UIKit 햅틱을 ViewModel에서 직접 호출.

### AppPhase 화면 전환

```swift
enum AppPhase: Sendable {
    case home
    case testing(rounds: Int)
    case result(session: TestSession)
}
```

`ReactionTimeCheckerApp`이 `@State private var phase: AppPhase = .home`을 소유하고 `switch phase`로 루트 뷰를 교체한다. **`NavigationStack` / `sheet` / `fullScreenCover` 절대 사용 금지.** 전환 시 `.transition(.opacity.combined(with: .scale(scale: 0.98)))` + `withAnimation(.smooth(duration: 0.35))`로 부드럽게 교체.

### TestState 상태 머신

```
idle
  ↓ (시작 진입)
countdown(3) → countdown(2) → countdown(1) → countdown(0 = "GO!")
  ↓ (각 1초, 탭 무시)
waiting (palette.error, "준비..." 표시)
  ↓ (1.0~5.0초 Task.sleep 랜덤 딜레이)
green (palette.success, "TAP!" 큰 문구)
  ↓ (유저 탭 → CACurrentMediaTime diff 계산)
recorded(ms: Int)
  ↓ (1.5초 후 자동 전환)
     ├─ 남은 라운드 있음 → countdown(3)부터 재시작
     └─ N회 완료 → completed → phase = .result(session)

waiting / countdown(0=GO 직전) 단계에서 탭 시:
  ↓
cheated (palette.error, 흔들림 + 재미있는 메시지 + "다시 하기" 버튼)
  ↓ ("다시 하기" 탭 → 같은 라운드 번호로 countdown(3) 재시작)
```

`enum TestState: Sendable`:
- `case idle`
- `case countdown(Int)` — 3, 2, 1, 0(GO!)
- `case waiting`
- `case green`
- `case recorded(ms: Int)`
- `case cheated(message: String)`
- `case completed`

**탭 처리 규칙** (TestViewModel.handleTap):
| 현재 state | 탭 처리 |
|---|---|
| `idle` | 무시 |
| `countdown(3/2/1)` | **무시 (실격 아님)** — 카운트다운 중 준비 동작은 자연스러움 |
| `countdown(0)` | GO 신호 직후이므로 waiting 전환 중일 수 있음 → waiting 규칙과 동일하게 취급 |
| `waiting` | **실격** → `cheated` 전환, 현재 라운드를 `isCheated: true` attempt로 기록 |
| `green` | 유효 기록 → `recorded(ms:)` |
| `recorded` | 무시 (1.5초 자동 전환 대기) |
| `cheated` | 무시 (사용자는 "다시 하기" 버튼만 누를 수 있음) |
| `completed` | 무시 |

---

## 기능 목록

### 기능 1: 홈 화면 (HomeView)

**목적**: 진입 화면. 라운드 수 선택 → 테스트 시작.

**UI 배치 (세로 중앙 정렬 + VStack spacing: DesignSpacing.lg)**:

1. 상단 여백 (Spacer, max 80pt)
2. 앱 타이틀 — `Text("ReactionTimeChecker")` `.font(.ssTitle1)` `.foregroundStyle(palette.textPrimary)`
3. 이모지 심볼 — `Text("⚡️").font(.system(size: 72))` (디자인 시스템에 72pt 토큰이 없어 예외적으로 허용, 서브 타이틀 위 장식)
   > **예외 메모**: 이모지는 색상이 아닌 심볼 문자이므로 하드코딩 금지 규정(Color/Font.system)과 무관하게 허용.
4. 서브 카피 — `Text("얼마나 빠른지 확인해볼까?")` `.font(.ssBody)` `.foregroundStyle(palette.textSecondary)`
5. `SurfaceCard(elevation: .raised)` 안에 `RoundSelectorView(selected: $selectedRounds)` 포함
6. `Text("\(selectedRounds)회 측정 후 등급 발표!")` `.font(.ssFootnote)`
7. `PillButton(title: "시작하기") { phase = .testing(rounds: selectedRounds) }`
8. `Text("⚠ 빨간 화면에서 절대 탭하지 마세요!").font(.ssCaption).foregroundStyle(palette.textSecondary)`
9. 하단 Spacer

**RoundSelectorView 디자인**:
- 수평 HStack에 5회 / 10회 두 개의 캡슐 버튼 (각 `RoundedActionButton` 스타일 변형)
- 선택된 쪽: `palette.accent` 배경 + 흰 텍스트, `.ssTitle2` 폰트
- 비선택: `palette.surface` 배경 + `palette.textSecondary` 텍스트
- 상태 변화 시 `view.gentleSpring(value: selectedRounds)` 적용
- 선택 시 light 햅틱 (`.onChange(of: selectedRounds)`)

**HomeView 상태**:
```swift
struct HomeView: View {
    @Binding var phase: AppPhase
    @State private var selectedRounds: Int = 5   // 5 또는 10
    @Environment(\.designPalette) var palette
}
```
**HomeViewModel 파일 생성 금지** (평가 기준 명시).

**최고 기록 표시**: MVP 범위에서는 **표시하지 않는다** (UserDefaults 저장 없음). 추후 확장 가능하도록 구조만 설계.

---

### 기능 2: 카운트다운 (Countdown)

**목적**: 테스트 시작 전 긴장감 고조 및 사용자 준비 시간 제공.

**진행 시퀀스**: `3 → 2 → 1 → GO!` 각 1초씩, 총 4초. 이후 `waiting` 상태로 즉시 전환.

**구현 방식**:
- `TestViewModel`에서 `Task { await runCountdown() }` 실행
- 각 단계마다 `state = .countdown(n)`; `try? await Task.sleep(nanoseconds: 1_000_000_000)`
- `Task.sleep` 사용 (절대 `Timer.scheduledTimer` 금지)
- `Task` 취소 처리: ViewModel이 소유한 `currentTask: Task<Void, Never>?`를 phase 이탈/재시도 시 `.cancel()`

**UI 표현 (CountdownView in TestComponents.swift)**:
- 배경: `palette.surface`
- 중앙에 거대 숫자 `Text("\(n)")` `.font(.ssLargeTitle)` (42pt bold)
- `countdown(0)`일 땐 `Text("GO!")` 로 교체하며 `palette.success`로 배경 선 전환
- **전환 애니메이션**: `.id(n)` + `.transition(.scale(scale: 0.5).combined(with: .opacity))` + `withAnimation(.spring(response: 0.35, dampingFraction: 0.55))`
- 숫자 주변에 `palette.accent` 링 circle `.scaleEffect` 펄스 애니메이션 (`.repeatForever(autoreverses: true)` 0.6초)
- 상단에 `RoundProgressView(current: currentRound, total: totalRounds)` 작게 표시 (예: "3 / 5")

**탭 처리**: `countdown(3/2/1)` 상태에서 탭이 들어오면 `handleTap`에서 `return` 하여 완전히 무시. 실격 처리하지 않는다. `countdown(0)`은 waiting과 동일 취급.

**햅틱**: 각 숫자 전환 시 `.onChange(of: state)`에서 `.impact(.light)`. `GO!` 에서는 `.impact(.medium)`.

---

### 기능 3: 반응속도 테스트 (waiting → green → recorded)

**목적**: 실제 반응속도를 측정한다. 이 앱의 심장.

**waiting 단계**:
- 배경: `palette.error` 풀스크린 (긴장 유발)
- 중앙 텍스트: `Text("준비...").font(.ssTitle2).foregroundStyle(.white)`
- 서브: `Text("초록색이 되면 바로 탭!").font(.ssBody).foregroundStyle(.white.opacity(0.85))`
- 배경이 미세하게 맥동(pulse) — `.opacity(0.92 → 1.0)` 0.8초 repeatForever
- 탭 → `cheated` 전환

**딜레이 로직 (ReactionTestService.actor)**:
```swift
func scheduleGreen() async throws {
    let delay = Double.random(in: 1.0...5.0)
    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    startTime = CACurrentMediaTime()   // actor 내부에서 기록
}
```
- `Task.sleep`이 취소되면 `CancellationError` 발생 → ViewModel이 catch 후 상태 유지
- 재시도 시 이전 Task를 반드시 취소해야 stale sleep이 남지 않는다

**green 단계**:
- waiting 딜레이 종료 직후 `state = .green` + ViewModel 측에서 이미 actor가 startTime을 기록한 상태
- 배경: `palette.success` 풀스크린
- 중앙 텍스트: `Text("TAP!").font(.ssLargeTitle).foregroundStyle(.white)`
- **팝 애니메이션**: `.scaleEffect` 1.0 → 1.15 spring `.gentleSpring(value: state)`
- 배경 전환은 `.animation(.easeOut(duration: 0.08), value: state)`로 즉각적이지만 부드럽게
- 햅틱: `.impact(.heavy)` (GO 신호 임팩트)

**탭 감지 & 측정 정밀도 (핵심)**:
- **반드시 View의 `.onTapGesture`에서 즉시** `let tapTime = CACurrentMediaTime()` 기록
- actor 메서드 `await` 호출 전이어야 함 (await 사이 hop 지연 방지)
- ViewModel로 전달:
  ```swift
  .onTapGesture {
      let tapTime = CACurrentMediaTime()
      Task { await viewModel.handleTap(at: tapTime) }
  }
  ```
- 왜 `CACurrentMediaTime()`인가: `Date()`는 시스템 시각 변경에 영향받고 monotonic 보장 없음. `CACurrentMediaTime()`은 Mach absolute time 기반으로 단조 증가 + 부팅 시점부터의 초 단위 double을 반환 → ms 측정에 최적.

**recorded 단계**:
- `state = .recorded(ms: ms)`
- 배경은 `palette.success` 유지 (팝 이후 자연스러운 연속)
- 중앙 표시: `Text("\(ms) ms").font(.ssLargeTitle)` + 아래 `Text("기록됨!").font(.ssTitle2)`
- 등장 애니메이션: `.transition(.scale(scale: 0.6).combined(with: .opacity))` spring
- 햅틱: `.impact(.light)` (기록 확정 피드백)
- **1.5초 후 자동 전환** — ViewModel에서 `Task { try? await Task.sleep(nanoseconds: 1_500_000_000); await advanceToNextRound() }`
- 남은 라운드 있음 → `countdown(3)` 부터 다시
- N회 완료 → `TestSession` 생성 후 `phase = .result(session)`

**진행 상태 표시 (RoundProgressView)**:
- 화면 상단 safe area 바로 아래 고정
- 가로 점 `●●●○○` 5회/10회에 맞춰 표시. 완료 = `palette.success`, 현재 = `palette.accent`, 미수행 = `palette.surface`
- 오른쪽에 텍스트 `"3 / 5"` `.font(.ssFootnote)`
- **실격 횟수 배지** 오른쪽 끝: `Text("❌ \(cheatedCount)").font(.ssCaption)` (실격이 1회 이상일 때만 표시)
- countdown, waiting, green, recorded, cheated 모든 단계에서 지속 노출

**TestSession 생성 로직**:
```swift
struct TestSession: Sendable {
    let attempts: [ReactionAttempt]        // 전체 (실격 포함)
    let validAttempts: [ReactionAttempt]   // 유효 N개만
    let averageMs: Int
    let bestMs: Int
    let worstMs: Int
    let cheatedCount: Int
    let rounds: Int
}
```

---

### 기능 4: 부정 탭 처리 (cheated)

**목적**: "빨간 화면에서 미리 탭하면 안 됨" 규칙을 재미있게 패널티화.

**감지 조건**: `state == .waiting` 에서 탭 발생 시.

**실격 메시지 풀 (최소 5종, 랜덤 선택)**:
```swift
private static let cheatedMessages: [String] = [
    "성급하시네요! 😤 빨간불에선 기다려요!",
    "앗! 너무 빨랐어요. 초록불을 기다려주세요 🚦",
    "실격! 눈 감고 탭한 건 아니죠? 🙈",
    "부정 출발! 🏃‍♂️💨 다시 한 번 해볼까요?",
    "헉! 빨간불에 건너면 안 돼요 🚸",
    "치팅 감지! 🕵️ 정정당당하게!",
]
```

**UI (cheated 상태)**:
- 배경: `palette.error` 풀스크린
- 상단 `Text("❌ 실격").font(.ssTitle1).foregroundStyle(.white)`
- 중앙 `Text(randomMessage).font(.ssTitle2).foregroundStyle(.white).multilineTextAlignment(.center).padding(.horizontal, DesignSpacing.lg)`
- 하단 `RoundedActionButton(title: "다시 하기") { viewModel.retryCurrentRound() }`
- **흔들기 애니메이션**: `ShakeEffect(shakes: 3)` geometryEffect를 전체 컨테이너에 적용. `.onAppear`에서 `withAnimation(.linear(duration: 0.4)) { shakeTrigger += 1 }`
- 햅틱: `.notification(.error)` (실패 피드백) — `.onChange(of: state)`에서 처리

**ShakeEffect 구현 (TestComponents.swift)**:
```swift
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(translationX: amount * sin(animatableData * .pi * shakesPerUnit), y: 0)
        )
    }
}
```

**재시도 로직**:
1. `retryCurrentRound()` 호출 시 기존 `currentTask?.cancel()`
2. 현재 라운드의 cheated attempt를 `attempts` 배열에 `isCheated: true`로 기록 (라운드 번호 동일)
3. `cheatedCount += 1`
4. `state = .countdown(3)` 로 전환하고 `Task { await runCountdown() }` 다시 실행
5. 카운트다운 → waiting → green 사이클 재개
6. **실격 횟수 제한 없음** — 유효 N회를 채울 때까지 계속

**전 라운드 실격 케이스 대비**:
- 이 경우는 사용자가 끝까지 실격만 하고 유효 기록이 0인 상태에서 앱을 종료하는 상황인데, 자동으로는 발생하지 않음 (유효 N회 채워야만 completed로 전환되므로).
- 단, **결과 화면(`ResultView`)에서 `session.validAttempts.isEmpty` 방어 로직**을 반드시 둔다 — "측정 결과 없음" 메시지 + 홈 복귀 버튼. 이는 테스트용 초기화 경로를 위한 안전장치.

---

### 기능 5: 결과 화면 (ResultView)

**목적**: 드라마틱한 순차 공개로 "와!" 감탄을 유도. 공유하고 싶게 만든다.

**순차 공개 시퀀스 (ResultViewModel이 소유)**:

고정 순서: **평균ms → 백분위 → 이모지 → 등급명 → 등급 설명 → 비교 차트 → 실격 통계 → 공유 버튼**

```swift
@MainActor @Observable
final class ResultViewModel {
    enum RevealStage: Int, Sendable {
        case nothing, averageMs, percentile, emoji, gradeName, gradeDesc, comparison, cheatedStat, shareButton
    }
    private(set) var stage: RevealStage = .nothing
    let session: TestSession
    let percentile: Int
    let grade: Grade

    func startReveal() async {
        let steps: [(RevealStage, UInt64)] = [
            (.averageMs,    600_000_000),
            (.percentile,   700_000_000),
            (.emoji,        700_000_000),
            (.gradeName,    500_000_000),
            (.gradeDesc,    500_000_000),
            (.comparison,   600_000_000),
            (.cheatedStat,  500_000_000),
            (.shareButton,  400_000_000),
        ]
        for (next, delay) in steps {
            try? await Task.sleep(nanoseconds: delay)
            stage = next
        }
    }
}
```

`ResultView.onAppear`에서 `Task { await vm.startReveal() }`. `stage >= .xxx` 조건으로 각 요소 `.opacity` / `.scaleEffect` 전환.

**레이아웃 (ScrollView + VStack spacing: DesignSpacing.lg)**:

1. **상단 타이틀** — `Text("결과 발표").font(.ssTitle1)` (stage 무관 즉시 표시)

2. **평균 ms 큰 숫자** (stage >= .averageMs):
   - `SurfaceCard(elevation: .raised)` 안에
   - `Text("평균 반응속도").font(.ssFootnote).foregroundStyle(palette.textSecondary)`
   - `Text("\(session.averageMs) ms").font(.ssLargeTitle).foregroundStyle(palette.textPrimary)`
   - HStack: `Text("최고: \(bestMs)ms").font(.ssBody)` / `Text("최악: \(worstMs)ms").font(.ssBody)`
   - 등장: `.transition(.scale(scale: 0.7).combined(with: .opacity))` spring

3. **백분위** (stage >= .percentile):
   - `Text("상위 \(percentile)%").font(.ssTitle2).foregroundStyle(palette.accent)`
   - 카운트업 애니메이션: `.contentTransition(.numericText(value: Double(percentile)))`
   - 햅틱: `.impact(.medium)` (`.onChange(of: stage)`)

4. **등급 카드 (GradeCardView)**:
   - `GlassCard { ... }` 컨테이너
   - (stage >= .emoji): `Text(grade.emoji).font(.system(size: 96))` 스프링 등장 (Pop) + heavy 햅틱
     > 이모지 크기만 예외 허용 — 색상/폰트 하드코딩과 무관
   - (stage >= .gradeName): `Text(grade.name).font(.ssTitle1).foregroundStyle(palette.textPrimary)` fade-in
   - (stage >= .gradeDesc): `Text(grade.description).font(.ssBody).foregroundStyle(palette.textSecondary).multilineTextAlignment(.center)` fade-in

5. **비교 차트 (stage >= .comparison)**:
   - `SurfaceCard` 내부 제목: `Text("다른 사람들과 비교").font(.ssTitle2)`
   - 4개 수평 바: "나", "운동선수(180ms)", "게이머(200ms)", "일반인(250ms)"
   - 각 바: `ZStack` — 배경 `palette.surface`, 전경 `palette.accent`(나일 경우) / `palette.textSecondary`(타인)
   - 너비: `min(CGFloat(ms) / 400.0, 1.0) * maxWidth` (400ms가 100% 기준)
   - 왼쪽 레이블 `.font(.ssFootnote)`, 오른쪽 ms 값 `.font(.ssFootnote)`
   - 등장: 바 `.scaleEffect(x: stage >= .comparison ? 1 : 0, anchor: .leading)` `.gentleSpring`

6. **실격 통계 (stage >= .cheatedStat)**:
   - `Text("총 실격 횟수: \(session.cheatedCount)회").font(.ssFootnote)`
   - `cheatedCount == 0`이면 `"완벽해요! 단 한 번도 실격 없음 👏"`
   - `cheatedCount >= 5`이면 `"성격 급한 편이시네요 😅 (\(cheatedCount)회 실격)"`

7. **액션 버튼 (stage >= .shareButton)**:
   - `OutlineButton(title: "결과 공유하기") { }` ← **action 비어있음 (placeholder)**
   - `Text("공유 기능은 곧 추가됩니다").font(.ssCaption).foregroundStyle(palette.textSecondary)`
   - `PillButton(title: "다시 도전하기") { phase = .home }`

8. **전 라운드 실격 방어** (`session.validAttempts.isEmpty`):
   - 위 구성 대신 `Text("측정 결과가 없습니다 🤔").font(.ssTitle2)` + `Text("빨간불에서는 탭하지 마세요!").font(.ssBody)` + `PillButton(title: "재도전") { phase = .home }`

**햅틱 (결과 화면 `.onChange(of: stage)`)**:
- `.percentile` 진입: `.impact(.medium)`
- `.emoji` 진입: `.impact(.heavy)` (등급 리빌의 하이라이트)
- `.shareButton` 진입: `.impact(.light)`

---

## 등급 시스템 상세

**`Grade` enum** (Sendable, CaseIterable):

```swift
enum Grade: String, Sendable, CaseIterable {
    case lightningGod, ninja, cyborg, cheetah, rabbit,
         human, slothJr, turtle, snail, fossil

    var emoji: String { ... }
    var name: String { ... }
    var description: String { ... }
    var percentileUpperBound: Int { ... }   // 포함
}
```

| 상위 % 범위 (포함) | case | name | 이모지 | 한 줄 설명 |
|---|---|---|---|---|
| 1 ~ 10 | `.lightningGod` | 반응속도의 신 | ⚡️ | "당신은 번개보다 빠릅니다" |
| 11 ~ 20 | `.ninja` | 닌자 | 🥷 | "닌자도 당신 앞엔 느림보" |
| 21 ~ 30 | `.cyborg` | 사이보그 | 🤖 | "인간의 한계를 넘었군요" |
| 31 ~ 40 | `.cheetah` | 치타 | 🐆 | "지구상 가장 빠른 동물급" |
| 41 ~ 50 | `.rabbit` | 토끼 | 🐰 | "평균 이상의 빠른 손" |
| 51 ~ 60 | `.human` | 일반인 | 🧑 | "평범하지만 나쁘지 않아요" |
| 61 ~ 70 | `.slothJr` | 나무늘보 주니어 | 🦥 | "조금 더 집중해봐요..." |
| 71 ~ 80 | `.turtle` | 거북이 | 🐢 | "느려도 괜찮아요, 꾸준히!" |
| 81 ~ 90 | `.snail` | 달팽이 | 🐌 | "달팽이도 당신보다 빠릅니다" |
| 91 ~ 100 | `.fossil` | 화석 | 🪨 | "혹시 자고 계셨나요...?" |

`StatisticsService.determineGrade(percentile:)`: percentile 값을 10으로 나눠 올림 / 매핑. percentile 1~10 → lightningGod, 11~20 → ninja, … 91~100 → fossil.

---

## 백분위 계산 방법

**`StatisticsService: struct`** (가변 상태 없음, `Sendable`):

```swift
struct StatisticsService: StatisticsServiceProtocol, Sendable {
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
        // 1. ms가 100 이하 → percentile 1 (상위 1%)
        // 2. ms가 400 이상 → percentile 99
        // 3. 중간값: anchors에서 averageMs를 감싸는 두 앵커 (lo, hi) 찾고 선형 보간
        //    t = (averageMs - lo.ms) / (hi.ms - lo.ms)
        //    p = lo.percentile + t * (hi.percentile - lo.percentile)
        // 4. max(1, min(99, Int(p.rounded())))
    }

    func determineGrade(percentile: Int) -> Grade {
        switch percentile {
        case ...10:  return .lightningGod
        case 11...20: return .ninja
        case 21...30: return .cyborg
        case 31...40: return .cheetah
        case 41...50: return .rabbit
        case 51...60: return .human
        case 61...70: return .slothJr
        case 71...80: return .turtle
        case 81...90: return .snail
        default:      return .fossil
        }
    }
}
```

**ms와 percentile 관계**: ms가 낮을수록 상위 %. 앵커는 전 세계 인간의 대략적 분포를 근사한 교육용 데이터(실제 통계 아님, 재미 목적). 선형 보간으로 `150ms → 1%`, `250ms → 50%`, `400ms → 99%` 등 연속값 계산.

**예시**:
- 평균 197ms → (190, 10) ~ (205, 20) 사이, t ≈ 0.467 → p ≈ 14.67 → 15% → `.ninja`
- 평균 245ms → (235, 40) ~ (250, 50), t = 0.667 → p ≈ 46.67 → 47% → `.rabbit`

---

## 색상 & 애니메이션 계획

### 상태별 배경 색상 (palette 토큰 고정)

| TestState | 배경 | 비고 |
|---|---|---|
| `idle` | `palette.background` | 전환 전 기본 |
| `countdown(n)` | `palette.surface` | 준비 단계 중립 |
| `waiting` | `palette.error` | 빨강 → 긴장 유발 |
| `green` | `palette.success` | 초록 → 즉시 반응 |
| `recorded(ms:)` | `palette.success` | 초록 유지 + 숫자 팝 |
| `cheated` | `palette.error` | 빨강 유지 + 흔들림 |
| `completed` | `palette.background` | 짧은 페이드 후 .result phase |

화면 전체 배경에 `.animation(.easeInOut(duration: 0.12), value: state)` 적용 (너무 느리면 긴장감 떨어짐).

### 핵심 애니메이션

| 위치 | 애니메이션 | 타이밍 |
|---|---|---|
| Countdown 숫자 교체 | `.transition(.scale(0.5).combined(with: .opacity))` + spring | response 0.35, damping 0.55 |
| Waiting pulse | `.opacity` 0.92↔1.0 repeatForever | 0.8s autoreverses |
| GO 팝 | `.scaleEffect` 1.0→1.15 spring | `.gentleSpring(value: state)` |
| Recorded 숫자 등장 | `.transition(.scale(0.6).combined(with: .opacity))` spring | response 0.4 |
| Cheated shake | `ShakeEffect(shakes: 3)` | 0.4s linear |
| Phase 전환 | `.transition(.opacity.combined(with: .scale(0.98)))` | smooth 0.35s |
| Result reveal | `.scaleEffect` 0.7→1.0 + `.opacity` 0→1 spring | 각 0.5~0.7s 간격 |
| 등급 이모지 Pop | `.scaleEffect` 0.3→1.0 + rotation 0→360 (한바퀴) | spring response 0.6 damping 0.5 |
| 비교 바 차트 | `.scaleEffect(x:, anchor: .leading)` `.gentleSpring` | sequential |

### 햅틱 (모두 `.onChange(of:)`로 View에서 처리 — MVVM 보호)

| 이벤트 | 햅틱 | 위치 |
|---|---|---|
| 카운트다운 숫자 변경 | `UIImpactFeedbackGenerator(.light)` | TestView `.onChange(of: state)` |
| GO (green 진입) | `.impact(.heavy)` | TestView |
| recorded 기록 확정 | `.impact(.light)` | TestView |
| cheated 진입 | `UINotificationFeedbackGenerator().notificationOccurred(.error)` | TestView |
| RoundSelector 탭 | `.impact(.light)` | HomeView `.onChange(of: selectedRounds)` |
| Result percentile 공개 | `.impact(.medium)` | ResultView `.onChange(of: stage)` |
| Result emoji 공개 | `.impact(.heavy)` | ResultView |
| Result shareButton 공개 | `.impact(.light)` | ResultView |

**주의**: ViewModel에서 `UIImpactFeedbackGenerator`를 `import UIKit` 해서 호출하면 MVVM 위반. 반드시 View의 `.onChange` 블록에서 인스턴스화 + 호출한다.

---

## 코드 컨벤션

### 파일명

- Swift 파일명은 타입명과 일치: `TestViewModel.swift` ↔ `final class TestViewModel`
- 한 파일 = 한 주요 타입 원칙 (작은 헬퍼는 같은 파일 허용)
- `TestComponents.swift`는 예외적으로 `ShakeEffect`, `CountdownView`, `RoundProgressView` 등 TestView 전용 작은 구조체를 묶는다.

### 접근 제어자

- 모든 타입 선언에 `public` / `internal` (기본) / `private` 명시
- ViewModel 프로퍼티: 외부 읽기만 허용되면 `private(set)`
- Service 내부 상태: `private`
- Protocol 정의: `internal` (앱 내부만 사용)

### 에러 타입

```swift
enum ReactionError: Error, Sendable {
    case taskCancelled
    case invalidState
    case noValidAttempts
}
```
`print()`로만 처리 금지. ViewModel은 에러를 `state` 변화로 치환하거나 swallow 시 `try?` 명시.

### TestState / AppPhase enum 원칙

- `Bool` 여러 개로 상태 관리 금지 (`isWaiting`, `isGreen` 등 ❌)
- 상태는 반드시 `enum` + `Sendable`
- associated value (예: `recorded(ms: Int)`)로 필요한 데이터 함께 전달

### Import 규칙

| 파일 종류 | 허용 import |
|---|---|
| View | `SwiftUI`, `TopDesignSystem`, 필요 시 `UIKit` (햅틱 한정) |
| ViewModel | `Foundation`, `Observation`, `QuartzCore` (CACurrentMediaTime 필요 시) |
| Service (actor) | `Foundation`, `QuartzCore` |
| Service (struct) | `Foundation` |
| Model | `Foundation` |

**ViewModel에서 `import SwiftUI` 절대 금지.** Color/Font 등 UI 타입이 섞이면 Evaluator가 MVVM 위반으로 감점.

### Task 관리

- ViewModel은 `private var currentTask: Task<Void, Never>?` 보관
- 재시도 / phase 이탈 / deinit 시 `currentTask?.cancel()`
- 카운트다운 + 딜레이 + 전환을 하나의 Task로 묶어 `Task.checkCancellation()` 적절히 활용

### 동시성 요약 체크리스트 (Generator가 지켜야 할 것)

- [ ] 모든 ViewModel: `@MainActor final class ... { ... }` + `@Observable`
- [ ] `ReactionTestService`: `actor`
- [ ] `StatisticsService`: `struct` + `Sendable`
- [ ] 모든 Model: `struct` + `Sendable`
- [ ] `AppPhase`, `TestState`, `Grade`, `ReactionError`: `enum` + `Sendable`
- [ ] `DispatchQueue` / `@Published` / `ObservableObject` 0회
- [ ] `Timer.scheduledTimer` 0회, 모든 대기는 `Task.sleep`
- [ ] 시간 측정 전부 `CACurrentMediaTime()`
- [ ] `.onTapGesture`에서 `tapTime` 즉시 캡처 후 ViewModel에 전달
- [ ] ViewModel에 `import SwiftUI` 없음

---

## 요약 — 왜 재미있는가 (재미 & UX 채점 대비)

1. **긴장의 빨강 → 해방의 초록**: 원초적 색 대비로 심박을 올림.
2. **카운트다운 스프링 애니메이션**: 3-2-1 숫자가 팝하며 기대감 증폭.
3. **실격 메시지 5종 랜덤 + 흔들림 + 에러 햅틱**: 실패조차 웃기게.
4. **결과 순차 공개 (8단계)**: 평균 → 백분위 → 이모지 → 등급명 → 설명 → 비교 → 실격 → 공유. 각 단계 스프링 + 햅틱으로 감탄 유도.
5. **10개 캐릭터 등급 (⚡️ ~ 🪨)**: 각각 한 줄 설명까지 있어 공유 동기 확보.
6. **비교 차트**: 내 기록이 운동선수/게이머/일반인 대비 어디 있는지 시각화 → 경쟁심 자극.
7. **"다시 도전하기" 버튼**: 결과 후 바로 재시작 가능 → 중독성.

이 SPEC의 모든 세부사항은 PROJECT_CONTEXT.md 고정 요구사항을 존중하면서, 평가 기준의 "재미 & UX" 항목 합격선(카운트다운, 스프링 GO, 흔들기+에러햅틱+랜덤 메시지 최소 3종, 재시도 로직, 순차 공개, 햅틱 4종, 10등급 이모지+설명, 공유 placeholder)을 전부 충족하도록 설계되었다.
