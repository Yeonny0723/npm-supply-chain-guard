---
description: npm 공급망 공격 방어 체크리스트 감사를 실행합니다
allowed-tools:
  - Bash(npm audit:*)
  - Bash(yarn audit:*)
  - Bash(npm ls:*)
  - Bash(yarn list:*)
  - Bash(npm audit fix:*)
  - Bash(git ls-files:*)
  - Bash(git check-ignore:*)
  - Bash(git diff:*)
  - Read
---

# npm 공급망 공격 방어 감사

npm 공급망 공격 예방 체크리스트를 단계별로 실행합니다.

## 실행 절차

### Step 1: 패키지 매니저 자동 감지

다음 순서로 lockfile 존재를 확인해 패키지 매니저를 감지한다.

1. `yarn.lock` → yarn
2. `package-lock.json` → npm

lockfile이 하나도 없으면 경고를 출력하고 감사를 중단한다.

### Step 2: lockfile git 추적 여부 확인

```bash
git ls-files <lockfile>
git check-ignore <lockfile>
```

- `git ls-files` 결과가 비어 있으면: "WARN: lockfile이 git에 추적되지 않습니다."
- `git check-ignore` 결과가 있으면: "WARN: lockfile이 .gitignore에 포함되어 있습니다."
- 필요하면 `git diff -- package.json <lockfile>` 또는 staged diff를 함께 확인해, 최근 의존성 변경이 있었는데 lockfile 반영이 누락된 정황이 있는지도 점검한다.

### Step 3: 취약점 감사 실행

감지된 패키지 매니저에 맞게 JSON 형식으로 실행해 구조화된 데이터를 파싱한다:

```bash
npm audit --json        # npm
yarn audit --json       # yarn
```

#### 3-1. severity 요약 출력

결과를 severity별로 요약한다. 취약점이 없으면 OK로 표시한다.

```
⚠️  총 N개 취약점 발견 (패키지 감사: M개)

  🔴 Critical  :  N개
  🟠 High      :  N개
  🟡 Moderate  :  N개
  🔵 Low       :  N개
```

#### 3-2. Critical 취약점 상세 출력

Critical 취약점이 1개 이상이면 반드시 각 항목을 아래 형식으로 출력한다.

```
🔴 Critical 취약점 상세

1. <패키지명> (<영향받는 버전 범위>)
   취약점: <취약점 이름> (<CVE 번호 또는 GHSA ID>)
   설명: <취약점이 어떤 공격을 허용하는지 1~2줄로 설명>
   수정 버전: <패치된 버전> 이상으로 업데이트 권장
             (패치 없음: 대체 패키지 또는 resolutions 고정 검토)
   의존성 경로: <직접의존성> > ... > <취약 패키지>
   참고: <advisory URL>
```

**파싱 규칙:**
- **npm**: `vulnerabilities[*]` 에서 `severity === "critical"` 항목 추출. `via[]`에서 취약점 이름·CVE·url, `fixAvailable`에서 수정 버전 정보를 가져온다. `fixAvailable`이 `false`이면 "패치 없음"으로 표시한다.
- **yarn**: `type === "auditAdvisory"` 이벤트 중 `data.advisory.severity === "critical"` 항목 추출. `data.advisory.title`, `data.advisory.cves[]`, `data.advisory.patched_versions`, `data.advisory.url`을 사용한다.

**출력 예시:**
```
🔴 Critical 취약점 상세

1. lodash (< 4.17.21)
   취약점: Prototype Pollution (CVE-2020-8203)
   설명: zipObjectDeep 함수에서 프로토타입 오염이 발생해 원격 코드 실행으로 이어질 수 있습니다.
   수정 버전: 4.17.21 이상으로 업데이트 권장
   의존성 경로: my-app > some-lib > lodash
   참고: https://github.com/advisories/GHSA-p6mc-m468-83gw

2. @stablelib/ed25519 (모든 버전)
   취약점: Ed25519 Signature Malleability (GHSA-xxxx-xxxx-xxxx)
   설명: 서명 가변성(malleability) 결함으로 서명 위조가 가능합니다.
   수정 버전: 패치 없음 — resolutions 필드로 버전 고정 또는 대체 패키지 검토 권장
   의존성 경로: wagmi > @wagmi/connectors > @walletconnect/... > @stablelib/ed25519
   참고: https://github.com/advisories/...
```

#### 3-3. High 취약점 목록 출력

High 취약점이 있으면 간략 목록으로 출력한다.

```
🟠 High 취약점 목록 (N개)
  - <패키지명> (<버전 범위>) — <취약점 이름> [수정 버전: <버전> 또는 패치 없음]
```

### Step 4: loose semver 범위 검사

`package.json`의 `dependencies`, `devDependencies`, `peerDependencies`, `optionalDependencies`, `resolutions`, `overrides`를 읽어  
`^`, `~`, `*`, `.x` 패턴이 포함된 버전을 목록으로 출력한다.

`file:`, `github:`, `git+`, `git:`, `link:`, `workspace:`, `portal:` 프로토콜은 false positive이므로 제외한다.

핵심 의존성은 정확한 버전 고정을 권장하고, loose semver가 남아 있으면 감사 결과에 WARN으로 포함한다.

### Step 5: 의존성 트리 출력 (depth 3)

```bash
npm ls --depth=3        # npm
yarn list --depth=3     # yarn (classic)
```

### Step 6: 수동 확인 체크리스트 출력

아래 항목을 화면에 출력하고 팀이 수동으로 확인하도록 안내한다:

```
[ ] CI/CD에 빌드에 꼭 필요한 secret만 주입했는가?
[ ] 토큰 scope를 최소화하고, 짧은 수명의 자격증명을 사용 중인가?
[ ] publish용 토큰과 runtime 토큰이 분리되어 있는가?
[ ] 패키지 발행 조직이라면 OIDC 기반 publish를 설정했는가?
[ ] 자동 의존성 업데이트(Renovate/Dependabot)와 자동 머지가 최소화되어 있는가?
```

### Step 7: 주간 자동 감사 스케줄 안내

주간 자동 감사를 설정하지 않았다면 다음 커맨드 실행을 안내한다:

```
# /npm-supply-chain-guard:schedule
```

### Step 8: 자동 수정 (취약점이 있을 때만)

Step 3의 audit 결과에서 취약점이 **1개 이상** 발견된 경우에만 이 단계를 실행한다. 취약점이 0개이면 Step 8 전체를 건너뛴다.

#### 8-1. yarn 프로젝트 처리

패키지 매니저가 yarn이면 `npm audit fix`를 지원하지 않으므로 아래 메시지를 출력하고 Step 8을 종료한다.

```
⚠️  yarn 프로젝트는 npm audit fix를 지원하지 않습니다.
    취약 패키지를 직접 업데이트하세요:
    yarn upgrade <패키지명>@<수정버전>
```

#### 8-2. dry-run으로 수정 범위 파악

```bash
npm audit fix --dry-run --json
```

JSON 출력을 파싱해 변경 예정 패키지 목록과 각 버전 변화를 추출한다.
추출 대상 필드: `auditReportVersion`, `actions[].action`, `actions[].resolves[].id`, `vulnerabilities[*].fixAvailable` (npm v7+의 경우 `vulnerabilities` 구조 사용).
`fixAvailable`이 객체이면 업그레이드 가능, `false`이면 수정 불가, `true`이면 자동 수정 가능으로 판단한다.

#### 8-3. safe fix 분류

dry-run 결과에서 각 패키지의 변경을 아래 기준으로 분류한다.

| 분류 | 조건 | 처리 |
|------|------|------|
| **safe fix** | patch 또는 minor 버전 업 (major 불변) | 자동 실행 |
| **force-only** | major 버전 변경 또는 `--force` 필요 | 경고만 출력 |
| **수정 불가** | `fixAvailable: false` | 경고만 출력 |

#### 8-4. safe fix 자동 실행

safe fix 대상이 없으면 8-4를 건너뛰고 8-5의 "자동으로 수정 가능한 취약점이 없습니다." 형식으로 바로 출력한다.

safe fix 대상이 1개 이상이면 아래 명령을 실행한다.

```bash
npm audit fix
```

실행 후 잔여 취약점 수를 확인하기 위해 다시 감사한다 (`--dry-run` 없이 실제 변경 결과를 측정한다).

```bash
npm audit --json
```

#### 8-5. 결과 출력

아래 형식으로 결과를 출력한다.

```
🔧 Step 8: 자동 수정

  ✅ safe fix 적용 (N개 패키지 업데이트)
     <패키지명>: <이전버전> → <수정버전>
     ...

  ⚠️  수동 조치 필요 (M개)
     <패키지명> (<severity>) — major 버전 변경 필요, 수동으로 검토하세요.
     <패키지명> (<severity>) — 패치 없음, 대체 패키지를 검토하세요.

  감사 재실행 결과: 잔여 취약점 K개
```

safe fix 대상이 없고 force-only/수정불가만 있는 경우:

```
🔧 Step 8: 자동 수정

  자동으로 수정 가능한 취약점이 없습니다.

  ⚠️  수동 조치 필요 (M개)
     <패키지명> (<severity>) — major 버전 변경 필요, 수동으로 검토하세요.
     <패키지명> (<severity>) — 패치 없음, 대체 패키지를 검토하세요.
```

> ⚠️ `npm audit fix --force` 는 breaking change를 유발할 수 있으므로 자동 실행하지 않습니다.
> safe fix 실행 시 `package-lock.json`이 변경됩니다. 변경 내용을 리뷰 후 커밋하세요.
