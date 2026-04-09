# 설치 가이드

## 권장 방식: 플러그인 마켓플레이스 설치

Claude Code 플러그인 마켓플레이스에서 설치합니다.

```bash
/plugin marketplace add yeonny0723/npm-supply-chain-guard
/plugin install npm-supply-chain-guard@yeonny0723
```

설치 후 사용할 수 있는 명령:

- `/npm-supply-chain-guard:init`
- `/npm-supply-chain-guard:audit`
- `/npm-supply-chain-guard:schedule`
- `/npm-supply-chain-guard:git:commit`

### 권장 첫 실행

```bash
/npm-supply-chain-guard:init
/npm-supply-chain-guard:audit
```

이 순서로 실행하면 프로젝트 기본 보안값을 먼저 적용하고, 현재 의존성 위험 상태를 바로 점검할 수 있습니다.

### 기대 동작

플러그인이 활성화되면 다음처럼 동작해야 합니다.

- lockfile이 없을 때 install 명령 차단
- 위험한 설치 패턴 경고
- 허용된 안전 경로에서는 조용히 통과

대표 메시지 예시:

- `BLOCKED: lockfile이 없습니다.`
- `npm ci --ignore-scripts 사용을 권장합니다.`

## 수동 설치

마켓플레이스 설치를 쓰지 않는다면 플러그인 파일을 직접 복사합니다.

```bash
cp -r hooks ~/.claude/
cp -r commands ~/.claude/
```

그리고 훅 설정을 `~/.claude/settings.json`에 병합합니다.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/npm/npm-install-guard.sh"
          }
        ]
      }
    ]
  }
}
```

수동 설치는 환경마다 경로 차이가 있을 수 있으므로, 실제 Claude Code 환경에서 훅 경로가 올바르게 해석되는지 확인해야 합니다.

## 확인 체크리스트

1. `/npm-supply-chain-guard:init`를 실행합니다.
2. `/npm-supply-chain-guard:audit`를 실행합니다.
3. lockfile이 있는 프로젝트에서 테스트용 install 명령을 실행합니다.
4. 예상한 경고 또는 차단 동작이 실제로 나타나는지 확인합니다.

## 참고

- 훅은 `package.json`이 있는 디렉터리에서만 의미가 있습니다.
- 패키지 프로젝트가 아닌 디렉터리에서는 개입하지 않고 종료합니다.
- 명령어와 훅의 관계는 [명령어와 훅 아키텍처](./commands-and-hooks.md)를 참고하세요.
