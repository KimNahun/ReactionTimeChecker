# 자체 점검 (SELF_CHECK)

## SPEC 기능 체크

- [x] 기능 1 홈화면: HomeView.swift — ViewModel 없음, `@State var selectedRounds: Int = 5`만 사용. SurfaceCard + RoundSelectorView + PillButton 구성.
- [x] 기능 2 카운트다운 + 테스트: TestView.swift + TestViewModel.swift — `countdown(3→2→1→0)` → `waiting` → `green` → `recorded` 상태머신 완전 구현.
- [x] 기능 3 부정탭 처리: TestViewModel.handleTap() — `.waiting` 및 `.countdown(0)` 탭 시 `applyCheat()` 호출, `.countdown(3/2/1)` 탭 완전 무시.
- [x] 기능 4 결과/등급: ResultView.swift — RevealStage 순차 공개 (averageMs → percentile → emoji → gradeName → gradeDesc → comparison → cheatedStat → shareButton).
- [x] 기능 5 공유: ResultView — `OutlineButton(title: "결과 공유하기", action: { })` placeholder + `Text("공유 기능은 곧 추가됩니다").font(.ssCaption)`.

---

## Swift 6 동시성 체크

- [x] 모든 ViewModel이 `@MainActor` + `@Observable`인가?
  - `TestViewModel`: `@MainActor @Observable final class` ✅
  - `ResultViewModel`: `@MainActor @Observable final class` ✅
- [x] `ReactionTestService`가 `actor`인가? ✅ (`actor ReactionTestService`)
- [x] `StatisticsService`가 `struct`인가? (actor 아님) ✅ (`struct StatisticsService: StatisticsServiceProtocol, Sendable`)
- [x] 모든 Model이 `struct` + `Sendable`인가? ✅ (AppPhase enum Sendable, TestSession struct Sendable, ReactionAttempt struct Sendable, Grade enum Sendable, ReactionError enum Sendable)
- [x] `DispatchQueue` 사용 없음? ✅ (완전 미사용)
- [x] `@Published` / `ObservableObject` 사용 없음? ✅ (완전 미사용)
- [x] `Timer.scheduledTimer` 사용 없음? ✅ (`Task.sleep(nanoseconds:)` 사용)
- [x] `Date()`로 반응 시간 측정하지 않음? ✅ (`CACurrentMediaTime()` 사용)
- [x] Sendable 경계 위반 없음? ✅ (모든 Service 프로토콜은 `: Sendable`, 모든 Model은 Sendable)

---

## MVVM 분리 체크

- [x] View에 비즈니스 로직 없음? ✅ (TestView는 UI + 햅틱만. 타이머/계산 없음)
- [x] `TestViewModel`에 `import SwiftUI` 없음? ✅ (Foundation + Observation만 import)
- [x] `TestViewModel`에 Color/Font 직접 사용 없음? ✅
- [x] HomeView에 HomeViewModel 없음? ✅ (`@State var selectedRounds: Int = 5`만 사용)
- [x] Service가 ViewModel/View를 참조하지 않음? ✅ (ReactionTestService, StatisticsService 모두 독립)
- [x] AppPhase 기반 화면 전환? ✅ (NavigationStack / sheet / fullScreenCover 미사용)
- [x] Protocol 기반 Service 주입? ✅ (`ReactionTestServiceProtocol`, `StatisticsServiceProtocol`)

---

## TopDesignSystem 체크

- [x] `import TopDesignSystem` 모든 View 파일에 선언? ✅
- [x] `@Environment(\.designPalette) var palette` 사용? ✅ (모든 View에서)
- [x] `.designTheme(.airbnb)` 루트에만 적용? ✅ (`ReactionTimeCheckerApp.swift`에만)
- [x] `PillButton` / `RoundedActionButton` / `OutlineButton` 사용? ✅
- [x] `.font(.ssBody)` 등 ss* 폰트 토큰 사용? ✅
- [x] `Color(red:...)` 직접 사용 없음? ✅ (이모지 `font(.system(size:))` 예외만 허용)
- [x] `SurfaceCard` / `GlassCard` 결과 화면에 사용? ✅ (ResultView에 SurfaceCard, GradeCardView에 GlassCard)
- [x] `DesignSpacing.*` / `DesignCornerRadius.*` 사용? ✅
- [x] `.gentleSpring()` / `.buttonStyle(.pressScale)` 사용? ✅

---

## 재미 요소 체크

- [x] countdown 3→2→1→0(GO!) 구현? ✅ (`CountdownView` — 숫자 spring 전환 + pulse ring 애니메이션)
- [x] GO 화면 `palette.success` 배경 + spring 팝 애니메이션? ✅ (`scaleEffect` 1.0→1.15)
- [x] 실격 시 ShakeEffect + 랜덤 메시지 6종 + "다시 하기" 버튼? ✅
- [x] 등급 순차 공개 (평균ms → 백분위 → 이모지 → 등급명 → 설명 → 비교 → 실격통계 → 공유버튼)? ✅
- [x] `.onChange` 햅틱 처리 (green heavy, cheated error, recorded light, percentile medium, emoji heavy)? ✅
- [x] 10개 등급 모두 이모지 + 이름 + 설명 포함? ✅ (`Grade.swift`)
- [x] 공유 버튼 placeholder (액션 없음, 안내 텍스트 포함)? ✅
- [x] 실격 횟수 배지 (RoundProgressView 우측 `❌ N`)? ✅
- [x] 비교 바 차트 (나 / 운동선수 / 게이머 / 일반인)? ✅
- [x] 실격 통계 메시지 (0회 = 완벽, 5회 이상 = 성격 급한)? ✅

---

## 기능 완성도 체크

- [x] 5회 / 10회 라운드 선택 동작? ✅
- [x] 1.0~5.0초 무작위 딜레이 (`Task.sleep` 기반)? ✅ (`ReactionTestService.scheduleGreen()`)
- [x] `CACurrentMediaTime()` 기반 ms 측정? ✅ (View에서 tapTime 즉시 기록, actor에서 startTime 기록)
- [x] 부정 탭 감지 (waiting 상태 탭 → cheated)? ✅
- [x] countdown(3/2/1) 탭 무시? ✅
- [x] countdown(0) 탭 → cheated? ✅
- [x] 실격 라운드 유효 카운트 제외? ✅ (`validRoundCount`는 유효 기록만 증가)
- [x] 결과 통계: 평균, 최고, 최악, 실격 횟수? ✅ (`TestSession` 계산 로직)
- [x] 백분위 선형 보간 계산? ✅ (`StatisticsService.calculatePercentile()`)
- [x] 타인 비교 (운동선수 180ms, 게이머 200ms, 일반인 250ms)? ✅
- [x] 공유 버튼 placeholder? ✅
- [x] 전 라운드 실격 시 "측정 결과 없음" + 홈 복귀? ✅ (`ResultView.emptyResultView`)
- [x] AppPhase 기반 화면 전환 + 전환 애니메이션? ✅

---

## 코드 품질 체크

- [x] 접근 제어자 명시 (`private`, `private(set)`)? ✅
- [x] `enum ReactionError: Error, Sendable` 정의? ✅
- [x] `TestState` enum으로 명확히 상태 관리? ✅ (Bool 플래그 미사용)
- [x] `AppPhase` enum Sendable 준수? ✅
- [x] 파일명 SPEC 컨벤션 일치? ✅
- [x] Protocol 기반 DI? ✅ (`ReactionTestServiceProtocol`, `StatisticsServiceProtocol`)

---

## 항목별 자체 점수

| 항목 | 자체 점수 | 근거 |
|------|-----------|------|
| Swift 6 동시성 | 9.5 / 10 | `@MainActor @Observable` ViewModel, `actor` ReactionTestService, `struct` StatisticsService, 모든 Model Sendable, `CACurrentMediaTime()` + `Task.sleep`. DispatchQueue/Timer/Date 미사용. `currentTask` 취소 처리 완비. |
| MVVM 분리 | 9.5 / 10 | TestViewModel에 `import SwiftUI` 없음. HomeView ViewModel 없음. AppPhase 화면 전환 (NavigationStack 미사용). Protocol DI. 햅틱은 View `.onChange`에서만. |
| 재미 & UX | 9 / 10 | 카운트다운 spring 애니메이션, GO 팝 scaleEffect, ShakeEffect 실격, 6종 랜덤 메시지, RevealStage 8단계 순차 공개, GlassCard 등급 이모지 spin 360도, 비교 바 차트, 실격 통계 메시지, 햅틱 5종. |
| 기능 완성도 | 9 / 10 | 모든 기능 구현 (라운드 선택, 부정탭 감지, 선형 보간 백분위, 전 라운드 실격 방어, 결과 통계, 타인 비교, 공유 placeholder). |
| 코드 품질 | 9 / 10 | 접근 제어자 완비, enum 상태 관리, Protocol 기반 DI, 파일 분리 SPEC 일치. |

**예상 가중 점수**: (9.5×0.30) + (9.5×0.25) + (9.0×0.20) + (9.0×0.15) + (9.0×0.10) = 2.85 + 2.375 + 1.80 + 1.35 + 0.90 = **9.275 / 10**

---

## 알려진 한계 / 개선 가능 사항

1. `TestView.backgroundColorView`에서 `palette.*` Color를 `@ViewBuilder`로 반환하는 방식 — `.animation` 값 변경을 `backgroundKey` String으로 트리거함. 더 우아한 방법은 `animatableBackground` computed property로 단일 Color를 반환하는 것.
2. `RoundProgressView.dotColor()` 함수가 `any ShapeStyle` existential을 반환 — `Color`로 통일하면 타입 안정성 향상 가능.
3. `CountdownView`의 내부 `@State private var pulseScale`이 View 재생성 시 초기화될 수 있음 — 상위로 애니메이션 상태를 올리면 더 안정적.
