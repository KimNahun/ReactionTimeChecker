# 평가 기준표

Generator와 Evaluator가 공유하는 Swift 코드 품질 기준.
이 앱의 핵심은 **"재미"**이므로 재미 & UX 항목 비중이 높다.

---

## 채점 항목

### 1. Swift 6 동시성 (비중: 30%)

Swift 6의 엄격한 동시성 모델을 올바르게 적용했는가?

**합격 기준:**
- 모든 ViewModel: `@MainActor` + `@Observable` 선언
- 가변 상태가 있는 Service (`ReactionTestService`): `actor` 선언
- 순수 계산 Service (`StatisticsService`): `struct` 선언 (actor 불필요)
- 모든 Model: `struct` + `Sendable` 준수
- `DispatchQueue`, `@Published`, `ObservableObject` 미사용
- `Timer.scheduledTimer` 미사용 → `Task.sleep(nanoseconds:)` 사용
- `Date()`로 반응 시간 측정 금지 → `CACurrentMediaTime()` 사용
- Sendable 경계 위반 없음

**불합격 기준:**
- ViewModel이 `@MainActor` 없음
- `ReactionTestService`가 일반 `class`로 구현
- `StatisticsService`가 `actor`로 구현 (가변 상태 없는데 actor 강제 → 불필요한 격리)
- `DispatchQueue.main.async` 사용
- `@Published` + `ObservableObject` 패턴 사용 (구버전)
- `Timer.scheduledTimer` 사용
- `Date()`로 반응 시간 측정 (actor hop 지연 오차)
- Non-Sendable 타입을 actor 경계 넘어 전달

---

### 2. MVVM 아키텍처 분리 (비중: 25%)

레이어 간 관심사가 명확히 분리되어 있는가?

**합격 기준:**
- `HomeView`: ViewModel 없음, `@State var selectedRounds: Int`만 사용
- `TestView`: 순수 UI 선언, 타이머/계산 로직 없음
- `TestViewModel`: UI 상태 소유, `import SwiftUI` 없음, `Color`/`Font` 없음
- Service: 비즈니스 로직만, ViewModel/View 참조 없음
- 의존성 단방향 흐름: View → ViewModel → Service
- AppPhase 기반 화면 전환 (NavigationStack/sheet/fullScreenCover 없음)
- Protocol 기반 Service 주입

**불합격 기준:**
- `HomeViewModel.swift` 파일이 존재함 (과설계 — 실질 역할 없는 빈 ViewModel)
- `TestView`에서 타이머 직접 실행 또는 통계 계산
- `TestViewModel`에 `import SwiftUI` 또는 UI 타입 직접 사용
- Service에서 ViewModel 콜백 또는 참조
- `NavigationStack`, `sheet`, `fullScreenCover` 사용 (AppPhase 방식 미준수)
- 역방향 의존성 존재

---

### 3. 재미 & UX (비중: 20%)

이 앱의 핵심 가치인 "재미"가 코드로 구현되어 있는가?
단순 기능 동작 여부가 아니라 **경험의 질**을 평가한다.

**합격 기준:**
- **카운트다운**: 3→2→1 시각적으로 구현, 이 단계에서 탭 무시
- **GO 화면**: `palette.success` 배경 + 팝하는 spring animation
- **실격 처리**: 흔들기 animation + error 햅틱 + 랜덤 재미있는 메시지 (최소 3종) + "다시 하기" 버튼
- **재시도 로직**: 실격 후 같은 라운드 카운트다운부터 재시작
- **등급 공개**: 순차 공개 (평균ms → 백분위 → 이모지 → 등급명) 딜레이+애니메이션
- **햅틱**: `.onChange`로 처리 — green(success), cheated(error), recorded(light), grade reveal(heavy)
- **10개 등급**: 이름 + 이모지 + 한 줄 설명 모두 포함
- **공유 버튼**: placeholder 처리 (OutlineButton, 액션 없음, 안내 텍스트 포함)

**불합격 기준:**
- 카운트다운 없이 바로 waiting 상태로 진입
- 애니메이션 없이 상태 전환 (즉시 색상 변경)
- 실격 후 "다시 하기" 버튼 없음
- 실격 메시지 단조롭거나 1종만 있음
- 등급 화면 즉시 표시 (순차 공개 없음)
- 햅틱 없음, 또는 ViewModel에서 직접 UIKit 햅틱 호출 (MVVM 위반)
- 등급 설명이 성의 없음 ("빠름", "느림" 같은 단순 표현)
- 공유 버튼 없음, 또는 실제 공유 로직을 구현하려다 미완성 (placeholder가 더 나음)

---

### 4. 기능 완성도 (비중: 15%)

반응속도 테스트의 모든 기능이 올바르게 구현되었는가?

**합격 기준:**
- 5회 / 10회 라운드 선택 동작
- 1.0~5.0초 무작위 딜레이 (`Task.sleep` 기반)
- `CACurrentMediaTime()` 기반 ms 측정 (정밀도 보장)
- 부정 탭 감지 (waiting/countdown 상태에서 탭 → cheated)
- 실격 라운드 카운트 제외 (N회 유효 기록 완료 후 결과로 이동)
- 결과 통계: 평균, 최고, 최악 (유효 시도만), 총 실격 횟수
- 백분위 선형 보간 계산 (StatisticsService)
- 타인 비교 데이터 표시 (일반인 250ms, 게이머 200ms, 운동선수 180ms)
- 공유 버튼 placeholder (OutlineButton, 액션 없음)
- 전 라운드 실격 시 "측정 결과 없음" 화면 + 재도전 버튼

**불합격 기준:**
- 라운드 선택 동작 안 함
- ms 측정 부정확 (초 단위 또는 0ms)
- 부정 탭 감지 없음
- 실격 시 다음 라운드로 그냥 넘어감 ("다시 하기" 버튼 없음)
- 결과 화면에서 통계 없음
- 전 라운드 실격 케이스 처리 없음

---

### 5. 코드 품질 (비중: 10%)

코드가 읽기 쉽고 Swift 관습을 따르는가?

**합격 기준:**
- 접근 제어자 명시 (`private`, `private(set)`, `internal`)
- 에러 타입이 `enum ReactionError: Error, Sendable`로 정의
- `TestState` enum 명확히 정의 (Bool 여러 개로 관리하지 않음)
- `AppPhase` enum Sendable 준수
- 파일명이 SPEC 컨벤션 일치
- 코드 중복 최소화

**불합격 기준:**
- 접근 제어자 없음 (모두 기본값)
- 에러를 `print()` 만으로 처리
- 상태를 Bool 여러 개로 관리 (`isWaiting`, `isGreen` 등 — enum 미사용)
- 파일 하나에 모든 코드 뭉쳐있음

---

## 판정

```
가중 점수 = (동시성×0.30) + (MVVM×0.25) + (재미UX×0.20) + (기능성×0.15) + (코드품질×0.10)
```

- **7.0 이상** → 합격
- **5.0 ~ 6.9** → 조건부 합격 (피드백 반영 후 재검수)
- **5.0 미만** → 불합격
- **동시성 또는 MVVM 항목 4점 이하** → 무조건 불합격
- **재미 & UX 항목 3점 이하** → 무조건 조건부 합격 이하 (이 앱의 핵심 가치이므로)

---

## 피드백 형식

```
**전체 판정**: [합격 / 조건부 합격 / 불합격]
**가중 점수**: X.X / 10.0

**항목별 점수**:
- Swift 6 동시성: X/10 — [한 줄 코멘트 + 핵심 증거]
- MVVM 분리: X/10 — [한 줄 코멘트 + 핵심 증거]
- 재미 & UX: X/10 — [한 줄 코멘트 + 핵심 증거]
- 기능 완성도: X/10 — [한 줄 코멘트 + 핵심 증거]
- 코드 품질: X/10 — [한 줄 코멘트 + 핵심 증거]

**구체적 개선 지시**:
1. [파일명] [함수/타입명]: [무엇을 어떻게 수정할 것]
2. [파일명] [함수/타입명]: [무엇을 어떻게 수정할 것]
...

**방향 판단**: [현재 방향 유지] 또는 [아키텍처 재설계]
```
