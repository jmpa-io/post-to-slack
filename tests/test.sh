#!/usr/bin/env bash
# tests run.sh against a stubbed curl; nothing is ever sent to Slack.
set -uo pipefail

root="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$root/.test-tmp"
rm -rf "$work"; mkdir -p "$work/bin"
trap 'rm -rf "$work"' EXIT

# a fake curl that records its arguments and replies with $STUB_RESPONSE.
cat > "$work/bin/curl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$STUB_LOG"
printf '%s' "$STUB_RESPONSE"
exit "${STUB_EXIT:-0}"
EOF
chmod +x "$work/bin/curl"

pass=0; fail=0
check() { # check <name> <expected-rc> <expected-output-regex> [env...]
  local name="$1" want_rc="$2" want_re="$3"; shift 3
  local out rc
  out=$(env -i PATH="$work/bin:$PATH" STUB_LOG="$work/log" \
    GITHUB_REPOSITORY=o/r GITHUB_RUN_ID=1 "$@" bash "$root/run.sh" 2>&1)
  rc=$?
  if [[ "$rc" -eq "$want_rc" && "$out" =~ $want_re ]]; then
    pass=$((pass + 1)); echo "ok   - $name"
  else
    fail=$((fail + 1)); echo "FAIL - $name (rc=$rc)"; echo "$out"
  fi
}

check "no inputs" 1 "missing input parameters: webhook or token status"
check "token without channel" 1 "missing input parameter: channel" \
  INPUT_TOKEN=t INPUT_STATUS=success
check "unknown status" 1 "missing weird implementation" \
  INPUT_WEBHOOK=http://x INPUT_STATUS=weird
check "webhook success, no GITHUB_SHA" 0 "Posting message to webhook" \
  INPUT_WEBHOOK=http://hook.test/x INPUT_STATUS=success STUB_RESPONSE=ok
check "webhook failure" 1 "non-successful message.*invalid_payload" \
  INPUT_WEBHOOK=http://hook.test/x INPUT_STATUS=failure \
  STUB_RESPONSE=invalid_payload
check "webhook curl error" 1 "failed curl" \
  INPUT_WEBHOOK=http://hook.test/x INPUT_STATUS=cancelled STUB_EXIT=7
check "bot error" 1 "non-successful message.*channel_not_found" \
  INPUT_TOKEN=xoxb-fake INPUT_CHANNEL=C123 INPUT_STATUS=success \
  STUB_RESPONSE='{"ok":false,"error":"channel_not_found"}'
check "bot success" 0 "Posting message to channel" \
  INPUT_TOKEN=xoxb-fake INPUT_CHANNEL=C123 INPUT_STATUS=success \
  STUB_RESPONSE='{"ok":true}'

# the bot request must target chat.postMessage with auth and the channel.
args="$(cat "$work/log")"
if [[ "$args" == *"chat.postMessage"* \
  && "$args" == *"Authorization: Bearer xoxb-fake"* \
  && "$args" == *'"channel": "C123"'* ]]; then
  pass=$((pass + 1)); echo "ok   - bot request shape"
else
  fail=$((fail + 1)); echo "FAIL - bot request shape"; echo "$args"
fi

echo "passed=$pass failed=$fail"
[[ "$fail" -eq 0 ]]
