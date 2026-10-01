#!/bin/bash
# Мониторинг ресурсов. Дописывает в monitor.log вывод free -h, df -h и uptime с меткой времени

LOG_FILE="monitor.log"
NOW=$(date "+%Y-%m-%d %H:%M:%S")

echo "--- $NOW ---" >> "$LOG_FILE"
free -h >> "$LOG_FILE"
df -h >> "$LOG_FILE"
uptime >> "$LOG_FILE"
