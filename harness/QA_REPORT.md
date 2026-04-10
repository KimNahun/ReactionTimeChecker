# QA Report — ReactionTimeChecker (Evaluator R1)

검수일: 2026-04-10
검수자: Evaluator Agent (Opus)
대상: `harness/output/` 전체 Swift 파일 (16개)

---

## 전체 판정

**전체 판정**: **불합격 (조건부 합격 이하)**
**가중 점수**: **6.05 / 10.0**

> Swift 6 엄격 동시성 모델에서 컴파일 실패가 예상되는 치명적 결함(ViewModel의 `deinit`에서 MainActor 격리 프로퍼티 접근)이 2건 존재한다. 이 문제가 해결되지 않으면 앱은 빌드 자체가 불가능하므로 동시성 항목을 4점으로 평가했고, 평가 기준(evaluation_criteria.md) 규정에 따라 **동시성 ≤ 4 → 무조건 불합격**.
> 기능·재미·MVVM·코드 품질은 전반적으로 좋으나, 동시성 결함 하나로 파이프라인 재실행이 필요하다.

---

## 항목별 점수

- **Swift 6 동시성: 4 / 10** — `@MainActor` 클래스의 nonisolated `deinit`에서 격리 프로퍼티(`currentTask`, `revealTask`) 참조. Swift 6에서 컴파일 에러.
- **MVVM 분리: 9 / 10** — HomeViewModel 없음, 의존 방향 단방향, ViewModel에 `import SwiftUI` 없음. 단, ViewModel이 `Task` 내부에서 직접 상태를 돌리는 부분은 잘 분리됨.
- **재미 & UX: 8 / 10** — 카운트다운, 팝/쉐이크/펄스 애니메이션, 실격 랜덤 메시지 6종, 순차 등급 공개, 10개 등급 이모지·이름·설명 모두 충실. `waiting`에 명시적 햅틱 없음(감점 1), `recorded` 블록에 `.transition` 미사용으로 팝 효과 약함(감점 1).
- **기능 완성도: 9 / 10** — 라운드 선택, 1~5초 랜덤, `CACurrentMediaTime` 측정, 부정 탭 감지, 실격 카운트 제외, 통계/백분위/비교 차트/실격 방어 모두 구현. `ResultViewModel.init` 에서 `self.percentile` 계산 시점이 `session.validAttempts.isEmpty`일 때 `averageMs == 0`이 들어가므로 `calculatePercentile(0) → 1` 을 반환해 잘못된 grade가 계산됨(empty view로 가려지긴 하나, 로직 상 결함).
- **코드 품질: 7 / 10** — 접근 제어자 명시, `TestState`/`AppPhase`/`Grade`/`ReactionError` enum 분리 양호. 단, `RoundProgressView.dotColor(for:)` 반환 타입이 `any ShapeStyle`이라 `.fill(dotColor(for: index))` 호출이 Swift 6에서 컴파일 실패 가능. `SPEC.md`에 적힌 "ViewModel에 `QuartzCore` 허용" 가이드와 달리 `TestViewModel`에서는 View가 `CACurrentMediaTime()`을 직접 호출하고 ms만 전달하므로 ViewModel 쪽 import는 정상.

**가중 계산**: `(4 × 0.30) + (9 × 0.25) + (8 × 0.20) + (9 × 0.15) + (7 × 0.10) = 1.20 + 2.25 + 1.60 + 1.35 + 0.70 = 7.10` (참고용)
단, **동시성 4 이하 → 무조건 불합격** 규정 적용으로 최종 판정은 불합격.

---

## Swift 6 동시성 검증 상세

### [치명] 결함 1 — `TestViewModel.deinit`에서 MainActor 프로퍼티 참조

**파일**: `output/ViewModels/Test/TestViewModel.swift:147-149`

```swift
deinit {
    currentTask?.cancel()
}
```

**문제**:
- `TestViewModel`은 `@MainActor final class`로 선언됨.
- Swift 6에서 `@MainActor` 클래스의 `deinit`은 **기본적으로 nonisolated** (deinit은 임의의 스레드에서 호출 가능).
- `currentTask`는 클래스 프로퍼티이므로 **MainActor에 격리**되어 있다.
- nonisolated `deinit`에서 MainActor 격리 프로퍼티에 접근 → **컴파일 에러**:
  `Main actor-isolated property 'currentTask' can not be referenced from a nonisolated context`

**근거**: Swift 6 엄격 동시성 / SE-0371 (Isolated synchronous deinit) 규정. 기본 `deinit`은 격리되지 않으며, 격리 프로퍼티에 직접 접근할 수 없다. 본 결함은 파이프라인 재호출 사용자 메시지에서 명시적으로 확인을 요청한 항목이다.

**수정 방법**:
`Task` 프로퍼티는 `deinit`에서 취소하지 않거나, `Task` 참조를 nonisolated로 만들거나, `deinit` 전에 명시적으로 `cancel`할 수 있는 훅을 제공해야 한다. 예:
```swift
// 옵션 A: deinit에서 Task 레퍼런스만 캡처하고 취소 (nonisolated 안전)
private nonisolated(unsafe) var currentTask: Task<Void, Never>?
// 또는
// 옵션 B: deinit에서 호출하지 않고 onDisappear에서 cancel 훅을 제공
// 옵션 C: Task를 격리되지 않은 별도 저장소에 보관 (예: actor)
```
단, 본 에이전트는 코드를 수정하지 않으며 Generator 단계에서 반드시 이 패턴을 재설계해야 한다.

### [치명] 결함 2 — `ResultViewModel.deinit`에서 MainActor 프로퍼티 참조

**파일**: `output/ViewModels/Result/ResultViewModel.swift:80-82`

```swift
deinit {
    revealTask?.cancel()
}
```

**문제**: 결함 1과 동일. `@MainActor` 클래스의 nonisolated `deinit`에서 격리 프로퍼티 `revealTask` 접근 → 컴파일 에러.

**수정 방법**: 결함 1과 동일한 패턴으로 수정. 만약 `deinit`에서의 Task 취소가 불가피하면 `Task`를 `nonisolated(unsafe)` 또는 `Atomic`한 저장소에 두거나, 뷰의 `.onDisappear`에서 명시적으로 취소하도록 아키텍처를 변경해야 한다.

### [확인] `init`에서의 격리 접근

**파일**: `output/ViewModels/Result/ResultViewModel.swift:33-39`

```swift
init(session: TestSession, statisticsService: StatisticsServiceProtocol = StatisticsService()) {
    self.session = session
    self.statisticsService = statisticsService
    let p = statisticsService.calculatePercentile(averageMs: session.averageMs)
    self.percentile = p
    self.grade = statisticsService.determineGrade(percentile: p)
}
```

- `@MainActor` 클래스의 `init`은 **MainActor 격리**로 간주된다(기본).
- 호출측(`ResultView.init` → `State(initialValue: ResultViewModel(...))`)이 MainActor 컨텍스트(`struct ResultView: View`의 `init`은 MainActor-isolated)에서 호출되므로 문제 없음.
- `TestViewModel.init`도 동일하게 MainActor로 호출되므로 통과.
- 단, `TestViewModel.init`의 기본 인자 `ReactionTestService()`는 호출 지점에서 평가되며 actor 초기화는 synchronous로 격리 없이 가능하므로 통과.

**결론**: init 쪽은 통과. `deinit` 쪽만 결함.

### [확인] `Task { }` 블록 격리 컨텍스트

- `TestViewModel.startTest`, `retryCurrentRound`, `applyValidRecord`의 `Task { ... }` — 모두 `@MainActor` 메서드 내부에서 생성 → Task 클로저는 MainActor 컨텍스트를 상속. 내부에서 `self.runRoundCycle()`, `self.state = ...`, `self.isCompleted` 접근 모두 정상. **통과**.
- `ResultViewModel.startReveal`의 `Task { await runRevealSequence() }` — 동일하게 MainActor 상속. `stage = next` 대입도 정상. **통과**.
- `TestView`의 `.onTapGesture { let tapTime = CACurrentMediaTime(); Task { await viewModel.handleTap(at: tapTime) } }` — View는 MainActor, Task는 MainActor 상속, `await`는 `handleTap`이 MainActor이므로 즉시 실행. **통과**.
- `TestView` `.completed` 분기의 `Task { try? await Task.sleep(...); withAnimation { phase = .result(...) } }` — MainActor 상속, `phase`는 @Binding이므로 MainActor 안전. **통과**.

### [확인] actor / struct 선언

- `ReactionTestService`: `actor` 선언, `startTime: Double` 가변 상태 보호. **통과**.
- `StatisticsService`: `struct StatisticsService: StatisticsServiceProtocol, Sendable` — 가변 상태 없음, 순수 계산. **통과** (PROJECT_CONTEXT.md "가변 상태 없으면 actor 강제 금지" 규정 준수).
- 모든 Model: `struct ... Sendable` 또는 `enum ... Sendable`. **통과**.

### [확인] 금지 API

- `DispatchQueue` 0회 ✔
- `@Published` / `ObservableObject` 0회 (Observation 사용) ✔
- `Timer.scheduledTimer` 0회 (`Task.sleep`만 사용) ✔
- `Date()` 기반 반응 시간 측정 0회 (`CACurrentMediaTime` 사용) ✔

### [확인] nonisolated 남용

- `TestViewModel` / `ResultViewModel`에 `nonisolated` 키워드 없음. 문제는 오히려 `deinit`을 `nonisolated` **로 만드는 대안**을 사용하지 않아 발생함 — 위 결함 1,2 참조.

---

## MVVM 분리 검증

- `HomeView`: `@State var selectedRounds` + `@Binding var phase`만 사용, HomeViewModel 파일 **없음**. **통과**.
- `TestView`: 타이머 없음, 계산 없음, `viewModel.state`만 렌더. **통과**.
- `TestViewModel.swift` / `ResultViewModel.swift`: `import Foundation`, `import Observation`만 사용 → `import SwiftUI` **없음**. Color/Font 직접 사용 **없음**. **통과**.
- 서비스 → ViewModel 역참조 **없음**. **통과**.
- 화면 전환: `AppPhase` switch만 사용, `NavigationStack` / `sheet` / `fullScreenCover` **없음**. **통과**.
- Protocol 기반 DI: `ReactionTestServiceProtocol`, `StatisticsServiceProtocol`을 이니셜라이저 기본 인자로 주입. **통과**.

**감점 1점**: `ReactionTestService`의 `scheduleGreen()`은 actor 내부에서 `Task.sleep`을 수행하는데, `markGreen()`과 기능이 중복된다(둘 다 `startTime`을 세팅). 사용처도 없는 `markGreen`·`randomDelay`가 노출되어 Service 책임 경계가 다소 모호. 사용하지 않는 API는 protocol에서 제거하는 것이 바람직.

---

## 재미 & UX 검증

- **카운트다운 3→2→1→GO**: `runRoundCycle()`의 `stride(from: 3, through: 0, by: -1)` + `CountdownView` seconds=0 분기 처리. `countdown(3/2/1)` 탭 무시, `countdown(0)`은 waiting 취급. **통과**.
- **GO 팝 애니메이션**: `TestView` `.green` 분기에서 `scaleEffect(goScale)` + `.spring(response: 0.3, dampingFraction: 0.5)` 로 1.0 → 1.15 트윈. **통과**.
- **흔들기 + 실격 메시지**: `ShakeEffect(animatableData: shakeTrigger)` + `.cheated` 진입 시 `withAnimation(.linear(duration: 0.4)) { shakeTrigger += 1 }`. `cheatedMessages` 6종 **통과**.
- **재시도 로직**: `retryCurrentRound()`가 기존 Task 취소 후 `runRoundCycle()` 재시작 (카운트다운부터). **통과**.
- **등급 순차 공개**: `ResultViewModel.RevealStage` 9단계 + `runRevealSequence`로 600/700/700/500/500/600/500/400ms 간격. **통과**.
- **10개 등급**: `Grade` enum에 이모지, name, description, `percentileUpperBound` 완비. 모두 SPEC과 일치. **통과**.
- **공유 버튼 placeholder**: `OutlineButton(title: "결과 공유하기", action: { })` + `Text("공유 기능은 곧 추가됩니다")` **통과**.
- **햅틱**: TestView `.onChange(of: state)`에서 countdown(light) / green(heavy) / recorded(light) / cheated(notification .error). RoundSelector(light), ResultView percentile(medium)/emoji(heavy)/shareButton(light). **통과**.
- **진행 표시**: `RoundProgressView` 점 + "N / M" + cheated 배지. **통과**.

**감점 1점**: `waiting` 상태에는 햅틱이 없다(SPEC에 필수 사항은 아니지만, "긴장 유발"을 위해 미세 진동이 더 재미있었을 것).
**감점 1점**: `recorded` 분기의 `VStack` 자체에 `.id(...)` 또는 `.transition`이 래핑되어 있지 않아, 이미 green 상태에서 연속 렌더되며 transition(scale 0.6)이 적용되지 않을 가능성. SPEC 지시("transition .scale(0.6) spring")가 부분적으로만 충족.

---

## 기능 완성도

- 라운드 선택 (5/10회): `RoundSelectorView`로 동작. **통과**.
- 1.0~5.0초 랜덤 딜레이: `ReactionTestService.scheduleGreen` `Double.random(in: 1.0...5.0)`. **통과**.
- `CACurrentMediaTime` 기반 측정: View `.onTapGesture`에서 tapTime 기록 → ViewModel → actor `calculateMs(tapTime:)`. **통과**.
- 부정 탭 감지: waiting + countdown(0) → applyCheat. **통과**.
- 실격 라운드 카운트 제외: `applyCheat`에서 `validRoundCount` 증가 없음. **통과**.
- 통계: `TestSession.init`에서 `validAttempts.averageMs/bestMs/worstMs/cheatedCount/rounds` 계산. **통과**.
- 백분위: `StatisticsService.calculatePercentile` 선형 보간 구현. **통과**.
- 비교 데이터: 180/200/250ms 하드코딩. **통과**.
- 공유 placeholder: **통과**.
- 전 라운드 실격 방어: `ResultView.body`에서 `session.validAttempts.isEmpty` 분기로 `emptyResultView` 표시. **통과**.

**감점 1점**: `ResultViewModel.init`에서 `session.averageMs`가 0(전 라운드 실격)일 때도 `calculatePercentile(0)`을 호출. 100ms 이하 → 1% → `lightningGod` 등급이 계산된다. UI에서는 `emptyResultView`가 덮어쓰므로 사용자에게 노출되진 않지만, 불필요한 오작동/혼란 소지. `if session.validAttempts.isEmpty`를 init에서 선방어하고 percentile/grade를 옵셔널로 만드는 것이 안전.

---

## 코드 품질

- 접근 제어자 `private`/`private(set)`/`internal` 명시. **통과**.
- `ReactionError` enum 존재. **통과**.
- `TestState` / `AppPhase` enum (Bool 누적 금지) **통과**.
- 파일 구조 SPEC과 일치. **통과**.

### [확인] `RoundProgressView.dotColor` 반환 타입

**파일**: `output/Views/Test/TestComponents.swift:107-115`

```swift
private func dotColor(for index: Int) -> any ShapeStyle {
    if index < current {
        return palette.success
    } else if index == current {
        return palette.accent
    } else {
        return palette.surface
    }
}
```
호출부: `Circle().fill(dotColor(for: index))`

**문제**: `Shape.fill<S: ShapeStyle>(_ content: S, ...)`는 **concrete** `ShapeStyle`을 요구한다. `any ShapeStyle` existential은 `ShapeStyle` 프로토콜을 자체적으로 conform 하지 않으므로 `.fill(...)` 호출 시 컴파일 에러 가능성(Swift 5.9+ 일부 SE-0335 런타임 경로 제외). `AnyShapeStyle`을 래핑해서 반환해야 안전하다.

**수정 제안**: `-> AnyShapeStyle` 로 반환 타입을 바꾸고 `AnyShapeStyle(palette.success)` 형태로 감싼다. (`ResultView.ComparisonBarRow`에서는 이미 `AnyShapeStyle`을 사용했으므로 동일 패턴으로 통일.)

---

## SPEC 기능 매핑

| SPEC 기능 | 구현 위치 | 상태 |
|---|---|---|
| 홈 라운드 선택 | `HomeView.swift`, `RoundSelectorView.swift` | PASS |
| 카운트다운 3→2→1→GO | `TestViewModel.runRoundCycle`, `CountdownView` | PASS |
| waiting 1~5초 랜덤 | `ReactionTestService.scheduleGreen` | PASS |
| GO 팝 애니 | `TestView` `.green` goScale 1.15 spring | PASS |
| ms 기록 | `TestViewModel.applyValidRecord` | PASS |
| 부정 탭 감지 | `TestViewModel.handleTap` waiting/countdown(0) | PASS |
| 실격 재시도 | `TestViewModel.retryCurrentRound` | PASS |
| 실격 횟수 카운트 | `TestViewModel.cheatedCount` | PASS |
| 결과 평균/최고/최악 | `TestSession.init` | PASS |
| 백분위 선형 보간 | `StatisticsService.calculatePercentile` | PASS |
| 10개 등급 | `Grade` enum | PASS |
| 순차 공개 | `ResultViewModel.runRevealSequence` | PASS |
| 비교 차트 | `ResultView.comparisonCard` | PASS |
| 공유 placeholder | `ResultView.actionButtons` OutlineButton | PASS |
| 전 라운드 실격 방어 | `ResultView.emptyResultView` | PASS |
| AppPhase 기반 화면 전환 | `ReactionTimeCheckerApp`, `.designTheme(.airbnb)` | PASS |
| `TopDesignSystem` 사용 | 모든 View `@Environment(\.designPalette)` + `ss*` 폰트 | PASS |

---

## 구체적 개선 지시 (Generator 재실행 시 반드시 반영)

1. **[치명] `TestViewModel.deinit`의 MainActor 격리 위반 수정** (`output/ViewModels/Test/TestViewModel.swift:147-149`)
   - 현재 `deinit { currentTask?.cancel() }` 는 Swift 6에서 컴파일 에러.
   - 옵션 A: `currentTask`를 `nonisolated(unsafe) private var`로 선언해 nonisolated deinit에서 접근 가능하게 하고, 다른 접근점은 MainActor에서만 수정되도록 규약으로 유지.
   - 옵션 B: `deinit`에서 Task 취소를 포기하고, `TestView.onDisappear`에서 `viewModel.cancel()` 같은 명시적 훅을 호출하도록 변경. 이 방법이 Swift 6 정식 권장 패턴.
   - 옵션 C: Task 저장소를 별도 `actor` 박스(`final class CancelBox: @unchecked Sendable`)로 분리.
   - 어떤 옵션이든 **컴파일이 통과해야 함**. 재실행 시 `xcodebuild` 혹은 `swift build`로 Swift 6 컴파일 확인 필수.

2. **[치명] `ResultViewModel.deinit`의 MainActor 격리 위반 수정** (`output/ViewModels/Result/ResultViewModel.swift:80-82`)
   - 위와 동일한 패턴 적용. `revealTask`에 동일 방식 처리.

3. **[중요] `RoundProgressView.dotColor(for:)` 반환 타입 수정** (`output/Views/Test/TestComponents.swift:107-115`)
   - `any ShapeStyle`은 `.fill(...)`과 호환되지 않음. `AnyShapeStyle`로 감싸서 `-> AnyShapeStyle`로 변경:
     ```swift
     private func dotColor(for index: Int) -> AnyShapeStyle {
         if index < current { return AnyShapeStyle(palette.success) }
         else if index == current { return AnyShapeStyle(palette.accent) }
         else { return AnyShapeStyle(palette.surface) }
     }
     ```

4. **[중요] `ResultViewModel.init`에서 빈 세션 방어** (`output/ViewModels/Result/ResultViewModel.swift:33-39`)
   - `session.validAttempts.isEmpty`일 때 `calculatePercentile(0)` 호출을 건너뛰고 `percentile`/`grade`를 옵셔널 또는 sentinel 값으로 처리.
   - 현재는 UI가 가리지만, 로직 안전성 확보 차원.

5. **[경미] `ReactionTestService`의 불필요한 API 제거** (`output/Services/ReactionTestService.swift`)
   - `markGreen()`과 `randomDelay()`는 현재 호출되지 않음. Protocol에서 제거하거나, `scheduleGreen`의 책임을 명확화.

6. **[경미] `recorded` 상태 트랜지션 확실화** (`output/Views/Test/TestView.swift:146-160`)
   - `VStack` 자체에 `.id(ms)` 또는 외부 `.transition`을 래핑해 SPEC 4.3의 "scale 0.6 spring" 팝 애니메이션이 실제로 트리거되도록 개선.

7. **[경미] `waiting` 상태 진입 시 미세 햅틱 추가 제안** (`output/Views/Test/TestView.swift:203`)
   - `.onChange(of: state)` switch에 `.waiting` 분기 추가하여 `UIImpactFeedbackGenerator(.soft)` 정도의 예비 햅틱으로 긴장감 강화.

---

## 방향 판단

**현재 방향 유지** — 아키텍처와 설계는 SPEC에 부합하며, MVVM 레이어링, Phase 기반 전환, TopDesignSystem 적용 모두 양호하다. 치명적 결함 2건(동시성)과 컴파일 리스크 1건(`any ShapeStyle`)만 해결하면 합격 가능성이 높다.

재실행은 단계 2 Generator (피드백 반영 — **opus 모델**) 로 진행하고, 이후 단계 3 Evaluator 재검수로 넘어갈 것.
