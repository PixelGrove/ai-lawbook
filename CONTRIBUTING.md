# 기여 안내 · Contributing

[한국어](#한국어) · [English](#english)

## 한국어

### 새 법 제안
1. 먼저 [법 제안 이슈](../../issues/new?template=law-proposal.yml)로 직무, AI가 실제로 저지르는 실패, 지켰는지 확인하는 방법을 알려 주세요.
2. `ai-lawmaker` 로 [표준 골격](plugins/ai-lawbook/skills/ai-lawmaker/references/law-skeleton.md)에 맞춰 초안을 씁니다.
3. 한국어판(`plugins/ai-lawbook/skills/<name>/`)과 영어판(`plugins/ai-lawbook-en/skills/<name>/`)을 **같은 조 번호**로 함께 올립니다.
   `agents/openai.yaml` 도 두 판 모두 넣습니다.
4. 입법 스킬의 선례 표(두 판의 `ai-lawmaker/SKILL.md` 제2조)와 README 법 표에 새 법을 넣습니다.
5. `bash tests/run.sh` 가 `all checks passed` 로 끝나는지 확인합니다.

### 훅 수정
- `hooks/inject.sh` 와 `hooks/guard.sh` 는 두 플러그인에 **똑같은 파일**로 둡니다(테스트가 비교합니다).
- macOS 기본 bash 3.2 에서도 돌아야 합니다. `${var,,}` 같은 bash 4 문법을 쓰지 마세요.
- 훅은 실패하면 통과시킵니다(fail-open). 프롬프트나 도구 호출을 막는 실패를 만들지 마세요.
- 바꾼 동작마다 `tests/run.sh` 에 회귀 테스트를 넣어 주세요.

### 기여의 라이선스
이 저장소에 보내는 기여(PR, 패치)에는 저장소의 라이선스([LICENSE](LICENSE), MIT + Commons Clause)가 적용됩니다.
기여하면, 저작권자가 앞으로 나올 판의 라이선스를 바꿀 수 있다는 데 동의한 것으로 봅니다. 동의하지 않으면 PR 에 적어 주세요.

## English

### Proposing a law
1. Open a [law proposal issue](../../issues/new?template=law-proposal.yml) with the role, the failure AI actually commits, and how compliance is checked.
2. Draft it with `ai-lawmaker` on the [standard skeleton](plugins/ai-lawbook-en/skills/ai-lawmaker/references/law-skeleton.md).
3. Ship the Korean edition (`plugins/ai-lawbook/skills/<name>/`) and the English edition (`plugins/ai-lawbook-en/skills/<name>/`)
   with the **same article numbering**, each with `agents/openai.yaml`.
4. Add the law to the precedent table (Article 2 of `ai-lawmaker/SKILL.md` in both editions) and to the README law table.
5. Make sure `bash tests/run.sh` ends with `all checks passed`.

### Changing the hooks
- Keep `hooks/inject.sh` and `hooks/guard.sh` **identical** in both plugins (the tests compare them).
- They must run on macOS's stock bash 3.2. Avoid bash 4 syntax such as `${var,,}`.
- The hooks fail open. Never introduce a failure that blocks a prompt or a tool call.
- Add a regression test to `tests/run.sh` for every behavior you change.

### License of contributions
Contributions (PRs, patches) are made under this repository's license ([LICENSE](LICENSE), MIT with the Commons
Clause), and you agree that the copyright holder may change the license of future versions. If you do not agree,
say so in the PR.
