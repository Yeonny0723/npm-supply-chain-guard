# audit 커맨드 remediation 확장 설계

날짜: 2026-04-16

## 개요

`/npm-supply-chain-guard:audit` 커맨드에 Step 8(자동 수정)을 추가해, 취약점 탐지 이후 `npm audit fix` 기반 조치 흐름을 한 번에 완결한다.

## 목표

- audit 결과에 취약점이 있을 때만 Step 8을 실행한다 (취약점 0개면 건너뜀).
- safe fix(patch/minor 범위)는 Claude가 자동 실행한다.
- major 버전 변경이나 `--force`가 필요한 경우, 수정 불가 경우는 경고 메시지만 출력한다.
- yarn 프로젝트는 `npm audit fix`를 지원하지 않으므로 수동 안내로 대체한다.

## 전체 흐름

```
Step 1~7: 현행 유지
          ↓
     취약점 있음?
     ├── NO  → 종료 (현행과 동일)
     └── YES → Step 8 진입
               ↓
          npm audit fix --dry-run --json
               ↓
          safe fix 분류 (patch/minor)
          ├── safe fix 있음 → npm audit fix 실행 → 재감사 → 잔여 취약점 출력
          └── force-only/수정불가 있음 → 경고 출력
```

## Step 8 상세

### 8-1. dry-run으로 수정 범위 파악

```bash
npm audit fix --dry-run --json   # npm 전용
```

yarn 프로젝트는 이 단계를 건너뛰고 8-4 수동 안내로 직행한다.

### 8-2. 분류 기준

| 분류 | 조건 | 처리 |
|------|------|------|
| safe fix | patch 또는 minor 버전 업 | 자동 실행 |
| force-only | major 버전 업 또는 `--force` 필요 | 경고만 출력 |
| 수정 불가 | `fixAvailable: false` | 경고만 출력 |

### 8-3. safe fix 실행

```bash
npm audit fix
```

실행 후 `npm audit --json` 재실행으로 잔여 취약점 수를 확인한다.

### 8-4. 출력 형식

```
🔧 Step 8: 자동 수정

  ✅ safe fix 적용 (N개 패키지 업데이트)
     lodash: 4.17.20 → 4.17.21

  ⚠️  수동 조치 필요 (M개)
     some-pkg (critical) — major 버전 변경 필요, 수동으로 검토하세요.
     other-pkg (high)    — 패치 없음, 대체 패키지를 검토하세요.

  감사 재실행 결과: 잔여 취약점 K개
```

yarn 프로젝트의 경우:

```
⚠️  yarn 프로젝트는 자동 fix를 지원하지 않습니다.
    yarn upgrade <패키지명>@<수정버전> 으로 개별 업데이트하세요.
```

## 커맨드 파일 변경 사항

`commands/audit.md`에 다음을 추가한다.

1. `allowed-tools`에 `Bash(npm audit fix:*)` 추가
2. Step 8 섹션 추가 (조건부 실행 명시)

## 제약 조건

- `npm audit fix --force`는 절대 자동 실행하지 않는다.
- safe fix 실행 시 lockfile이 변경된다는 사실을 출력에 명시한다.
- Step 7(주간 자동 감사 스케줄 안내)은 Step 8 이후에 출력한다.
