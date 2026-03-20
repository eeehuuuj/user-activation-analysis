# Activation 전환율 개선을 위한 유저 초기 행동 분석

신규 유저의 Activation(첫 레슨 완료) 전환율이 낮은 문제를 정의하고,
가입 초기 행동 데이터를 기반으로 전환에 영향을 미치는 핵심 요인을 분석한 프로젝트입니다.

## 🧐 Problem
- 가입자의 76.7%가 첫 레슨 완료 이전 이탈
- Activation은 Retention 및 Revenue로 이어지는 핵심 선행 지표

## 👀 Insights
### 1. 빠른 레슨 시작 ≠ Activation
- 가입 직후(<1h) 레슨 진입 유저 전환율: 47.1%
- 전체 평균(63.0%) 대비 낮음

➡️ 초기 진입 속도는 전환의 주요 요인이 아님

### 2. 콘텐츠 탐색 경험이 Activation을 결정
- 콘텐츠 탐색 후 레슨 시작 그룹: 37.0%
- 바로 레슨 시작 그룹: 28.5% (p < 0.001)

➡️ 레슨 시작 전 콘텐츠 탐색 여부는 Activation 전환을 설명하는 핵심 행동 변수

## 🌟 Action Plan

1. 관심사 기반 온보딩 개인화
→ 초기 콘텐츠 탐색 행동 유도

2. CTA 변경 실험
→ ‘레슨 시작’ → ‘커리큘럼/후기 보기’

3. 탐색 기반 추천 콘텐츠 노출
→ 연속 탐색 행동 유도

## 📈 Metrics

### Success
- Activation Rate
- 레슨 시작 전 콘텐츠 탐색 수
- 콘텐츠 탐색 경험 유저 비율

### Guardrail
- 레슨 진입률
- 페이지 이탈률

## Data & Method

- 데이터: 온라인 구독형 교육 서비스 로그 데이터
- 분석 도구: SQL, Python (Pandas)
- 시각화 도구: Tableau
- 분석 방식:
  - 사용자 행동 피처 생성
  - 세그먼트별 전환율 비교
  - 통계적 유의성 검정 (Chi-square test)

## Project Structure
```plaintext
.
├── sql/
│   ├── 01_preprocessing.sql
│   ├── 02_feature_engineering.sql
│   └── 03_feature_dataset.sql
├── notebook/
│   └── activation_analysis.ipynb
├── Result/
│   └── onepaper_portfolio.png
└── README.md
```
![온라인구독서비스-원페이퍼-003](https://github.com/user-attachments/assets/f8c2f6ce-5259-414a-8689-0e72182b0561)


