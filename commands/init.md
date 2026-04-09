---
description: 프로젝트에 .npmrc / .yarnrc.yml 보안 설정을 추가합니다
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash(ls:*)
  - Bash(test:*)
---

# /npm-supply-chain-guard:init

프로젝트 루트에 `.npmrc` / `.yarnrc.yml` 보안 설정을 추가합니다. 이미 파일이 존재하면 누락된 키만 추가하고, 충돌하는 값이 있으면 경고를 출력합니다.

## 실행 절차

### Step 1: 패키지 매니저 감지

Read 툴로 다음 파일들의 존재를 확인해 패키지 매니저를 감지한다 (파일이 없으면 Read가 오류를 반환하므로 존재 여부를 판단할 수 있다).

1. `yarn.lock` → yarn
2. `package-lock.json` → npm
3. 모두 없음 → lockfile 없음 경고 출력 후 `.npmrc` 생성은 계속 진행

### Step 2: .npmrc 처리 (npm 공통)

`.npmrc` 파일에 아래 보안 키를 적용한다.

```ini
ignore-scripts=true
save-exact=true
audit=true
audit-level=high
package-lock=true
```

**처리 규칙:**
- 파일이 없으면 위 내용으로 신규 생성한다.
- 파일이 있으면 각 키를 확인한다:
  - 키가 없으면 파일 끝에 추가한다.
  - 키가 있고 값이 같으면 건너뛴다 (이미 적용됨).
  - 키가 있고 값이 다르면 덮어쓰지 않고 경고를 출력한다:
    `⚠️  .npmrc — 충돌 (수동 검토 필요): <key> (현재값: <value>)`

### Step 3: .yarnrc.yml 처리 (Yarn 프로젝트만)

`yarn.lock`이 감지된 경우만 실행한다. `.yarnrc.yml` 파일에 아래 보안 키를 적용한다.

```yaml
enableScripts: false
enableImmutableInstalls: true
checksumBehavior: throw
```

**처리 규칙:**
- 파일이 없으면 위 내용으로 신규 생성한다.
- 파일이 있으면 각 키를 확인한다:
  - 키가 없으면 파일 끝에 추가한다.
  - 키가 있고 값이 같으면 건너뛴다.
  - 키가 있고 값이 다르면 덮어쓰지 않고 경고를 출력한다:
    `⚠️  .yarnrc.yml — 충돌 (수동 검토 필요): <key> (현재값: <value>)`

### Step 4: 결과 요약 출력

각 파일에 대해 아래 형식으로 출력한다.

```
✅ .npmrc — <N>개 키 추가됨: <key1>, <key2>, ...
⚠️  .npmrc — <N>개 키 충돌 (수동 검토 필요): <key> (현재값: <value>)
✅ .yarnrc.yml — 신규 생성됨 (<N>개 키)
```

변경이 없었으면:
```
✅ .npmrc — 이미 모든 보안 키가 적용되어 있습니다.
```

### Step 5: 다음 단계 안내

완료 후 다음을 출력한다.

```
다음 단계: /npm-supply-chain-guard:audit 를 실행해 현재 프로젝트 전체 감사를 실행하세요.
```
