#!/usr/bin/env bash
# posts a formatted message to a given Slack channel, via a given webhook.

# funcs.
die() { echo "$1" >&2; exit "${2:-1}"; }
diejq() { echo "$1" >&2; jq '.' <<< "$2"; exit "${3:-1}"; }

# check bash version.
[[ "${BASH_VERSION:0:1}" -lt 4 ]] \
  && die "bash version 4+ required"

# check deps.
deps=(curl jq)
for dep in "${deps[@]}"; do
  hash "$dep" 2>/dev/null || missing+=("$dep")
done
if [[ ${#missing[@]} -ne 0 ]]; then
  s=""; [[ ${#missing[@]} -gt 1 ]] && { s="s"; }
  die "missing dep${s}: ${missing[*]}"
fi

# check required parameters are given.
# https://docs.github.com/en/free-pro-team@latest/actions/reference/workflow-syntax-for-github-actions#jobsjob_idstepswith
webhook="$INPUT_WEBHOOK"
status="$INPUT_STATUS"
missing=()
[[ -z "$webhook" ]] && { missing+=("webhook"); }
[[ -z "$status" ]] && { missing+=("status"); }
if [[ ${#missing[@]} -ne 0 ]]; then
  [[ ${#missing[@]} -gt 1 ]] && { s="s"; }
  die "missing input parameter${s}: ${missing[*]}"
fi

# vars.
# https://docs.github.com/en/actions/learn-github-actions/environment-variables#default-environment-variables
commit="${GITHUB_SHA:0:7}" # use shorthand commit
commit="${commit:-commit}"
repo="${GITHUB_REPOSITORY:-repo}"
workflow="${GITHUB_WORKFLOW:-workflow}"
branch="${GITHUB_REF:-branch}"
branch="${branch/refs\/heads\//}"
event="${GITHUB_EVENT_NAME:-event}"
actor="${GITHUB_ACTOR:-actor}"
runId="${GITHUB_RUN_ID:-runId}"
buildNumber="${GITHUB_RUN_NUMBER:-buildNumber}"
date=$(TZ=Australia/Sydney date +"%Y-%m-%dT%H:%M:%S%:z") \
  || die "failed to get iso date"

# determine message status.
# https://docs.github.com/en/free-pro-team@latest/actions/reference/context-and-expression-syntax-for-github-actions#job-context
msg=""; color=""
case "$status" in
success)
  msg=":thumbsup::skin-tone-2: *<https://github.com/$repo|$repo> (<https://github.com/$repo/actions/runs/$runId|$workflow>) succeeded!*"
  color="#44E544"
  ;;
failure)
  msg=":thumbsdown::skin-tone-2: *<https://github.com/$repo|$repo> (<https://github.com/$repo/actions/runs/$runId|$workflow>) failed!*"
  color="#FF4C4C"
  ;;
cancelled)
  msg=":hand::skin-tone-2: *<https://github.com/$repo|$repo> (<https://github.com/$repo/actions/runs/$runId|$workflow>) cancelled!*"
  color="#FF7F50"
  ;;
*) die "missing $status implementation"
esac

# query to execute.
# shellcheck disable=SC2162
read -d '' q <<@
{
  "text": "$msg",
  "attachments": [
    {
      "color": "$color",
      "blocks": [
        {
          "type": "section",
          "fields": [
            {
              "type": "mrkdwn",
              "text": "*Branch:*\\\\n<https://github.com/$repo/tree/$branch|$branch>"
            },
            {
              "type": "mrkdwn",
              "text": "*Commit:*\\\\n<https://github.com/$repo/commit/$commit|$commit>"
            },
            {
              "type": "mrkdwn",
              "text": "*Triggered by:*\\\\n<https://github.com/$actor>"
            },
            {
              "type": "mrkdwn",
              "text": "*Event:*\\\\n$event"
            }
          ]
        },
        {
          "type": "context",
          "elements": [
            {
              "type": "mrkdwn",
              "text": "\`#$buildNumber\` | <https://github.com/$repo/actions/runs/$runId/workflow|:page_facing_up:> | :clock1: $date"
            }
          ]
        }
      ]
    }
  ]
}
@

# validate query is valid json.
[[ $(<<<"$q" jq '. | tojson') ]] \
  || die "query is an invalid json payload"

# post query to webhook.
# https://api.slack.com/messaging/webhooks
echo "##[group]Posting message to webhook"
resp=$(curl -s "$webhook" \
  -H "Content-type: application/json" \
  -d "$q") \
  || die "failed curl to post message to webhook"
[[ "$resp" != "ok" ]] \
  && die "non-successful message returned when posting message to webhook: $resp"
echo "##[endgroup]"
