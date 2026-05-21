# 반응속도 테스트

순발력, 색감, 기억력, 시간 감각을 측정하는 **9가지 미니 게임**이 담긴 iOS 앱입니다.

> **AI 하네스 기반 개발** · **한국어 / 영어 다국어 지원**

<table>
  <tr>
    <td align="center" width="25%">
      <b>홈 화면</b><br/>
      <img src="docs/screenshots/01_home.png" width="220"/>
    </td>
    <td align="center" width="25%">
      <b>반응속도</b><br/>
      <img src="docs/screenshots/02_reaction.png" width="220"/>
    </td>
    <td align="center" width="25%">
      <b>색상 판별</b><br/>
      <img src="docs/screenshots/03_stroop.png" width="220"/>
    </td>
    <td align="center" width="25%">
      <b>순서 탭</b><br/>
      <img src="docs/screenshots/04_sequence.png" width="220"/>
    </td>
  </tr>
  <tr>
    <td align="center">
      <b>멀티 탭</b><br/>
      <img src="docs/screenshots/05_multitap.png" width="220"/>
    </td>
    <td align="center">
      <b>시간 감각</b><br/>
      <img src="docs/screenshots/06_timesense.png" width="220"/>
    </td>
    <td align="center">
      <b>순간 포착</b><br/>
      <img src="docs/screenshots/07_memory.png" width="220"/>
    </td>
    <td align="center">
      <b>액자 맞추기</b><br/>
      <img src="docs/screenshots/08_frame.png" width="220"/>
    </td>
  </tr>
  <tr>
    <td align="center">
      <b>색상 찾기</b><br/>
      <img src="docs/screenshots/09_findcolor.png" width="220"/>
    </td>
    <td align="center">
      <b>큰 원 찾기</b><br/>
      <img src="docs/screenshots/10_bigcircle.png" width="220"/>
    </td>
    <td align="center">
      <b>결과 화면</b><br/>
      <img src="docs/screenshots/11_result.png" width="220"/>
    </td>
    <td align="center">
      <b>더 많은 기능</b><br/>
      <sub>랭킹 · 기록 저장 · 공유</sub>
    </td>
  </tr>
</table>

---

## Highlights

### AI 하네스 기반 개발
**Planner → Generator → Evaluator** 3-Agent 파이프라인으로 코드를 자동 생성·검증합니다.
한 줄 프롬프트만 입력하면 SPEC 작성 → Swift 코드 생성 → QA 리포트까지 자동 실행되며,
각 단계 결과물은 `harness/` 폴더에 산출물(SPEC.md, output/, QA_REPORT.md)로 남습니다.

```
사용자 한 줄 프롬프트
       │
       ▼
[Planner]   ──► SPEC.md 생성
       │
       ▼
[Generator] ──► output/*.swift 생성
       │
       ▼
[Evaluator] ──► QA_REPORT.md 합격/피드백
       │
       ▼  (합격 시)
Xcode 프로젝트에 통합
```

### 다국어 지원 (Localization)
`Localizable.strings` 기반으로 **한국어 / 영어**를 완벽 지원합니다.
모든 게임 UI · 등급 설명 · 결과 화면 문구가 시스템 언어에 맞춰 자동 전환됩니다.

```
ReactionTimeChecker/
├── ko.lproj/Localizable.strings   # 한국어
└── en.lproj/Localizable.strings   # English
```

---

## 게임 소개

| 게임 | 설명 |
| --- | --- |
| **반응속도** | 화면이 초록색으로 바뀌는 순간 즉시 탭. 5라운드 평균 반응속도 측정 |
| **색상 판별** | 스트룹 효과 — 글자가 아닌 **글자 색**을 빠르게 판단 |
| **순서 탭** | 흩어진 숫자를 작은 수부터 큰 수 순서로 탭 |
| **멀티 탭** | 빨간색 도형이 사라지기 전 모두 탭 |
| **시간 감각** | 화면이 보이지 않은 상태에서 정확히 **10.00초**에 탭 |
| **순간 포착** | 짧게 노출된 숫자를 기억하고 그대로 입력 |
| **액자 맞추기** | 점선 액자 안에 그림을 정확히 맞추기 (0pt = Perfect) |
| **색상 찾기** | 제시된 색상 타일을 그리드에서 찾기 |
| **큰 원 찾기** | 비슷한 크기의 원들 중 **가장 큰 원** 선택 |

---

## 기술 스택

**Swift 5 · SwiftUI · iOS 17+ · MVVM · SPM** (TopDesignSystem, Kakao SDK)

## 빌드

```bash
# 1) 시크릿 설정
cp Secrets.template.xcconfig Secrets.xcconfig
# Secrets.xcconfig에 카카오 앱 키 입력

# 2) Xcode 열기
open ReactionTimeChecker.xcodeproj
```
