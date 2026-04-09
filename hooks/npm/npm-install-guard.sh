#!/usr/bin/env bash
# npm-install-guard.sh
# PreToolUse:Bash — npm/yarn install 명령 위험 감지
# 동작: lockfile 유무와 명령 종류에 따라 차단(exit 2) 또는 경고(exit 0)

INPUT=$(cat)

# JSON에서 command 추출 (python3 → node 폴백)
CMD=$(echo "$INPUT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)
if [ -z "$CMD" ]; then
  CMD=$(echo "$INPUT" | node -e "
    let d='';
    process.stdin.on('data', c => d += c);
    process.stdin.on('end', () => {
      try { process.stdout.write(JSON.parse(d).tool_input?.command || ''); } catch(e) {}
    });
  " 2>/dev/null)
fi

[ -z "$CMD" ] && exit 0

# install 트리거 패턴 체크 (안전한 명령은 조기 통과)
SAFE_PATTERNS=(
  "npm ci --ignore-scripts"
  "npm ci --ignore-scripts"
  "yarn install --immutable"
  "yarn install --frozen-lockfile"
)
for SAFE in "${SAFE_PATTERNS[@]}"; do
  if echo "$CMD" | grep -qF "$SAFE"; then
    exit 0
  fi
done

# install 트리거 여부 확인
IS_INSTALL=false
if echo "$CMD" | grep -qE '(^|[;&|]|\s)(npm\s+(install|i|update)|yarn\s+(install|add))(\s|$)'; then
  IS_INSTALL=true
fi

[ "$IS_INSTALL" = false ] && exit 0

# 패키지 매니저 자동 감지 (lockfile 존재 기반)
PKG_MANAGER=""
LOCKFILE=""
if [ -f "yarn.lock" ]; then
  PKG_MANAGER="yarn"
  LOCKFILE="yarn.lock"
elif [ -f "package-lock.json" ]; then
  PKG_MANAGER="npm"
  LOCKFILE="package-lock.json"
fi

# package.json 없는 디렉토리면 무시
[ ! -f "package.json" ] && exit 0

# ── 상황별 처리 ─────────────────────────────────────────────

# 1. lockfile 없음 → BLOCK
if [ -z "$LOCKFILE" ]; then
  echo ""
  echo "⛔ [npm-supply-chain] BLOCKED: lockfile이 없습니다."
  echo ""
  echo "   lockfile 없이 install하면 패키지 매니저가 semver 범위 내 최신 버전을"
  echo "   새로 해석합니다. 이는 Axios 2026 같은 공급망 공격의 진입점이 됩니다."
  echo ""
  echo "   권장 조치:"
  echo "   1. 안전한 버전으로 lockfile을 먼저 생성하세요."
  echo "   2. lockfile을 git에 커밋하세요."
  echo "   3. 이후 'npm ci --ignore-scripts' 를 사용하세요."
  echo ""
  exit 2
fi

# 2. yarn add → 새 패키지 추가 경고
if echo "$CMD" | grep -qE '(yarn\s+add)'; then
  echo ""
  echo "⚠️  [npm-supply-chain] 새 의존성을 추가합니다."
  echo ""
  echo "   추가 전 확인 사항:"
  echo "   - 패키지 출처(GitHub, npm 레지스트리)를 확인했나요?"
  echo "   - 설치 후 'npm audit' 또는 'yarn audit'를 실행하세요."
  echo "   - package.json의 semver 범위를 가능하면 정확한 버전으로 고정하세요."
  echo ""
  exit 0
fi

# 3. npm ci (--ignore-scripts 없음) → 경고
if echo "$CMD" | grep -qE '(^|[;&|]|\s)npm\s+ci(\s|$)'; then
  echo ""
  echo "⚠️  [npm-supply-chain] 'npm ci'에 '--ignore-scripts' 추가를 권장합니다."
  echo ""
  echo "   postinstall 같은 설치 스크립트는 공급망 공격의 실행 지점입니다."
  echo "   권장: npm ci --ignore-scripts"
  echo ""
  echo "   (설치 스크립트가 꼭 필요한 패키지가 있다면 이 경고를 무시하세요.)"
  echo ""
  exit 0
fi

# 4. npm install (npm ci 아님) → 경고
if echo "$CMD" | grep -qE '(^|[;&|]|\s)npm\s+(install|i|update)(\s|$)'; then
  echo ""
  echo "⚠️  [npm-supply-chain] 'npm install' 대신 'npm ci --ignore-scripts' 사용을 권장합니다."
  echo ""
  echo "   'npm install'은 lockfile을 갱신할 수 있습니다."
  echo "   'npm ci'는 lockfile을 엄격히 준수하므로 의도치 않은 버전 변경을 방지합니다."
  echo ""
  echo "   권장: npm ci --ignore-scripts"
  echo ""
  exit 0
fi

# 5. yarn install → 경고
if echo "$CMD" | grep -qE '(^|[;&|]|\s)yarn\s+install(\s|$)'; then
  echo ""
  echo "⚠️  [npm-supply-chain] 'yarn install --immutable --ignore-scripts' 사용을 권장합니다."
  echo ""
  echo "   --immutable: lockfile 변경 방지"
  echo "   (Yarn Berry) enableScripts: false 설정으로 postinstall 스크립트를 비활성화할 수 있습니다."
  echo ""
  exit 0
fi

exit 0
