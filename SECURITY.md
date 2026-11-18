# 보안 제보 · Security

AI 법전의 훅은 사용자의 컴퓨터에서 실행되고, 모든 세션의 컨텍스트에 글을 넣습니다. 다음과 같은 문제를 찾으면 알려 주세요.

- guard 훅의 차단 규칙을 우회하는 방법(README 의 "한계"에 적힌 것 제외)
- 시행 명부나 반성문 장부를 통해 사용자가 통제하지 않는 글이 "이미 시행 중"인 법으로 주입되는 경로
- 비밀값 가림(`- 검사: 비밀값`)이 놓치는 흔한 형식
- 훅이 실패해 프롬프트나 도구 호출이 막히는 경우

**공개 이슈에 재현 방법을 바로 올리지 마세요.** GitHub 의 비공개 보안 제보
([Security → Report a vulnerability](../../security/advisories/new))를 써 주세요. 그 기능을 쓸 수 없으면
재현 방법을 빼고 "보안 제보 경로가 필요하다"는 이슈만 열어 주세요.

---

The hooks run on your machine and write into every session's context. Please report:

- ways around a guard block rule (other than the limits listed in the README)
- paths that inject text the user does not control as a law "already in force"
- common secret formats that `- Check: secrets` misses
- hook failures that block a prompt or a tool call

**Do not post reproduction steps in a public issue.** Use GitHub private vulnerability reporting
([Security → Report a vulnerability](../../security/advisories/new)). If that is unavailable, open an issue that
only asks for a private channel, without the details.
