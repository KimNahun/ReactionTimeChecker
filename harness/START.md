# 실행 방법

## 프로젝트 구조

```
ReactionTimeChecker/
├── harness/                           ← 여기서 실행
│   ├── CLAUDE.md                      ← 오케스트레이터 (Claude Code가 자동으로 읽음)
│   ├── PROJECT_CONTEXT.md             ← 앱 고정 요구사항 (최우선)
│   ├── agents/
│   │   ├── evaluation_criteria.md     ← Swift + 재미 품질 평가 기준
│   │   ├── planner.md                 ← Planner 서브에이전트 지시서
│   │   ├── generator.md               ← Generator 서브에이전트 지시서
│   │   └── evaluator.md               ← Evaluator 서브에이전트 지시서
│   ├── output/                        ← 생성된 Swift 파일들 (실행 후 채워짐)
│   │   ├── App/ReactionTimeCheckerApp.swift
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   ├── Models/
│   │   └── Services/
│   ├── SPEC.md                        ← Planner가 생성 (실행 후 생김)
│   ├── SELF_CHECK.md                  ← Generator가 생성 (실행 후 생김)
│   ├── QA_REPORT.md                   ← Evaluator가 생성 (실행 후 생김)
│   └── START.md                       ← 지금 이 파일
└── ReactionTimeChecker/               ← 실제 Xcode 프로젝트 소스 (통합 후 채워짐)
```

---

## 실행 방법

### 1단계: harness 폴더에서 Claude Code를 실행합니다

```bash
cd /Users/haesuyoun/Desktop/NahunPersonalFolder/ReactionTimeChecker/harness
claude
```

Claude Code가 CLAUDE.md를 자동으로 읽고 오케스트레이터 역할을 합니다.

### 2단계: 프롬프트 한 줄을 입력합니다

```
반응속도 테스트 앱 만들어줘. 재미있게.
```

이것만 치면 됩니다.
CLAUDE.md의 지시에 따라 자동으로:

1. Planner 서브에이전트가 SPEC.md (Swift 6 + MVVM 설계서)를 생성합니다
2. Generator 서브에이전트가 output/ 폴더에 Swift 파일들을 생성합니다
3. Evaluator 서브에이전트가 QA_REPORT.md를 생성합니다
4. 불합격이면 Generator가 피드백을 반영하여 재작업합니다
5. 합격이면 output/ → ReactionTimeChecker/ 로 파일을 복사합니다
6. 완료 보고가 나옵니다

### 3단계: 결과를 확인합니다

```bash
open /Users/haesuyoun/Desktop/NahunPersonalFolder/ReactionTimeChecker/ReactionTimeChecker.xcodeproj
```

---

## 앱 핵심 개념

```
[홈] 라운드 선택(5회/10회) → 시작 버튼
       ↓
[테스트] 어두운 화면 (대기) → 1~5초 랜덤 → 초록 화면 (탭!)
       ↓ (탭하기 전에 터치 → 실격! "거짓말쟁이로군요!")
[결과] 평균ms / 최고 / 최악 / 다른 사람 비교 / 등급 + 이모지 / 공유 버튼
```

## 등급 시스템 (핵심 재미 요소)

| 상위 % | 등급 | 캐릭터 |
|--------|------|--------|
| 1~10% | 반응속도의 신 | ⚡️ |
| 11~20% | 닌자 | 🥷 |
| 21~30% | 사이보그 | 🤖 |
| 31~40% | 치타 | 🐆 |
| 41~50% | 토끼 | 🐰 |
| 51~60% | 일반인 | 🧑 |
| 61~70% | 나무늘보 주니어 | 🦥 |
| 71~80% | 거북이 | 🐢 |
| 81~90% | 달팽이 | 🐌 |
| 91~100% | 화석 | 🪨 |

---

## 평가 항목 (Swift 6 + 재미 특화)

| 항목 | 비중 | 핵심 기준 |
|------|------|-----------|
| Swift 6 동시성 | 30% | @MainActor, actor, Sendable |
| MVVM 분리 | 25% | View↔VM↔Service 단방향 의존 |
| 재미 & UX | 20% | 애니메이션, 햅틱, 등급 시스템, 실격 메시지 |
| 기능 완성도 | 15% | 테스트 흐름, 공유, 딥링크, 통계 |
| 코드 품질 | 10% | 접근 제어자, 에러 타입, 가독성 |

**합격 기준**: 가중 점수 7.0 이상 (동시성 또는 MVVM 4점 이하 시 무조건 불합격)
