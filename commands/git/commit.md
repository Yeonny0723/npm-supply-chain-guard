---
description: "컨벤셔널 커밋 메시지로 잘 포맷된 커밋을 생성합니다"
allowed-tools:
  [
    "Bash(git add:*)",
    "Bash(git status:*)",
    "Bash(git commit:*)",
    "Bash(git diff:*)",
    "Bash(git log:*)",
    "Read",
  ]
---

# /git:commit

컨벤셔널 커밋 메시지로 잘 포맷된 커밋을 생성합니다.

## 프로세스

1. 스테이지된 파일 확인, 스테이지된 파일이 있으면 해당 파일만 커밋
2. 여러 논리적 변경사항에 대한 diff 분석
3. **npm 공급망 보안 체크** (아래 참고)
4. **커밋 계획을 사용자에게 먼저 제시하고 승인 대기**
   - 커밋 분할 여부 및 각 커밋의 범위
   - 각 커밋의 메시지 (최종 포맷 그대로)
   - 스테이징할 파일 목록
5. 사용자가 승인하면 커밋 실행, 수정 요청 시 메시지/범위 조정 후 재확인

## npm 공급망 보안 체크

커밋 계획 제시 전에 반드시 아래 두 가지를 확인한다.

### 1. package.json 변경 감지 → semver 검사 + 커밋 분리 권장

스테이징된 파일 중 `package.json`이 포함된 경우:

- `package.json`을 읽어 `dependencies`, `devDependencies`, `peerDependencies`, `optionalDependencies`의 버전 범위를 확인한다.
- `^`, `~`, `*`, `.x` 패턴이 포함된 패키지를 목록으로 출력하고 정확한 버전 고정을 권장한다.
  - `file:`, `github:`, `git+`, `workspace:` 프로토콜은 false positive이므로 제외한다.
- `package.json`이 다른 관심사(기능 코드, 설정 등)와 함께 스테이징된 경우, **별도 커밋으로 분리**할 것을 권장한다.
- `package.json`이 스테이징되어 있는데 대응하는 lockfile이 이번 커밋에 전혀 포함되지 않았다면 명시적으로 안내한다.
  - 의도적 분리라면 진행 가능하지만, 누락이라면 lockfile도 함께 포함하도록 권장한다.

### 2. lockfile 변경 감지 → 커밋 분리 권장

스테이징된 파일 중 `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml` 중 하나라도 포함된 경우:

- lockfile 변경은 의존성 트리 변경을 의미하므로 코드 변경과 **별도 커밋**으로 분리할 것을 권장한다.
- lockfile이 스테이징되어 있으나 대응하는 `package.json`이 스테이징되지 않은 경우도 함께 안내한다.

## 커밋 포맷

`<타입>: <설명>`

**타입:**

- `feat`: 새로운 기능
- `fix`: 버그 수정
- `docs`: 문서화
- `style`: 포맷팅
- `refactor`: 코드 리팩토링
- `perf`: 성능 개선
- `test`: 테스트
- `chore`: 빌드/도구

**규칙:**

- 명령형 어조 ("추가" not "추가됨")
- 첫 줄 72자 미만
- 원자적 커밋 (단일 목적)
- 관련 없는 변경사항 분할

## 분할 기준

다른 관심사 | 혼합된 타입 | 파일 패턴 | 큰 변경사항 | **package.json / lockfile 변경**

## 참고사항

- 스테이지된 파일이 있으면 해당 파일만 커밋
- 분할 제안을 위한 diff 분석
- **커밋에 Claude 서명 절대 추가하지 않음**

