#!/usr/bin/env bash
# Cursor stop → Claude notify-on-stop (macOS 알림)
osascript -e 'display notification "응답이 완료되었습니다." with title "Cursor" sound name "Glass"' 2>/dev/null || true
exit 0
