#!/usr/bin/env bash
#
# ai-lawbook 가드 훅 — 반성문 장부에 적힌 기계 규칙 줄을 도구 호출과 최종 응답에 집행한다.
#
# 왜 필요한가: 주입된 장부는 읽어도 잊을 수 있다. 같은 위반이 반복되면 장부 항목에 기계가 판정할 수
# 있는 규칙 줄을 적고, 이 훅이 하네스 단계에서 막거나 고친다. 규칙 줄이 없으면 아무것도 하지 않는다.
#
# 장부 항목(## [ 로 시작) 안 어디든, 줄 머리 그대로:
#   - 차단: <정규식>  / - Block: <regex>     PreToolUse(Bash): 따옴표 구간을 지운 명령과 따옴표 기호만 지운
#                                             명령이 둘 다 맞으면 거부. 빈 문자열에도 맞는 정규식은 무시한다
#   - 검사: 한국어    / - Check: korean      PreToolUse(Bash): 한글 없는 description 거부
#                                             Stop·SubagentStop: 코드를 뺀 최종 응답이 라틴 문자 40자 이상인데
#                                             한글이 없으면 한 번 되돌려 다시 쓰게 한다(stop_hook_active 면 통과)
#   - 검사: 비밀값    / - Check: secrets     PostToolUse(Bash): stdout·stderr 의 비밀값을 가려 모델에 넘긴다
# 안내 문구는 규칙 줄을 쓴 언어(한국어 머리/영어 머리)를 따른다. 두 플러그인이 같은 파일을 쓴다.
#
# 사용법: hooks.json 이 PreToolUse·PostToolUse(matcher Bash)·Stop·SubagentStop 에서 인자 없이 부른다.
# 입력은 표준입력의 훅 JSON(hook_event_name 으로 분기)이다.
#
# 실패 정책(fail-open): 장부가 없거나, 규칙 줄이 없거나, jq 가 없거나(또는 --rawfile 이 없는 1.5 이하),
# 입력이 깨졌으면 아무것도 출력하지 않고 exit 0. 가드가 고장 나도 작업을 막지 않는다.
# 원래 비밀값은 어디에도 쓰지 않는다(로그 없음, 바뀐 출력만 낸다).
set -uo pipefail

[ -n "${HOME:-}" ] || exit 0
LEDGER="${HOME}/.claude/ai-lawbook/confessions.md"
[ -r "$LEDGER" ] || exit 0
grep -Eq '^- (차단|Block|검사|Check): ' "$LEDGER" 2>/dev/null || exit 0
command -v jq >/dev/null 2>&1 || exit 0

read -r -d '' PROG <<'JQ'
# 장부 → [{title, fix, block: [{re, ko}], korean, secrets}] (korean·secrets 는 "ko"/"en"/null)
def entries:
  reduce ($ledger | split("\n")[] | rtrimstr("\r")) as $l
    ({fence: false, cur: null, out: []};
     if ($l | test("^\\s*```")) then .fence |= not
     elif .fence then .
     elif ($l | startswith("## [")) then
       .out += [.cur // empty] | .cur = {title: ($l | ltrimstr("## ")), fix: "", block: [], korean: null, secrets: null}
     elif ($l | test("^##? ")) then .out += [.cur // empty] | .cur = null
     elif .cur == null then .
     elif ($l | test("^- (시정 및 재발 방지|Correction and prevention):")) then .cur.fix = ($l | sub("^- [^:]*:\\s*"; ""))
     elif ($l | test("^- (차단|Block): ")) then
       ($l | sub("^- (차단|Block): "; "") | sub("\\s+$"; "")) as $re
       | if $re == "" then . else .cur.block += [{re: $re, ko: ($l | startswith("- 차단"))}] end
     elif ($l | test("^- (검사: 한국어|Check: [Kk]orean)\\s*$")) then .cur.korean = (if ($l | startswith("- 검사")) then "ko" else "en" end)
     elif ($l | test("^- (검사: 비밀값|Check: [Ss]ecrets)\\s*$")) then .cur.secrets = (if ($l | startswith("- 검사")) then "ko" else "en" end)
     else . end)
  | .out + [.cur // empty];

# 비밀값 이름(대소문자 무관): password·passwd·secret·token·api key·private key. 소문자가 이어지거나(tokenizer)
# 복수형이면(max_tokens·SECRETS) 비밀값 이름이 아니다. 앞뒤로 붙은 단어 글자는 키 이름의 일부다.
def secret_key: "[A-Za-z0-9_.-]*(?i:passw(?:or)?d|secret|token|api[_-]?key|private[_-]?key)(?![a-z])(?![Ss](?![A-Za-z0-9]))[A-Za-z0-9_.-]*";

# mask 의 규칙이 걸릴 수 있는 단서. jq 는 정규식을 호출마다 새로 컴파일하므로, 단서가 없는 출력과 줄은
# 규칙 9개를 돌리지 않고 넘긴다(실제 장부 기준 Bash 호출당 63ms → 23ms).
def secret_hint: "-----BEGIN|://\\S*@|(?i:authorization|bearer|passw(?:or)?d|secret|token|api[_-]?key|private[_-]?key)|(sk|rk)[-_]|gh[pousr]_|github_pat_|glpat-|xox[abposr]-|AKIA|ASIA|AIza|eyJ";

# 비밀값을 $t 로 바꾼다. PEM 개인키는 여러 줄이라 먼저 통째로 가리고, 나머지는 줄마다 본다.
# - DSN 의 user:비밀번호@ (user 는 비어도 된다. host:포트/… 는 비밀번호가 아니다), Authorization 헤더 값,
#   Bearer 토큰, 알려진 접두 토큰(sk-·ghp_·xoxb-·AKIA… 단어 중간의 task- 같은 것은 제외), JWT
# - 어디서든 KEY=값, "KEY": "값", --KEY 값
# - 줄 머리(들여쓰기·목록·diff·grep 접두 허용)의 KEY: 값 / KEY = 값 — 값이 함수 호출·첨자 식이면 코드로 보고
#   둔다(`token = get_token()`, `api_key = os.environ["API_KEY"]`).
def mask($t):
  if test(secret_hint) | not then . else
  ("[A-Za-z_$][A-Za-z0-9_.$]*[ \\t]*[(\\[].*[)\\]][ \\t]*[;,]?[ \\t]*$") as $code
  | gsub("(?<b>-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----)[\\s\\S]*?(?<e>-----END [A-Z0-9 ]*PRIVATE KEY-----|\\z)"; "\(.b)\n\($t)\n\(.e)")
  | split("\n") | map(if test(secret_hint) | not then . else
    gsub("(?<p>://[^:/\\s@]*:)(?![0-9]+(/|\\s|$))\\S+?@(?=[^@\\s/]+([/:?#\\s]|$))"; "\(.p)\($t)@")
    | gsub("(?<p>(?i:authorization)[\"']?[ \\t]*[:=][ \\t]*[\"']?([A-Za-z]+[ \\t]+)?)[^\\s\"',]+"; "\(.p)\($t)")
    | gsub("Bearer [A-Za-z0-9._~+/=-]{8,}"; "Bearer \($t)")
    | gsub("(?<![A-Za-z0-9_-])((sk|rk)[-_]|sk_live_|sk_test_|gh[pousr]_|github_pat_|glpat-|xox[abposr]-|AKIA|ASIA|AIza)[A-Za-z0-9_-]{16,}"; $t)
    | gsub("(?<![A-Za-z0-9_-])eyJ[A-Za-z0-9_-]{8,}\\.eyJ[A-Za-z0-9_-]{8,}\\.[A-Za-z0-9_-]*"; $t)
    | gsub("(?<k>\"" + secret_key + "\"[ \\t]*:[ \\t]*)\"[^\"]*\""; "\(.k)\"\($t)\"")
    | gsub("(?<k>" + secret_key + "=)(?!=)(\"[^\"]*\"|'[^']*'|[^\\s\"']+)"; "\(.k)\($t)")
    | gsub("(?<k>--" + secret_key + "[ \\t]+)(?![-<\"'])[^\\s\"']+"; "\(.k)\($t)")
    | sub("^(?<k>([^\\s:]+:([0-9]+:)?)?[-+ ]?[ \\t]*(- )?(export[ \\t]+)?[\"']?" + secret_key + "[\"']?[ \\t]*[:=][ \\t]*)(?!((await|new)[ \\t]+)?" + $code + ")[^ \\t].*$"; "\(.k)\($t)")
  end) | join("\n") end;

# 배열 끝에 하나를 붙인다. `.o += [$c]` 는 붙일 때마다 배열을 복사해 10만 자에서 7초가 넘는다.
def push($c): setpath(["o", (.o | length)]; $c);

# heredoc 연산자(<<WORD, <<-WORD, <<'WORD', <<"WORD", <<\WORD) 뒤의 종결 낱말과 <<- 여부. 아니면 빈 결과.
def heredoc_op: capture("^<<(?<d>-?)[ \\t]*\\\\?(?<q>['\"]?)(?<w>[A-Za-z_][A-Za-z0-9_.-]*)\\k<q>") | {w, tab: (.d == "-")};

# 문맥 스택: .st 는 칸을 지우지 않는 배열이고 .sn 이 쓰는 칸 수다(꺼낼 때 배열을 복사하지 않아 깊은 중첩도 빠르다).
# 한 칸: {k: "a"(산술 (( )) ) | "c"(명령 치환 $( ) ) | "b"(큰따옴표 안 백틱) | "p"(매개변수 확장 ${ }),
#         d: 괄호·중괄호 깊이, q: 그 문맥이 열릴 때의 따옴표 상태}.
def top_k: if .sn == 0 then "t" else .st[.sn - 1].k end;
def spush($e): setpath(["st", .sn]; $e) | .sn += 1;
def bump($n): (.sn - 1) as $i | setpath(["st", $i, "d"]; .st[$i].d + $n);
def spop: .st[.sn - 1].q as $oq | .sn -= 1 | .q = $oq;
# 괄호를 닫는다. 맨 위 문맥의 깊이가 0이 되면 꺼내고, 그 문맥이 열릴 때의 따옴표 상태로 돌아간다.
# 백틱 문맥은 괄호로 닫히지 않는다(다음 백틱에서 닫힌다).
def close_paren:
  if .sn == 0 then .
  elif top_k == "b" then (if .st[.sn - 1].d > 1 then bump(-1) else . end)
  else bump(-1) | if .st[.sn - 1].d <= 0 then spop else . end end;

# 역슬래시 이스케이프, 따옴표 구간, 주석을 지운다. jq 1.7 의 gsub·scan 은 일치 수에 대해 제곱이라(10만 자
# heredoc 명령에 14초, 훅 타임아웃 5초) 줄마다 한 번 훑는 상태 기계로 한다. 닫히지 않은 따옴표는 끝까지 지운다.
# 결과는 {text, ok}. 해석을 마쳤을 때 따옴표나 문맥이 열려 있거나 heredoc 상한에 걸렸으면 ok=false 이고, 그때
# 판정은 따옴표 기호만 지운 원문($unq)으로 한다(셸과 해석이 어긋났을 수 있으므로 막는 쪽으로 떨어진다).
# - 따옴표 밖 이스케이프: 역슬래시만 지우고 글자는 남긴다(`\pkill` 은 pkill 로 본다).
# - 주석: 따옴표 밖에서 줄 머리나 공백·;&|( 뒤에 오는 # 부터 줄 끝까지. 실행되지 않으므로 지운다. 앞 글자가
#   역슬래시로 이스케이프됐으면(`a\ #b`) 주석이 아니다. `${ }` 안의 # 도 주석이 아니다. `)` 바로 뒤의 # 는
#   `$(cmd)#tag` 처럼 낱말일 수도, 서브셸 뒤 주석일 수도 있으므로 지우지도 해석하지도 않고 그 줄 나머지를 남긴다.
# - heredoc 본문: 따옴표 상태를 바꾸지 않고 글자 그대로 남긴다. 본문 속 아포스트로피(it's)가 따옴표를 열어
#   종결 줄 뒤의 명령을 숨기지 못하게 한다. `bash <<EOF` 처럼 본문이 실행될 수 있으므로 검사 대상에는 남긴다.
#   종결 줄은 bash 와 같게 판정한다: << 는 줄 전체가 낱말과 같아야 하고, <<- 는 앞의 탭만 지운 뒤 같아야 한다.
#   줄 이음(줄 끝 역슬래시)으로 끝난 줄에서는 heredoc 을 열지 않는다.
# - 문맥: 산술 (( … ))·$(( … )) 안의 << 는 시프트라 heredoc 으로 보지 않는다. 명령 치환 $( … ) 와 큰따옴표 안
#   백틱은 바깥이 큰따옴표여도 따옴표 밖처럼 해석한다(`-m "$(cat <<'EOF' … EOF )"` 의 heredoc 을 알아본다). 큰따옴표
#   안의 명령 치환에서 연 heredoc 본문은 따옴표 안 글자처럼 데이터로 보고 지운다(커밋 메시지가 규칙 낱말을 언급해도
#   막지 않는다). 한 명령에서 기다리는 heredoc 은 64개까지만 보고, 넘으면 ok=false 다.
# - $'…' 안에서는 \' 가 이스케이프다($$'…' 의 $$ 는 PID 라 일반 작은따옴표로 본다).
def strip_quotes:
  reduce split("\n")[] as $line ({o: [], q: 0, e: false, st: [], sn: 0, h: null, pend: [], cap: false, cont: false};
    if .h != null then
      .h as $h
      | if ($line | rtrimstr("\r") | if $h.tab then sub("^\\t+"; "") else . end) == $h.w
        then .h = (.pend[0] // null) | .pend = .pend[1:]
        elif $h.data then .
        else reduce ($line | explode)[] as $x (.; push($x)) | push(10) end
    else
      ($line | explode) as $cs
      | reduce range(0; $cs | length) as $i (.c = false | .l = false | .x = false;
          $cs[$i] as $c | $cs[$i + 1] as $n | $cs[$i + 2] as $n2
          | if .c then .
            elif .l then push($c)
            elif .e then .e = false | .x = true | (if .q == 0 then push($c) else . end)
            else
              .x as $px | .x = false
              | if .q == 39 then (if $c == 39 then .q = 0 else . end)
                elif .q == 36 then (if $c == 92 then .e = true elif $c == 39 then .q = 0 else . end)
                elif $c == 92 then .e = true
                elif .q == 34 then
                  (if $c == 34 then .q = 0
                   elif $c == 36 and $n == 40 and $n2 != 40 then spush({k: "c", d: 0, q: 34}) | .q = 0 | push($c)
                   elif $c == 96 then spush({k: "b", d: 1, q: 34}) | .q = 0 | push($c)
                   else . end)
                elif $c == 96 and top_k == "b" then spop | push($c)
                elif top_k == "p" then
                  (if $c == 123 then bump(1) elif $c == 125 then (if .st[.sn - 1].d <= 1 then spop else bump(-1) end) else . end) | push($c)
                elif $c == 39 then (if $i > 0 and $cs[$i - 1] == 36 and ($i < 2 or $cs[$i - 2] != 36) and ($px | not) then .q = 36 else .q = 39 end)
                elif $c == 34 then .q = 34
                elif top_k == "a" then
                  (if $c == 40 then bump(1)
                   elif $c == 41 then close_paren
                   elif $c == 36 and $n == 40 and $n2 != 40 then spush({k: "c", d: 0, q: .q})
                   else . end) | push($c)
                elif $c == 36 and $n == 123 then spush({k: "p", d: 0, q: .q}) | push($c)
                elif $c == 40 and $n == 40 then spush({k: "a", d: 1, q: .q}) | push($c)
                elif $c == 36 and $n == 40 and $n2 != 40 then spush({k: "c", d: 0, q: .q}) | push($c)
                elif $c == 40 then (if .sn == 0 then . else bump(1) end) | push($c)
                elif $c == 41 then close_paren | push($c)
                elif $c == 35 and ($px | not) and $i > 0 and $cs[$i - 1] == 41 then .l = true | push($c)
                elif $c == 35 and ($px | not) and ($i == 0 or ($cs[$i - 1] | . == 32 or . == 9 or . == 59 or . == 38 or . == 124 or . == 40)) then .c = true
                elif $c == 60 and $n == 60 and $n2 != 60 and ($i == 0 or $cs[$i - 1] != 60) then
                  if (.pend | length) >= 64 then .cap = true | push($c)
                  else
                    (first($cs[$i:$i + 80] | implode | heredoc_op) // null) as $w
                    | push($c) | if $w then .pend += [$w + {data: any(.st[0:.sn][]; .q == 34)}] else . end
                  end
                else push($c) end
            end)
      # 줄 끝: 역슬래시 뒤 줄바꿈은 줄 이음이다. 따옴표 밖이면 줄바꿈을 남기고, 기다리는 heredoc 을 연다.
      | if .e then .e = false | .cont = true elif .q == 0 then push(10) | .cont = false else .cont = false end
      | if .q == 0 and .pend != [] and (.cont | not) then .h = .pend[0] | .pend = .pend[1:] else . end
    end)
  | {text: (.o | implode), ok: (.q == 0 and .sn == 0 and (.cap | not))};

def deny($why): {hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $why}};

entries as $E
# 컴파일되지 않거나 빈 문자열에도 맞는 정규식(`pkill|`, `.*`)은 버린다. 둘 다 모든 명령을 막는 실수다.
| [$E[] | . as $e | .block[] | . as $b | select(try ("" | test($b.re) | not) catch false) | . + {title: $e.title, fix: $e.fix}] as $B
| (first($E[] | .korean // empty) // null) as $KO
| (first($E[] | .secrets // empty) // null) as $SEC
| .hook_event_name as $ev
| if $ev == "PreToolUse" and .tool_name == "Bash" then
    # $unq: 따옴표 기호와 역슬래시만 지운 명령. $cmd: 따옴표 구간째 지운 명령(따옴표 안 글자는 데이터라 규칙에 걸리지
    # 않는다). 두 쪽 모두 맞아야 막는다 — `git stash drop "stash@{0}"` 처럼 따옴표 안 글자가 규칙의 예외
    # 조건(부정 전방탐색)을 채우는 경우를 오탐하지 않는다. 싼 $unq 로 먼저 거르고 $cmd 는 후보가 있을 때만 만든다.
    ((.tool_input.command // "") | tostring) as $raw
    | ($raw | explode | map(select(. != 34 and . != 39 and . != 92)) | implode) as $unq
    | [$B[] | . as $b | select(try ($unq | test($b.re)) catch false)] as $cand
    | (if $cand == [] then null
       else ($raw | strip_quotes | if .ok then .text else $unq end) as $cmd | first($cand[] | . as $b | select(try ($cmd | test($b.re)) catch false)) // null end) as $hit
    | ((.tool_input.description // "") | tostring) as $desc
    | if $hit then
        ($hit.fix | .[0:200] | sub("[.\\s]+$"; "")) as $fix
        | if $hit.ko then deny("반성문 장부 「\($hit.title)」의 차단 규칙(\($hit.re))에 걸렸다. 재발 방지: \($fix). 규칙을 끄려면 장부에서 그 줄을 지워라.")
          else deny("Blocked by the rule (\($hit.re)) in Confession Ledger entry \"\($hit.title)\". Prevention: \($fix). To turn the rule off, delete that line from the ledger.") end
      elif $KO and ($desc | test("\\S")) and ($desc | test("[가-힣]") | not) then
        if $KO == "ko" then deny("Bash description 을 한국어로 다시 써서 호출하라(반성문 장부 검사: 한국어).")
        else deny("Rewrite the Bash description in Korean and call again (Confession Ledger Check: korean).") end
      else empty end
  elif ($ev == "Stop" or $ev == "SubagentStop") and $KO and .stop_hook_active != true then
    # 앞 2만 자만 본다. gsub·scan 은 일치 수에 대해 제곱이라 긴 응답(10만 자)에 16초가 걸린다(타임아웃 5초).
    ((.last_assistant_message // "") | tostring | .[0:20000]
     | gsub("```[\\s\\S]*?(```|\\z)"; "") | gsub("`[^`\\n]*`"; "")) as $m
    | if ([$m | explode[] | select((. >= 65 and . <= 90) or (. >= 97 and . <= 122))] | length) >= 40
         and ($m | test("[가-힣]") | not) then
        {decision: "block", reason: (if $KO == "ko"
          then "최종 응답에 한국어가 없다. 다른 작업 없이 같은 내용을 한국어로 다시 써라(코드·명령·고유명사만 원문). 사용자가 이번 턴에 영어를 명시 요청했거나 기계 판독용 출력(JSON 등)이면 그대로 다시 내라."
          else "The final response has no Korean. Without doing anything else, rewrite the same content in Korean (keep only code, commands, and proper nouns as is). If the user explicitly asked for English this turn or the output is machine-readable (JSON etc.), output it again unchanged." end)}
      else empty end
  elif $ev == "PostToolUse" and .tool_name == "Bash" and $SEC and (.tool_response | type) == "object" and .tool_response.isImage != true then
    (if $SEC == "ko" then "<가림>" else "<redacted>" end) as $t
    # 있는 문자열 필드만 바꾸고 키를 더하지 않는다. 모양이 원래 출력과 다르면 하네스가 교체를 무시해
    # 가리지 않은 원문이 그대로 모델에 간다(문서: 내장 도구는 출력 스키마가 맞아야 한다).
    | .tool_response as $r
    | ($r | with_entries(if (.key == "stdout" or .key == "stderr") and (.value | type) == "string"
                         then .value |= mask($t) else . end)) as $n
    | if $n != $r then {hookSpecificOutput: {hookEventName: "PostToolUse", updatedToolOutput: $n}} else empty end
  else empty end
JQ

out="$(jq -c --rawfile ledger "$LEDGER" "$PROG" 2>/dev/null)" || exit 0
[ -n "$out" ] && printf '%s\n' "$out"
exit 0
