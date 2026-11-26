---
id: conventions.workflow.notify
---
# Notifications
> Load when: a job runs > ~10 min, or a failure needs a human.

- Tool: `{{profile.notification_tool}}` (`-h` for help). Embed with outcome title; `-s ok|fail|warn|run`; fields `-F "k|v"`; links `-b "label|url"`.
- Send on long-job start + end, and on failures needing a human.
- `-p` pings the owner: critical only.
- Webhooks and user IDs live in the tool's local config (`$DC_WEBHOOK` or the user config dir); never in a repo.
