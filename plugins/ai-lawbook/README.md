# AI 법전 (한국어판)

AI 에이전트에게 직무별 품질 기준을 법률 형식으로 집행하는 Claude Code 플러그인입니다.
개발자, 디자이너, 기획자, 마케터, 작가, 번역가, 데이터 분석가, 연구자, 고객지원, 교육자,
인사, 영업 12개 직무의 AI법, 모든 답변의 언어·구조·문장을 다루는 답변 AI법, 새 법을
제정·개정하는 입법 스킬 `ai-lawmaker` 를 담고 있습니다.

AI가 법을 어기면 로컬 파일 `~/.claude/ai-lawbook/confessions.md`(반성문 장부)에 반성문을 스스로 기록합니다.
SessionStart 훅은 세션마다, SubagentStart 훅은 하위 에이전트마다 그 장부와 시행 명부
(`~/.claude/ai-lawbook/enabled-laws`)에 적힌 법을 컨텍스트에 넣습니다(세션은 9,000자, 하위 에이전트는 6,000자를 넘으면 축약).
UserPromptSubmit 훅은 턴마다 재범이 가장 많은 반성문(최다 전과) 한 줄을 상기시키고, guard 훅은 장부에 적힌 기계 규칙 줄
(차단·한국어 검사·비밀값 가림)을 Bash 호출과 최종 응답에 집행합니다.

훅이 읽는 것은 위 두 로컬 파일, `~/.claude/skills` 와 이 플러그인 안의 법 파일,
그리고 Claude Code 가 검사용으로 넘겨준 그 호출의 내용뿐입니다. 네트워크 요청을 하지 않고 어떤 데이터도
외부로 보내지 않습니다.

설치(Claude Code 2.1.275 이상은 한 줄):

```text
/plugin install ai-lawbook --marketplace PixelGrove/ai-lawbook
```

라이선스: 1.4.0부터 MIT + Commons Clause(무료 사용·수정·공유 가능, 판매 금지). 자세한 내용과
설치·사용법·개인정보 안내는 저장소 README를 참고하세요: https://github.com/PixelGrove/ai-lawbook
