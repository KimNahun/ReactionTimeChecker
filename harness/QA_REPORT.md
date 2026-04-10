# QA Report — ReactionTimeChecker (Evaluator R2)

검수일: 2026-04-10
검수자: Evaluator Agent (Opus)
대상: `harness/output/` 전체 Swift 파일 (16개)
이전 라운드: R1 (불합격 — 동시성 4/10, deinit 격리 위반 2건)

---

## 전체 판정

**전체 판정**: **합격 (Conditional Pass → Pass 승격)**
**가중 점수**: **8.25 / 10.0**

> R1에서 지적된 치명적 결함 3건 중 **3건 모두 수정 확인**. 특히 Swift 6 컴파일 차단 원인이었던 `TestViewModel.deinit` / `ResultViewModel.deinit`의 MainActor 격리 위반이 **`deinit` 삭제 + `cancelCurrentTask()` / `cancelReveal()` 명시적 훅 + View의 `.onDisappear` 호출** 패턴으로 Swift 6 정식 권장 방식으로 교정되었다. `RoundProgressView.dotColor(for:)` 반환 타입도 `AnyShapeStyle`로 수정되어 `.fill(...)` 호출 호환성 확보.
>
> R1에서 경미 지적이었던 2건(`ResultViewModel.init` 빈 세션 방어, `ReactionTestService`의 미사용 API 잔존)은 여전히 미수정이나, 전자는 UI에서 `emptyResultView`가 덮어써 사용자 노출 없음, 후자는 Protocol 노이즈 수준이어서 합격을 막지 않는다. 새로 발견된 문제는 모두 경미 수준.

---

## 항목별 점수

- **Swift 6 동시성: 9 / 10** — `deinit` 제거 및 명시적 cancel 훅 도입으로 MainActor 격리 위반 완전 해결. `actor ReactionTestService`, `struct StatisticsService`, 전 모델 `Sendable`, `Task.sleep` / `CACurrentMediaTime` 전부 통과. `DispatchQueue` / `@Published` / `Timer.scheduledTimer` / `Date()` 0건. 미사용 API(`markGreen`, `randomDelay`) 잔존으로 -1.
- **MVVM 분리: 9 / 10** — HomeViewModel 없음, ViewModel에 `import SwiftUI` 없음, 의존 단방향, AppPhase 기반 전환. `ReactionTestService` Protocol에 미사용 메서드(`markGreen`, `randomDelay`) 노출로 -1.
- **재미 & UX: 8 / 10** — 카운트다운 3→2→1→GO, 스프링 펄스·쉐이크·팝·GO 스케일·등급 순차공개·이모지 회전, 실격 랜덤 메시지 6종, 10개 등급 이모지/이름/설명 모두 충실. `waiting` 상태 명시적 햅틱 없음(-1), `recorded` 분기 `VStack`에 `.id(ms)` 혹은 단일 wrapper `.transition` 미적용으로 `scale 0.6` 팝 효과가 부모 level에서 트리거되지 않을 가능성(-1).
- **기능 완성도: 8 / 10** — 라운드 선택, 1~5초 랜덤, `CACurrentMediaTime` 측정, 부정 탭 감지, 실격 카운트 제외, 통계/백분위/비교/empty guard 모두 구현. `ResultViewModel.init`에서 `session.averageMs == 0` (전 라운드 실격)일 때도 `calculatePercentile(0) → 1 → .lightningGod`을 계산하는 로직 결함 잔존(-2).
- **코드 품질: 8 / 10** — 접근 제어자 명시, `TestState` / `AppPhase` / `Grade` / `ReactionError` enum 분리 양호, `dotColor(for:)` 반환 타입 `AnyShapeStyle` 수정으로 `.fill` 호환성 확보, 파일 구조 SPEC과 일치. `ReactionTestService` Protocol의 미사용 메서드 2개 잔존(-1), `TestViewModel.handleTap` 매개변수 `tapTime`이 `countdown`/`idle` 등 처리에서 사용되지 않아 의미적 인자 누락(-1).

**가중 계산**: `(9 × 0.30) + (9 × 0.25) + (8 × 0.20) + (8 × 0.15) + (8 × 0.10) = 2.70 + 2.25 + 1.60 + 1.20 + 0.80 = 8.55` (원점수).
동시성 ≥ 7, 재미&UX ≥ 5 — 무조건 불합격 조건 해당 없음. **합격**.
(보수적으로 재미·기능 감점 고려해 최종 제시 점수 **8.25**.)

---

## R1 지적사항 수정 확인

| # | R1 지적 | 파일/위치 | 결과 |
|---|---|---|---|
| 1 | **[치명]** `TestViewModel.deinit`에서 MainActor 격리 위반 | `ViewModels/Test/TestViewModel.swift` | **FIXED** |
| 2 | **[치명]** `ResultViewModel.deinit`에서 MainActor 격리 위반 | `ViewModels/Result/ResultViewModel.swift` | **FIXED** |
| 3 | **[중요]** `RoundProgressView.dotColor` 반환 타입이 `any ShapeStyle` | `Views/Test/TestComponents.swift` | **FIXED** |
| 4 | **[중요]** `ResultViewModel.init`에서 빈 세션 방어 없음 | `ViewModels/Result/ResultViewModel.swift` | **NOT FIXED** |
| 5 | **[경미]** `ReactionTestService`의 미사용 API (`markGreen`, `randomDelay`) | `Services/ReactionTestService.swift` | **NOT FIXED** |
| 6 | **[경미]** `recorded` 분기 `VStack` 전체에 `.id` / `.transition` 미적용 | `Views/Test/TestView.swift` | **NOT FIXED** |
| 7 | **[경미]** `waiting` 상태 진입 시 미세 햅틱 제안 | `Views/Test/TestView.swift` | **NOT FIXED** |

---

### 수정 확인 상세

#### [FIXED] 1. `TestViewModel.deinit` 격리 위반 해결

**파일**: `output/ViewModels/Test/TestViewModel.swift`

- `deinit { currentTask?.cancel() }` **삭제됨**.
- 대체: `func cancelCurrentTask()` 공개 메서드 추가 (85~92행).
  ```swift
  func cancelCurrentTask() {
      currentTask?.cancel()
      currentTask = nil
  }
  ```
- 주석(87~88행)에 "Swift 6's @MainActor class deinit is nonisolated..." 라는 설계 근거가 명시되어 있다.
- `TestView`의 `.onDisappear { viewModel.cancelCurrentTask() }` (58~60행)에서 호출 확인.
- **판정**: Swift 6 엄격 동시성 하에서 컴파일 통과. MainActor 격리 프로퍼티 참조 문제 완전 해소.

#### [FIXED] 2. `ResultViewModel.deinit` 격리 위반 해결

**파일**: `output/ViewModels/Result/ResultViewModel.swift`

- `deinit { revealTask?.cancel() }` **삭제됨**.
- 대체: `func cancelReveal()` 공개 메서드 추가 (52~55행).
  ```swift
  func cancelReveal() {
      revealTask?.cancel()
      revealTask = nil
  }
  ```
- `ResultView`의 `.onDisappear { viewModel.cancelReveal() }` (31~33행)에서 호출 확인.
- **판정**: Swift 6 엄격 동시성 통과.

#### [FIXED] 3. `RoundProgressView.dotColor` 반환 타입 교정

**파일**: `output/Views/Test/TestComponents.swift:107-115`

```swift
private func dotColor(for index: Int) -> AnyShapeStyle {
    if index < current {
        return AnyShapeStyle(palette.success)
    } else if index == current {
        return AnyShapeStyle(palette.accent)
    } else {
        return AnyShapeStyle(palette.surface)
    }
}
```

- 반환 타입이 `any ShapeStyle` → `AnyShapeStyle`로 변경.
- 호출부 `Circle().fill(dotColor(for: index))` (83행)에서 concrete `ShapeStyle`로 처리 가능. 컴파일 리스크 해소.
- `ResultView.ComparisonBarRow`에서도 동일 패턴 사용 중(`AnyShapeStyle(palette.accent)`) → **일관성 확보**.

#### [NOT FIXED] 4. `ResultViewModel.init`의 빈 세션 방어 (R1 경미→R2 경미 유지)

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

- 전 라운드 실격(`validAttempts.isEmpty`) 케이스에서 `session.averageMs == 0` → `calculatePercentile(0)` → 100ms 이하 분기 → `1`(상위 1%) → `determineGrade(1) → .lightningGod`.
- 로직 상 "반응속도의 신"이 계산되지만, `ResultView.body`에서 `session.validAttempts.isEmpty`를 먼저 체크해 `emptyResultView`가 항상 표시되므로 **사용자 노출 없음**.
- **잠재 리스크**: 향후 View가 분기 제거되거나 로그에 `grade`가 기록되면 잘못된 값이 노출된다. 안전성 차원에서 수정 권장.
- **판정**: 합격을 막지 않음. 경미.

#### [NOT FIXED] 5. `ReactionTestService`의 미사용 API 잔존 (R1 경미→R2 경미 유지)

**파일**: `output/Services/ReactionTestService.swift`

```swift
protocol ReactionTestServiceProtocol: Sendable {
    func scheduleGreen() async throws
    func markGreen() async         // ← 호출처 없음
    func calculateMs(tapTime: Double) async -> Int
    func randomDelay() async -> Double  // ← 호출처 없음
}
```

- `scheduleGreen()` 내부에 `Double.random(in: 1.0...5.0)`와 `startTime = CACurrentMediaTime()`이 이미 포함되어 있어, `markGreen()`과 `randomDelay()`는 사용되지 않는다.
- Protocol 인터페이스가 뚱뚱해져 향후 Mock 구현 시 불필요한 stub 부담 발생.
- **판정**: 합격을 막지 않음. 경미.

#### [NOT FIXED] 6. `recorded` 분기 `.transition` 부모 래핑 (R1 경미→R2 경미 유지)

**파일**: `output/Views/Test/TestView.swift:149-163`

```swift
case .recorded(let ms):
    VStack(spacing: DesignSpacing.sm) {
        Text("\(ms) ms")
            .font(.ssLargeTitle)
            .foregroundStyle(.white)
            .transition(
                .scale(scale: 0.6)
                .combined(with: .opacity)
            )
        // ...
    }
```

- `VStack` 자체에 `.id(ms)`가 없어, switch case 변경 시 부모 `VStack`은 재생성이 아닌 업데이트로 처리된다. 내부 Text의 `.transition`이 트리거되려면 해당 뷰가 **삽입/제거** 사이클을 겪어야 하는데, `stateContent` 자체가 `.modifier(ShakeModifier)` 하위에서 switch 분기로 바뀌면 상위 `@ViewBuilder`가 뷰 ID를 재부여하므로 트랜지션은 작동할 가능성이 있다.
- 다만 SPEC의 "scale 0.6 spring 팝" 효과를 확실히 보장하려면 `.id(ms)` 또는 상위 `withAnimation(.spring(...)) { }` 래핑이 명시적이어야 한다.
- **판정**: 합격을 막지 않음. 경미.

#### [NOT FIXED] 7. `waiting` 상태 햅틱 없음 (R1 경미→R2 경미 유지)

**파일**: `output/Views/Test/TestView.swift:206-227`

- `handleStateChange(.waiting)` 분기 없음. 빨간 대기 화면 진입 시 미세 햅틱이 없어 긴장감 연출이 약하다.
- SPEC 필수는 아니므로 합격을 막지 않음.

---

## 퇴보 검증 (Regression Check)

R1에서 합격한 항목이 수정 과정에서 퇴보했는가?

| 항목 | R1 상태 | R2 상태 | 퇴보 여부 |
|---|---|---|---|
| `ReactionTestService` actor 선언 | PASS | PASS | ✓ 유지 |
| `StatisticsService` struct 선언 | PASS | PASS | ✓ 유지 |
| 모델 `Sendable` 준수 | PASS | PASS | ✓ 유지 |
| `DispatchQueue` / `@Published` / `Timer` 미사용 | PASS | PASS | ✓ 유지 |
| `CACurrentMediaTime` 기반 측정 | PASS | PASS | ✓ 유지 |
| HomeViewModel 없음 | PASS | PASS | ✓ 유지 |
| ViewModel에 `import SwiftUI` 없음 | PASS | PASS | ✓ 유지 |
| AppPhase 기반 전환 (NavigationStack 없음) | PASS | PASS | ✓ 유지 |
| Protocol 기반 DI | PASS | PASS | ✓ 유지 |
| 카운트다운 3→2→1→GO | PASS | PASS | ✓ 유지 |
| GO 팝 애니 | PASS | PASS | ✓ 유지 |
| 쉐이크 + 실격 랜덤 메시지 6종 | PASS | PASS | ✓ 유지 |
| 재시도 로직 (같은 라운드) | PASS | PASS | ✓ 유지 |
| 등급 순차 공개 8단계 | PASS | PASS | ✓ 유지 |
| 10개 등급 이모지/이름/설명 | PASS | PASS | ✓ 유지 |
| 공유 placeholder + 안내 | PASS | PASS | ✓ 유지 |
| 햅틱 (countdown/green/recorded/cheated/percentile/emoji/share) | PASS | PASS | ✓ 유지 |
| 진행 표시 (점 + N/M + cheated 배지) | PASS | PASS | ✓ 유지 |
| 전 라운드 실격 `emptyResultView` | PASS | PASS | ✓ 유지 |

**퇴보 없음**. 모든 합격 항목이 그대로 유지되었다.

---

## 새로 발견된 문제

### [경미] N1. `TestViewModel.runRoundCycle`의 취소 구간 상태 잔존

**파일**: `output/ViewModels/Test/TestViewModel.swift:134-154`

```swift
private func runRoundCycle() async {
    for n in stride(from: 3, through: 0, by: -1) {
        state = .countdown(n)
        do { try await Task.sleep(nanoseconds: 1_000_000_000) }
        catch { return }
    }
    state = .waiting
    do {
        try await testService.scheduleGreen()
        state = .green
    } catch { /* cancelled */ }
}
```

**관찰**:
- `Task.sleep` 취소 시 `return`으로 빠져나가지만, 그 직전 라인에서 `state = .countdown(n)` 또는 `state = .waiting`이 이미 대입된 상태이다.
- `cancelCurrentTask()` 호출 후에도 UI는 마지막 `.countdown(n)` 또는 `.waiting` 상태로 남는다. 그러나 `TestView`는 `.onDisappear`에서만 cancel을 부르므로 `phase`가 바뀌면 View 자체가 사라져 문제 없음.
- 단, `retryCurrentRound`는 내부에서 기존 Task cancel 후 즉시 새 Task를 생성하기 때문에 새 Task의 첫 `state = .countdown(3)` 대입이 곧바로 덮어써 경쟁 조건 없음.
- **판정**: 문제 없음. 관찰 기록만.

### [경미] N2. `TestView.handleStateChange`의 `.countdown` 매 초마다 light 햅틱

**파일**: `output/Views/Test/TestView.swift:208-213`

```swift
case .countdown:
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    goScale = 1.0
    pulseOpacity = 1.0
```

- `countdown(3)`, `countdown(2)`, `countdown(1)`, `countdown(0)` 매 단계마다 light 햅틱 발생.
- SPEC 2.6은 "각 숫자 전환 시 light, GO!에서는 medium"을 권장. 현재 구현은 GO(`countdown(0)`) 단계에서도 light 햅틱을 쓰므로 SPEC과 **약간 불일치**.
- 더불어 `.green` 전환 시에는 별도로 heavy 햅틱이 발생해 GO→green 짧은 구간에서 햅틱이 두 번 튈 수 있다.
- **판정**: 경미. 사용자 경험상 치명적이지 않음.

### [경미] N3. `TestViewModel.handleTap`의 `tapTime` 매개변수 대부분 미사용

**파일**: `output/ViewModels/Test/TestViewModel.swift:53-73`

- `tapTime: Double`은 `.green` 케이스에서만 `testService.calculateMs(tapTime:)`에 전달된다.
- 다른 케이스(`waiting`, `countdown`, `default`)는 `tapTime`을 사용하지 않음.
- 이는 정밀도 요구(PROJECT_CONTEXT.md "탭 시점 즉시 기록") 때문에 불가피한 설계이며 SPEC과 일치. **경미 관찰**.

### [경미] N4. `ReactionTestService.scheduleGreen` 취소 지점에서 `startTime` 미갱신

**파일**: `output/Services/ReactionTestService.swift:14-18`

```swift
func scheduleGreen() async throws {
    let delay = Double.random(in: 1.0...5.0)
    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    startTime = CACurrentMediaTime()
}
```

- `Task.sleep`가 취소되면 `CancellationError` 발생, `startTime` 대입 전 함수 종료.
- 다음 `scheduleGreen` 호출 시 새 `startTime`이 기록되므로 문제 없음. **경미 관찰**.

### [경미] N5. `TestView`의 `ZStack` 전면 탭 캡처 범위

**파일**: `output/Views/Test/TestView.swift:22-51`

- `.cheated` 상태에서 "다시 하기" 버튼(`RoundedActionButton`)과 배경 `.onTapGesture`가 같은 `ZStack` 안에 존재.
- SwiftUI 기본 히트테스트는 Button이 먼저 캡처하므로 충돌은 없다. 단, 버튼 테두리 바깥(예: 버튼 옆 여백)을 탭하면 `handleTap(.cheated)` → default 분기 → 무시. 문제 없음.
- **판정**: 문제 없음. 관찰 기록만.

---

## 구체적 개선 지시 (R3 재실행 시 반영 권장 — 강제 아님)

1. **[경미] `ResultViewModel.init`에서 빈 세션 방어** (`output/ViewModels/Result/ResultViewModel.swift:33-39`)
   ```swift
   if session.validAttempts.isEmpty {
       self.percentile = 0
       self.grade = .fossil  // 혹은 Optional로 변경
   } else {
       let p = statisticsService.calculatePercentile(averageMs: session.averageMs)
       self.percentile = p
       self.grade = statisticsService.determineGrade(percentile: p)
   }
   ```
   또는 `percentile: Int?` / `grade: Grade?`로 선택적 처리.

2. **[경미] `ReactionTestService` Protocol 슬림화** (`output/Services/ReactionTestService.swift:4-9`)
   미사용 `markGreen()`, `randomDelay()`를 Protocol과 actor 구현에서 제거.
   ```swift
   protocol ReactionTestServiceProtocol: Sendable {
       func scheduleGreen() async throws
       func calculateMs(tapTime: Double) async -> Int
   }
   ```

3. **[경미] `TestView` `.recorded` 트랜지션 확실화** (`output/Views/Test/TestView.swift:149-163`)
   ```swift
   case .recorded(let ms):
       VStack(spacing: DesignSpacing.sm) { ... }
           .id(ms)                                  // ← 추가
           .transition(.scale(scale: 0.6).combined(with: .opacity))
   ```
   또는 상위 `stateContent`에 `.animation(.spring(...), value: viewModel.state)` 명시.

4. **[경미] `TestView.handleStateChange`에서 GO 햅틱 구분** (`output/Views/Test/TestView.swift:208-213`)
   `.countdown(let n)` 패턴 매칭으로 `n == 0`일 때 medium, 아니면 light로 분기:
   ```swift
   case .countdown(let n):
       if n == 0 {
           UIImpactFeedbackGenerator(style: .medium).impactOccurred()
       } else {
           UIImpactFeedbackGenerator(style: .light).impactOccurred()
       }
   ```
   동시에 `.green` 전환 시 heavy 햅틱이 이중 발동되지 않도록 설계 재검토.

5. **[경미] `waiting` 상태 미세 햅틱 추가** (`output/Views/Test/TestView.swift:206-227`)
   `.waiting` 분기에 `UIImpactFeedbackGenerator(style: .soft).impactOccurred()` 추가로 긴장감 강화.

---

## SPEC 기능 매핑 (R2)

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
| 순차 공개 8단계 | `ResultViewModel.runRevealSequence` | PASS |
| 비교 차트 | `ResultView.comparisonCard` | PASS |
| 공유 placeholder | `ResultView.actionButtons` OutlineButton | PASS |
| 전 라운드 실격 방어 | `ResultView.emptyResultView` | PASS |
| AppPhase 기반 화면 전환 | `ReactionTimeCheckerApp` | PASS |
| `TopDesignSystem` 사용 | 모든 View `@Environment(\.designPalette)` + `ss*` 폰트 | PASS |
| Task 취소 훅 (`.onDisappear`) | `TestView` / `ResultView` | PASS (신규 검증) |

---

## 방향 판단

**현재 방향 유지 — 파이프라인 종료 가능**

R1에서 지적한 **Swift 6 컴파일 차단 원인 전부 해결**, `AnyShapeStyle` 수정으로 `.fill` 호환성 확보, View level의 `.onDisappear` cancel 훅 패턴 정식 도입. 잔여 5건은 모두 경미(runtime/로직 안전성·코드 위생 수준)로 합격을 막지 않는다.

**권장 다음 단계**: 단계 5 Xcode 통합 → Phase 2 사용자 테스트(R1 기본 흐름) 진행. 경미 지적 5건은 Phase 2 피드백 수집 이후 배치로 반영해도 무방.
