#!/bin/bash
# Claude 응답 완료 시 macOS 알림 전송

osascript -e 'display notification "응답이 완료되었습니다." with title "Claude Code" sound name "Glass"'
