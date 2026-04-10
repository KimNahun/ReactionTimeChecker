# Swift 하네스 엔지니어링 오케스트레이터

이 프로젝트는 3-Agent 하네스 구조로 동작합니다.
사용자의 한 줄 프롬프트를 받아, **Planner → Generator → Evaluator** 파이프라인을 자동 실행합니다.

**타겟**: Swift 6 + SwiftUI 100% + MVVM + 엄격한 동시성 + 재미 중심 UX

---

## 작업 진행 현황 (다른 AI가 이어받을 때 여기서부터 확인)

> **마지막 업데이트**: 초기화
> **현재 상태**: ⬜ 파이프라인 미시작

### 전체 작업 목록

| # | 단계 | 설명 | 상태 |
|---|------|------|------|
| 1 | Planner | SPEC.md 생성 | ⬜ 대기 |
| 2 | Generator R1 | output/ Swift 파일 생성 | ⬜ 대기 |
| 3 | Evaluator R1 | QA_REPORT.md 생성 | ⬜ 대기 |
| 4 | 판정 확인 + 반복 | 합격 or 피드백 반영 | ⬜ 대기 |
| 5 | Xcode 통합 | output/ → ReactionTimeChecker/ 동기화 | ⬜ 대기 |

---

## 각 단계 완료 시 커밋 규칙

**각 단계를 완료할 때마다 반드시 git commit을 실행한다.**

```bash
# 단계 1 완료 시
git add harness/SPEC.md
git commit -m "harness: [단계1] Planner SPEC.md 생성 완료"

# 단계 2 완료 시 (Generator)
git add harness/output/ harness/SELF_CHECK.md
git commit -m "harness: [단계2] Generator R{N} - Swift 파일 생성 완료"

# 단계 3 완료 시 (Evaluator)
git add harness/QA_REPORT.md
git commit -m "harness: [단계3] Evaluator QA_REPORT 생성 - {합격/조건부/불합격}"

# 최종 완료 시
git add harness/
git commit -m "harness: 파이프라인 완료 - 최종 점수 {X.X}/10"
```

**커밋 타이밍 규칙**:
1. 서브에이전트가 파일을 생성/수정한 직후 오케스트레이터가 커밋을 실행한다
2. 다음 단계를 시작하기 전에 반드시 이전 단계 커밋이 완료되어 있어야 한다
3. 커밋 실패 시 원인을 확인하고 해결한 뒤 재시도한다 (--no-verify 사용 금지)

---

## 실행 흐름

```
[사용자 프롬프트]
       ↓
  ① Planner 서브에이전트
     → SPEC.md 생성
       ↓
  ② Generator 서브에이전트
     → output/ Swift 파일 생성 + SELF_CHECK.md 작성
       ↓
  ③ Evaluator 서브에이전트
     → QA_REPORT.md 작성
       ↓
  ④ 판정 확인
     → 합격: 완료 보고
     → 불합격/조건부: ②로 돌아가 피드백 반영 (최대 3회 반복)
```

---

## 단계별 실행 지시

### 단계 0: Xcode 프로젝트 준비 ← 파이프라인 시작 전 반드시 실행

**오케스트레이터가 직접 실행. Xcode 프로젝트와 SPM 패키지가 준비되어야 Generator 결과물을 통합할 수 있다.**

#### 0-1. Xcode 프로젝트 존재 여부 확인

```bash
PROJECT_ROOT="/Users/haesuyoun/Desktop/NahunPersonalFolder/ReactionTimeChecker"
ls "$PROJECT_ROOT/"*.xcodeproj 2>/dev/null && echo "✅ 프로젝트 존재" || echo "❌ 프로젝트 없음"
```

**프로젝트가 없으면 Xcode에서 직접 생성**:
```
Xcode → File → New → Project → iOS → App
Product Name: ReactionTimeChecker
Bundle Identifier: com.nahun.ReactionTimeChecker
Interface: SwiftUI / Language: Swift
저장 위치: /Users/haesuyoun/Desktop/NahunPersonalFolder/ReactionTimeChecker/
```

#### 0-2. TopDesignSystem SPM 패키지 추가

Xcode 프로젝트가 생성된 후, `ruby xcodeproj` gem을 사용해 SPM 패키지를 자동 추가한다.

```bash
# xcodeproj gem 설치 확인 (없으면 설치)
gem list xcodeproj | grep xcodeproj || gem install xcodeproj

# SPM 패키지 추가 스크립트 실행
ruby << 'RUBY_SCRIPT'
require 'xcodeproj'

project_path = "/Users/haesuyoun/Desktop/NahunPersonalFolder/ReactionTimeChecker/ReactionTimeChecker.xcodeproj"
project = Xcodeproj::Project.open(project_path)

# 이미 추가되어 있는지 확인
already_added = project.root_object.package_references.any? do |ref|
  ref.repositoryURL&.include?("TopDesignSystem")
end

if already_added
  puts "✅ TopDesignSystem 이미 추가됨"
else
  # Remote SPM 패키지 참조 추가
  pkg = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  pkg.repositoryURL = "https://github.com/KimNahun/TopDesignSystem.git"
  pkg.requirement = { kind: "upToNextMajorVersion", minimumVersion: "3.0.0" }
  project.root_object.package_references << pkg

  # 메인 타겟에 product dependency 추가
  target = project.targets.find { |t| t.name == "ReactionTimeChecker" }
  dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  dep.package = pkg
  dep.product_name = "TopDesignSystem"
  target.package_product_dependencies << dep

  project.save
  puts "✅ TopDesignSystem SPM 추가 완료"
end
RUBY_SCRIPT
```

#### 0-3. 패키지 의존성 해결

```bash
cd "/Users/haesuyoun/Desktop/NahunPersonalFolder/ReactionTimeChecker"
xcodebuild -resolvePackageDependencies \
  -project ReactionTimeChecker.xcodeproj \
  -scheme ReactionTimeChecker
echo "✅ 패키지 의존성 해결 완료"
```

**단계 0 완료 조건**: `.xcodeproj` 파일 존재 + `TopDesignSystem` 패키지 참조 추가 + resolve 성공.
실패 시 원인을 파악하고 해결한 뒤 다음 단계로 진행한다.

---

### 단계 1: Planner 호출

**Agent 도구 호출 — `model: "opus"` 필수:**

```
description: "Planner: SPEC.md 설계"
model: "opus"
subagent_type: "general-purpose"
prompt: |
  PROJECT_CONTEXT.md 파일을 반드시 먼저 읽어라. 이것이 프로젝트 고정 요구사항이다.
  agents/planner.md 파일을 읽고, 그 지시를 따라라.
  agents/evaluation_criteria.md 파일도 읽고 참고하라.

  사용자 요청: [사용자가 준 프롬프트]

  PROJECT_CONTEXT.md의 요구사항을 사용자 프롬프트보다 우선 적용하라.
  결과를 SPEC.md 파일로 저장하라.
```

Planner 서브에이전트가 SPEC.md를 생성하면, 다음 단계로 진행한다.


### 단계 2: Generator 호출

**최초 실행 시 — `model: "sonnet"` 사용:**

```
description: "Generator R1: Swift 파일 생성"
model: "sonnet"
subagent_type: "general-purpose"
prompt: |
  PROJECT_CONTEXT.md 파일을 반드시 먼저 읽어라. 이것이 프로젝트 고정 요구사항이다.
  agents/generator.md 파일을 읽고, 그 지시를 따라라.
  agents/evaluation_criteria.md 파일도 읽고 참고하라.
  SPEC.md 파일을 읽고, 전체 기능을 구현하라.

  PROJECT_CONTEXT.md의 아키텍처, 색상, 애니메이션 요구사항을 반드시 준수하라.
  output/ 폴더 아래에 파일 구조에 따라 Swift 파일들을 생성하라.
  완료 후 SELF_CHECK.md를 작성하라.
```

**피드백 반영 시 (2회차 이상) — `model: "opus"` 사용:**

```
description: "Generator R{N}: QA 피드백 반영"
model: "opus"
subagent_type: "general-purpose"
prompt: |
  PROJECT_CONTEXT.md 파일을 반드시 먼저 읽어라. 이것이 프로젝트 고정 요구사항이다.
  agents/generator.md 파일을 읽고, 그 지시를 따라라.
  agents/evaluation_criteria.md 파일도 읽고 참고하라.
  SPEC.md 파일을 읽어라.
  output/ 폴더의 모든 Swift 파일을 읽어라. 이것이 현재 코드다.
  QA_REPORT.md 파일을 읽어라. 이것이 QA 피드백이다.

  QA 피드백의 "구체적 개선 지시"를 모두 반영하여 코드를 수정하라.
  "방향 판단"이 "아키텍처 재설계"이면 레이어 구조 자체를 다시 잡아라.
  완료 후 SELF_CHECK.md를 업데이트하라.
```


### 단계 3: Evaluator 호출

**Agent 도구 호출 — `model: "opus"` 필수:**

```
description: "Evaluator: QA_REPORT 작성"
model: "opus"
subagent_type: "general-purpose"
prompt: |
  PROJECT_CONTEXT.md 파일을 반드시 먼저 읽어라. 이것이 프로젝트 고정 요구사항이다.
  agents/evaluator.md 파일을 읽고, 그 지시를 따라라.
  agents/evaluation_criteria.md 파일을 읽어라. 이것이 채점 기준이다.
  SPEC.md 파일을 읽어라. 이것이 설계서다.
  output/ 폴더의 모든 Swift 파일을 읽어라. 이것이 검수 대상이다.

  검수 절차:
  1. output/ 코드를 분석하라
  2. SPEC.md의 기능이 구현되었는지 확인하라
  3. evaluation_criteria.md에 따라 5개 항목을 채점하라
  4. 최종 판정(합격/조건부/불합격)을 내려라
  5. 불합격 또는 조건부 시, 구체적 개선 지시를 작성하라

  결과를 QA_REPORT.md 파일로 저장하라.
```


### 단계 4: 판정 확인

QA_REPORT.md를 읽고 판정을 확인한다.

- **"합격"** → 단계 5(Xcode 통합)로 진행.
- **"조건부 합격"** 또는 **"불합격"** → 단계 2로 돌아가 피드백 반영.
- **최대 반복 횟수**: 3회. 3회 후에도 불합격이면 현재 상태로 전달하고 이슈를 보고.

### 단계 5: Xcode 프로젝트 통합 ← QA 합격 후 반드시 실행

오케스트레이터가 직접 실행:

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

**통합 전제조건** (스크립트 실행 전 확인):
- `ReactionTimeChecker.xcodeproj`가 존재해야 한다
- Xcode에서 TopDesignSystem SPM 패키지가 추가되어 있어야 한다
  - File → Add Package Dependencies → `https://github.com/KimNahun/TopDesignSystem.git`

**통합 후 수동 작업** (공유 기능 구현 시점에 처리):
```
Xcode → Target → Info → URL Types → "+" → URL Schemes: "reactiontime"
```

---

## 완료 보고 형식

```
## 하네스 실행 완료

**결과물**: output/ 폴더
**Planner 설계 기능 수**: X개
**QA 반복 횟수**: X회
**최종 점수**: 동시성 X/10, MVVM X/10, UX/재미 X/10, 기능 X/10, 코드품질 X/10 (가중 X.X/10)

**실행 흐름**:
1. Planner: [설계 요약 한 줄]
2. Generator R1: [구현 결과 한 줄]
3. Evaluator R1: [판정 + 핵심 피드백 한 줄]
4. Generator R2: [수정 내용 한 줄] (있는 경우)
5. Evaluator R2: [판정 결과] (있는 경우)
...

**주요 파일**:
- output/App/ReactionTimeCheckerApp.swift
- output/Views/[주요 뷰 목록]
- output/ViewModels/[주요 뷰모델 목록]
```

---

## 서브에이전트 모델 선택 기준

| 단계 | 모델 | 이유 |
|------|------|------|
| 단계 1 Planner | **opus** | 전체 아키텍처 설계. 구조를 잘못 잡으면 Generator/Evaluator 모두 망함 |
| 단계 2 Generator (최초) | **sonnet** | 일반 Swift 코딩. 비용 대비 성능 최적 |
| 단계 2 Generator (피드백 반영) | **opus** | QA 피드백 + 전체 코드 맥락 동시 처리. 복잡한 디버깅 |
| 단계 3 Evaluator | **opus** | 동시성·MVVM·재미 UX 위반 탐지. 놓치면 안 됨 |

Agent 도구 호출 시 `model` 파라미터를 반드시 지정하라:
- `"model": "sonnet"` — 1회차 코드 생성
- `"model": "opus"` — 설계, QA, 피드백 반영

---

## 주의사항

- Generator와 Evaluator는 반드시 다른 서브에이전트로 호출할 것 (분리가 핵심)
- 각 단계 완료 후 생성된 파일이 존재하는지 확인할 것
- output/ 폴더가 없으면 생성할 것
- **재미 요소 누락 시 Evaluator가 반드시 감점한다** — 등급 이모지, 애니메이션, 햅틱이 형식적으로만 있으면 감점

---

## Phase 2: 사용자 테스트 & 피드백 루프

> **하네스 자동 파이프라인(Phase 1)이 완료된 후**, 사용자가 실기기/시뮬레이터에서 직접 앱을 사용해보며 피드백을 주는 단계.

### 라운드 구성

| 라운드 | 관점 | 사용자가 집중할 것 |
|--------|------|-------------------|
| **R1** | **기본 흐름** | 라운드 선택 → 테스트 시작 → 기록 → 결과 확인. 전체 흐름이 끊김 없이 동작하는가? |
| **R2** | **재미 요소** | 등급 이모지가 기쁜가? 애니메이션이 팝한가? 햅틱이 적절한가? 결과 화면이 흥미로운가? |
| **R3** | **통계 & 비교** | 백분위 계산이 정확한가? 다른 사람 비교 수치가 잘 보이는가? 재도전 버튼이 동작하는가? |
| **R4** | **부정 탭 처리** | 실격 메시지가 웃긴가? 화면 반응이 명확한가? |
| **R5** | **엣지 케이스** | 모든 라운드 실격 시, 매우 빠른 탭, 앱 백그라운드 복귀 등 |

### 피드백 형식 (사용자 → AI)

```
[버그] 설명
[UI] 설명
[재미] 설명  ← 이 앱에서 중요한 카테고리
[기능] 설명
[개선] 설명
```

### 피드백 기록

각 라운드의 피드백과 처리 결과는 `harness/FEEDBACK_LOG.md`에 기록한다.

### 현재 상태

| 라운드 | 상태 |
|--------|------|
| R1 기본 흐름 | ⬜ 대기 |
| R2 재미 요소 | ⬜ 대기 |
| R3 공유 기능 | ⬜ 대기 |
| R4 부정 탭 처리 | ⬜ 대기 |
| R5 엣지 케이스 | ⬜ 대기 |
