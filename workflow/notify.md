# Notifications
> Load when: a job runs > ~10 min, or a failure needs a human.

- Tool: `dc-notify` (`-h` for help). Embed with outcome title; `-s ok|fail|warn|run`; fields `-F "k|v"`; links `-b "label|url"`.
- Send on long-job start + end, and on failures needing a human.
- `-p` pings @sx66 (818166724641030193): critical only.
