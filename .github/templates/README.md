<!-- markdownlint-disable MD041 MD010 MD034 -->
%BADGES%

%LOGO%

%NAME%

```diff
%DESCRIPTION%
```

* Inspired by https://github.com/8398a7/action-slack
* To learn about creating a custom GitHub Action like this, see [this doc](https://docs.github.com/en/free-pro-team@latest/actions/creating-actions/creating-a-docker-container-action).

## Usage

basic usage:
```yaml
- name: Notify Slack
  uses: jmpa-oss/notify-slack@v0.0.1
  with:
    webhook: ${{ secrets.SLACK_WEBHOOK_URL }}
    status: ${{ job.status }}
```

with if conditionals ([see doc](https://docs.github.com/en/free-pro-team@latest/actions/reference/context-and-expression-syntax-for-github-actions#job-status-check-functions)):
```yaml
- name: Notify Slack
  if: success() # accepts: success(), always(), cancelled(), failure()
  uses: jmpa-oss/notify-slack@v0.0.1
  with:
    webhook: ${{ secrets.SLACK_WEBHOOK_URL }}
    status: ${{ job.status }}
```

## Inputs

### (required) `webhook`

The Slack webhook to post to. This is created / managed
by a custom Slack App in your Slack workspace.

### (required) `status`

The status of the running GitHub Action job.

## Webhook?

* [To create the webhook used by this GitHub Action, follow the steps in this doc and create a custom Slack App for your Slack workspace.](https://api.slack.com/messaging/webhooks)

## Pushing new tag?

Using a <kbd>terminal</kbd>, run:

```bash
git tag v<version>
git push origin v<version>

# for example
git tag v0.0.1
git push origin v0.0.1
```

%SCRIPTS_TABLE%

%HOW_TO_USE_TEMPLATE%
