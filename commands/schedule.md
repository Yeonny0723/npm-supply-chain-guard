---
description: 매주 월요일 09:00에 npm 공급망 감사를 자동 실행하는 스케줄을 설정합니다
allowed-tools: []
---

# npm 주간 감사 스케줄 설정

매주 월요일 09:00에 `/npm-supply-chain-guard:audit`를 자동 실행하는 스케줄을 등록합니다.

## 실행 절차

### Step 1: CronCreate로 스케줄 등록

CronCreate 도구를 사용해 다음 설정으로 스케줄을 등록한다.

- **cron 표현식:** `0 9 * * 1` (매주 월요일 09:00)
- **prompt:**
  > 현재 프로젝트에서 `/npm-supply-chain-guard:audit`를 실행하고, 결과를 요약해 보고하세요.

### Step 2: 완료 안내

스케줄 등록 완료 후 다음을 출력한다.

- 등록된 스케줄 ID
- 스케줄 조회 방법: CronList 도구 사용
- 스케줄 삭제 방법: CronDelete 도구에 스케줄 ID 전달
- 다음 실행 예정 시각 (다음 월요일 09:00)
