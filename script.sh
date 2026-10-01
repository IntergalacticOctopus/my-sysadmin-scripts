#!/bin/bash
# Мониторинг ресурсов. Раз в INTERVAL секунд дописывает в monitor.log вывод free -h, df -h и uptime с меткой времени

LOG_FILE="monitor.log"
INTERVAL=3

# Проверка: нужные команды есть в системе
for cmd in free df uptime; do
  if ! command -v "$cmd" > /dev/null; then
    echo "Ошибка: не найдена команда $cmd" >&2
    exit 1
  fi
done

# Проверка: в лог-файл можно писать
if ! touch "$LOG_FILE" 2> /dev/null || [ ! -w "$LOG_FILE" ]; then
  echo "Ошибка: нет прав на запись в $LOG_FILE" >&2
  exit 1
fi

# Корректная остановка по Ctrl+C (INT) или команде kill (TERM)
stop_monitoring() {
  echo "--- $(date "+%Y-%m-%d %H:%M:%S") мониторинг остановлен ---" >> "$LOG_FILE"
  echo
  echo "Мониторинг остановлен"
  exit 0
}
trap stop_monitoring INT TERM

echo "Мониторинг запущен: интервал $INTERVAL с, лог $LOG_FILE. Остановка — Ctrl+C"

while true; do
  NOW=$(date "+%Y-%m-%d %H:%M:%S")
  echo "--- $NOW ---" >> "$LOG_FILE"
  free -h >> "$LOG_FILE"
  df -h >> "$LOG_FILE"
  uptime >> "$LOG_FILE"
  sleep "$INTERVAL"
done
