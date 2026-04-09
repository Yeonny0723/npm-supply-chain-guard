# npm 공급망 공격과 Axios 2026 사례 정리

## 사건 요약

2026년 3월 31일, Axios 유지보수 계정이 탈취되며 악성 버전 `axios@1.14.1`, `axios@0.30.4`가 npm에 게시되었습니다.
두 버전은 하위 의존성 `plain-crypto-js@4.2.1`을 끼워 넣어 설치 시점에 RAT(원격 제어 악성코드) 다운로드 스크립트를 실행했습니다.

핵심 메시지: **위험은 실행 코드에서만 시작되지 않고 `npm install` 또는 `yarn install` 자체에서 시작될 수 있습니다.**

## 문제 배경: npm 공급망 공격이란

우리가 직접 설치한 패키지 하나가 다시 다른 패키지에 의존하면서 트리를 타고 내려갑니다.  
예를 들어 `my-sdk`가 `axios`를, `axios`가 하위 의존성으로 `plain-crypto-js`를 끌어오는 형태입니다.

공격자는 라이브러리 내부 로직을 크게 바꾸지 않아도, 신뢰된 의존성 트리 어딘가에 악성 패키지를 심어 실행 지점을 만들 수 있습니다.

## 공격은 어떻게 진행되나

1. 공식 패키지 발행 계정/권한 탈취
2. 새 버전에 악성 의존성 추가
3. `npm install`/`npm update`/새 환경 세팅에서 해당 버전 설치
4. 설치 중 lifecycle script 실행
5. 토큰 탈취·원격 제어·추가 배포로 확산

## install-time code execution의 실무 포인트

- npm: `preinstall` / `install` / `postinstall` 실행 가능
- Yarn Classic/Yarn Berry 모두 설치 시 스크립트 실행 가능성 존재

특히 다수 공격은 `postinstall`에서 드러나며, `npm install` 자체가 공격면이 됩니다.

## 왜 특히 위험했나

- lockfile 미사용 새 설치 시 버전 재해석 폭증
- 느슨한 semver(`^`, `~`, `*`)로 악성 패치 버전이 즉시 선별될 수 있음
- 개발자/CI/자격증명 환경 침해가 내부망 및 파이프라인으로 확장

## 대응 원칙(요약)

1. **lockfile 고정** (`package-lock`, `yarn.lock`) 및 CI에서는 `npm ci`
2. **설치 스크립트 통제** (`--ignore-scripts`, Yarn 설정 등)
3. **감사 체계화** (`npm audit`, `yarn audit`, semver 검사, 의존성 트리 확인)
4. **비밀정보 최소권한**: 토큰 scope 축소, CI secret 최소화, publish/runtime 분리
5. 의심 사례는 `npm audit` 결과와 무관하게 침해 가정으로 대응

## 사고 의심 시

1. 문제 버전/의존성 존재 여부로 빠른 침해 가능성 판정
2. 감염 의심 환경 격리
3. 안전 버전으로 downgrade
4. 비밀값 회전 (GitHub/NPM/클라우드/SSH 등)
5. C2/비정상 통신 로그 조사
6. 필요 시 재이미징 또는 완전 재구축

## 실무 체크리스트(간단)

- [ ] lockfile을 커밋하고 CI에서 `npm ci` 사용
- [ ] `npm audit` 실행 후 경고/차단 정책 적용
- [ ] `loose semver`(`^`, `~`, `*`, `.x`) 단계적으로 축소
- [ ] 정기 감사 + 주간 스케줄 자동화
- [ ] CI secret 최소 권한/짧은 수명화

## 부록: 왜 1.14.1/0.30.4인가

두 버전은 정상 버전의 바로 다음 패치 버전이어서(`1.14.0`→`1.14.1`, `0.30.3`→`0.30.4`) 사용자 입장에서 자연스러운 패치 업데이트로 보였습니다.
또한 `^1.14.0`, `^0.30.0` 범위의 자동 수용 패턴이 넓어 다수 프로젝트에 빠르게 전파될 수 있었습니다.

## 참고

- Axios 사후 보고: https://github.com/axios/axios/issues/10636
- Microsoft 분석: https://www.microsoft.com/en-us/security/blog/2026/04/01/mitigating-the-axios-npm-supply-chain-compromise/
- npm scripts: https://docs.npmjs.com/cli/v8/using-npm/scripts/
- npm audit/ci: https://docs.npmjs.com/cli/v9/commands/npm-audit/ , https://docs.npmjs.com/cli/v11/commands/npm-ci/
- npm semver: https://docs.npmjs.com/about-semantic-versioning/
- Yarn 설정: https://yarnpkg.com/configuration/yarnrc
