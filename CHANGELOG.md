# 변경 이력 · Changelog

판마다 무엇이 바뀌었는지 적습니다. 날짜는 한국 시간(KST, UTC+9) 기준 배포일입니다. 각 법의 부칙 날짜는 조문을
확정한 날이라 배포일과 하루쯤 다를 수 있습니다.

## 1.6.0 — 2026-11-20

최근 PHP·Java·nginx에서 원격 코드 실행으로 이어질 수 있는 취약점(PHP2Shell, Java4Shell, NGINX2Root)이 잇따른 것을
계기로 보안 규칙을 손봤습니다. Prompted by the recent PHP2Shell, Java4Shell, and NGINX2Root vulnerabilities.

### 보안 AI법 신설 · New Security AI Law
- 13번째 직무 법 `security-ai-law` 를 한국어·영어로 추가했습니다. "보안 검사 해줘"처럼 보안 점검이나 취약점 대응을
  요청했을 때 적용합니다. 의존성·런타임 버전의 보안 공지와 CISA KEV 대조, 새 취약점의 영향 분석, 수정판과 임시 완화
  계획, 점검 보고 형식을 정하고, 기억만으로 한 "취약점 없음" 판정, 지어낸 CVE·버전, 근거 없는 스캐너 경고 끄기,
  허가 없는 스캔, 부작용을 숨긴 임시 완화를 막습니다. Added the Security AI Law for requested security checks and
  vulnerability response.

### 개발자 AI법 보안 개정 · Developer AI Law security amendment
- 제18조 제5항·제6항: 오류나 경고를 없애려는 경우를 포함해 보안 장치를 끄거나 약화하는 일(TLS 검증 끄기, 자격 증명을
  허용하는 CORS의 모든 출처 허용, CSP `unsafe-inline`, 쿠키 속성 제거, `--no-verify` 등)을 금지하고, 피할 수 없는
  예외는 사전 승인·제27조 기록·개발 환경 한정으로 묶었습니다.
- 제18조 제7항: 신뢰할 수 없는 입력(요청, 업로드, 외부 응답, 저장된 사용자 데이터, LLM 출력)을 셸·쿼리·`eval`·
  역직렬화·템플릿·경로·서버 쪽 요청·리다이렉트에 문자열로 이어 붙이지 못하게 하고 안전한 대안을 적었습니다.
- 제18조의2(의존성 안전) 신설: 패키지를 추가할 때 진짜 패키지인지와 `audit` 결과를 확인하고, 잠금 파일을 지우거나
  `--force` 같은 강제 옵션을 승인 없이 쓰지 못하게 했습니다. 보안 공지 조회와 취약점 대응은 코드 작업마다 하지 않고
  보안 AI법으로 넘겼습니다. Added Article 18-2 (Dependency Safety).
- 제2조 제5항, 제19조 제4항, 제24조(위반 등급), 최종 준법 체크리스트와 description을 함께 고쳤습니다.

### 그 밖 · Other
- 입법 스킬의 선례 표, README 법전 목록·배지, 플러그인 설명에 보안 AI법을 넣었습니다.

## 1.5.0 — 2026-11-19

### Agent Skills 규격과 다른 에이전트 · Agent Skills and other agents
- 모든 법의 프런트매터를 [Agent Skills](https://agentskills.io) 규격 필드만으로 쓰고 `license`·`compatibility` 를
  넣었습니다. `compatibility` 에는 세션마다 자동 적용과 guard 집행이 Claude Code 플러그인에서만 동작한다고 적었습니다.
  Every law now uses Agent Skills spec fields only, with `license` and `compatibility`.
- README 에 Codex·Cursor·Gemini CLI·GitHub Copilot 같은 다른 에이전트의 설치 안내(`npx skills add`,
  `~/.agents/skills/` 복사)와, 늘 적용하는 `AGENTS.md` 한 줄 예시를 넣었습니다.
- 법 본문을 다른 에이전트에서도 맞게 고쳤습니다. 프로젝트 지침 파일을 `CLAUDE.md`·`AGENTS.md` 등으로 넓히고,
  장부를 읽거나 쓸 수 없으면 사용자에게 알리게 하고, guard 규칙 줄은 Claude Code 플러그인 훅이 있을 때만
  집행된다고 밝혔습니다. 답변 AI법의 위젯·Artifact·archify·입력창 명령 규칙과 입법 스킬의 저장 위치 안내도 맞췄습니다.
- Codex 용 `agents/openai.yaml`: 영어판 짧은 설명을 64자 이하로, 한국어판 기본 프롬프트를 한국어로 바꿨습니다.

### 스킬 설명 · Skill descriptions
- 28개 스킬의 description 을 한국어 300자·영어 450자 이하로 맞췄습니다(합계 한국어 5,949→3,680자,
  영어 13,354→6,223자). Claude Code 는 스킬 목록에 문자 예산(모델 컨텍스트 창의 1%)을 두고, 넘치면 덜 쓰는
  스킬부터 설명을 빼고 이름만 보여 줍니다. 그래서 인사·영업·번역가·작가 AI법이 설명 없이 표시되던 문제를 줄였습니다.
  설명에서 뺀 다른 법과의 경계와 일반 대화 적용 조건은 각 법 제2조에 두었습니다. 경계가 이미 제1항에 있으면 그대로
  두고, 없던 것은 제1항이나 제5항에 넣었습니다.
- 영어판 입법 스킬 설명의 `<role>` 을 바꿨습니다. 설명 속 꺾쇠 괄호는 일부 플랫폼에서 XML 태그로 취급돼 거부되거나
  이스케이프됩니다.

### 테스트 · Tests
- Agent Skills 규격 검사(허용 필드, 이름 형식, YAML 안전성, 설명 길이, `compatibility`, `openai.yaml`)를 더해
  검사가 568개가 됐습니다.

## 1.4.0 — 2026-11-18

### 라이선스 · License
- 1.4.0부터 **MIT + Commons Clause**(무료 사용·수정·공유, 판매 금지)로 바꿨습니다. 1.3.0 이하는 MIT 그대로입니다.
  From 1.4.0 the license is MIT with the Commons Clause (free to use, change, and share; not for sale). 1.3.0 and earlier stay MIT.
- `NOTICE`, `TRADEMARKS.md`(이름·로고 사용 안내)를 추가했습니다. `plugins/archify/` 는 Apache-2.0 그대로입니다.
- `plugin.json` 의 license 를 `LicenseRef-MIT-Commons-Clause` 로 바꿨습니다.

### 훅 · Hooks
- **예산 재배분**: 짧은 법은 전문으로 넣고, 남은 예산을 긴 법에 나눠 줍니다. 축약되는 법도 몫이 남으면 조문 본문을
  앞에서부터 장·조 단위로 채웁니다. 예전에는 축약본이 몫과 상관없이 최우선 수칙·목차·체크리스트만 담아 예산의
  대부분을 남겼습니다. 예(한국어판 기준): 답변 AI법 + 짧은 규칙 + 장부 1건이면 주입이 약 2,000자에서 약 8,900자로 늘어납니다.
- **시행 명부**: 첫 줄의 BOM 을 지우고 대문자를 소문자로 읽습니다. 한 줄에 여러 이름을 쉼표나 공백으로 나눠 적을
  수도 있습니다. 건너뛴 이름은 까닭별로 나눠 알립니다(이름 형식이 틀림, 법전에 없음, 본문이 비어 있음). 서로 다른
  이름이 64개를 넘으면 그 사실도 알립니다. 명부는 awk 로 읽어 `tr` 이 없어도 동작합니다.
- **CRLF**: 줄 끝이 CRLF 인 법 파일에서 프론트매터(description)가 본문과 함께 주입되던 문제를 고쳤습니다.
  `.gitattributes` 로 줄 끝을 LF 로 고정했습니다.
- **fail-open**: 모든 훅 명령에 `|| true` 를 붙여, 훅이 깨져도 프롬프트와 도구 호출을 막지 않게 했습니다.
- **장부 건수**: 코드 펜스 안의 예시 항목을 세지 않습니다. 재범 횟수가 없거나 0회인 항목만 있으면, 턴마다 띄우는
  최다 전과 상기문을 내지 않습니다.
- **guard**: 주석(`# …`)이나 heredoc 본문(`<<`, `<<-`, `<<'EOF'`, `<<\EOF`) 안의 아포스트로피가 따옴표 시작으로
  읽혀, 그 뒤의 명령이 차단 규칙 검사에서 빠지던 문제를 고쳤습니다. heredoc 종결 줄은 bash 와 같게 판정하고,
  산술식 `(( … ))` 안의 `<<` 는 heredoc 으로 보지 않습니다. heredoc 본문은 실행될 수 있어 계속 검사하되, 큰따옴표 안
  `$( )` 에서 연 heredoc(커밋 메시지에 흔한 형태)은 데이터로 봅니다. 이스케이프한 공백 뒤의 `#`, `)` 뒤의 `#`,
  `$'…\'…'`, 따옴표 밖 이스케이프(`\pkill`), 큰따옴표 안 백틱, `${ }` 도 bash 처럼 읽습니다. 해석이 셸과 어긋난 채
  끝나면(닫히지 않은 따옴표·괄호) 따옴표 기호만 지운 원문으로 판정해 막는 쪽으로 떨어집니다.
  한 줄짜리 10만 자 명령과 깊이 5만의 `$(` 중첩도 5초 안에 판정합니다(배열 복사를 없앰).

### 문서 · Docs
- README 에 "왜 필요한가", 법 표의 명부 이름 열, "답변 형식도 법으로", 라이선스 안내를 넣었습니다.
- 입법 스킬의 선례 표에 답변 AI법을 넣었습니다. 플러그인 README 를 실제 훅 동작에 맞췄습니다.
- `CONTRIBUTING.md`, `SECURITY.md`, 이슈 템플릿을 추가했습니다.
- 답변 AI법: 제4장·제11조 제목과 description 을 고쳐, ASD-STE100 을 참고해 새로 쓴 비인증 규칙임을 밝혔습니다.
- 입법 스킬: 제8조 제3항(예산 재배분과 축약본 본문 채우기)과 제14조(명부 형식, 64개 상한)를 실제 훅 동작에 맞췄습니다.
- 저장소 주소를 `PixelGrove/ai-lawbook` 으로, 작성자 표기를 `Pixel._.Grove` 로 바꿨습니다. 옛 주소
  `jinyeong03/ai-lawbook` 은 GitHub 가 새 주소로 넘겨 줍니다.

## 1.3.0 — 2026-10-28
- 답변 AI법(한국어·영어)을 신설했습니다. 문장 규칙은 ASD-STE100 원칙을 참고했고, 구조도는 archify 로 그립니다.
- archify(tt-a1i/archify, Apache-2.0)의 수정하지 않은 사본을 마켓플레이스에 넣었습니다.

## 1.2.0 — 2026-10-26
- 주입 예산(9,000자, 하위 에이전트 6,000자)과 축약 주입, 최우선 수칙, UserPromptSubmit 최다 전과 상기문을 넣었습니다.
- guard 훅(차단·한국어 검사·비밀값 가림)으로 장부의 기계 규칙 줄을 집행합니다.

## 1.1.0 — 2026-09-29
- SubagentStart 훅으로 하위 에이전트에도 법과 반성문 장부를 넣습니다.

## 1.0.0 — 2026-09-27
- 직무 AI법 12종(한국어·영어), 입법 스킬 `ai-lawmaker`, 반성문 장부, SessionStart 주입 훅으로 처음 공개했습니다.
