# cc/co 모델 선택 단순화 설계

## 목표

`cc`와 `co` 실행 시 각 CLI의 native `-m/--model` 옵션으로 모델을 지정한다.
모델 또는 reasoning tier를 명령 이름에 포함한 `cc-h`, `cc-m`, `cc-l`,
`co-h`, `co-m`, `co-l`은 모두 제거한다.

## 사용 방법

```shell
cc -m opus
cc --model claude-sonnet-4-6
co -m gpt-5.6-sol
co --model gpt-5.6-terra
```

모델을 지정하지 않은 `cc`와 `co` 호출은 현재 기본 모델 동작을 유지한다.
두 명령의 permission bypass 옵션도 그대로 유지한다.

## 구현

- `cc`는 현재 함수가 받은 인자를 Claude CLI에 그대로 전달하도록 유지한다.
- `co`는 현재 별칭이 받은 인자를 Codex CLI에 그대로 전달하도록 유지한다.
- Claude wrapper에서 `cc-h`, `cc-m`, `cc-l` 함수를 제거한다.
- Zsh 별칭에서 `co-h`, `co-m`, `co-l`을 제거한다.
- 제거된 wrapper를 설명하는 주석과 테스트 기대값을 함께 정리한다.
- `cco`, `ccz`, `cck`의 모델 선택 동작은 이번 범위에서 변경하지 않는다.

별도 모델 파서나 모델 목록 설정은 추가하지 않는다. 두 CLI가 이미 제공하는
`-m/--model` 계약을 그대로 사용하는 것이 가장 단순하고 CLI 업데이트와도
중복되지 않기 때문이다.

## 검증

제어된 fake `claude`와 `codex` 실행 파일로 생성된 Zsh 설정을 로드한 뒤 다음을
검증한다.

- `cc -m opus`가 Claude CLI에 permission bypass 옵션과 `-m opus`를 전달한다.
- `co -m gpt-5.6-sol`이 Codex CLI에 permission bypass 옵션과
  `-m gpt-5.6-sol`을 전달한다.
- 모델을 생략한 `cc`와 `co`도 기존 permission bypass 옵션으로 실행된다.
- 제거된 suffix 명령은 생성된 Zsh 환경에 존재하지 않는다.
- 관련 Nix 단위·통합 테스트와 포매팅 검사를 통과한다.
