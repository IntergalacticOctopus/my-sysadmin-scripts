# my-sysadmin-scripts

Это скрипт мониторинга ресурсов. Раз в 10 секунд он дописывает в файл `monitor.log` блок с текущим временем и выводом команд `free -h`, `df -h` и `uptime`.

## Что лежит в репозитории

Сам скрипт находится в `script.sh`, а пример его работы можно посмотреть в `sample_output.txt`. Dockerfile собирает образ, в котором скрипт работает вместе с простым HTTP-сервером на порту 8080, а `docker-compose.yml` позволяет запустить то же самое через Docker Compose. В папке `deploy` лежат настройки для сервера: конфиг Nginx и systemd-служба.

## Как запустить скрипт

```bash
chmod +x script.sh
./script.sh
```

Остановить скрипт можно через Ctrl+C, при этом в лог запишется отметка об остановке. Интервал и имя лог-файла задаются в начале `script.sh` константами `INTERVAL` и `LOG_FILE`.

Перед началом работы скрипт проверяет, что в системе есть нужные команды и что в лог-файл можно писать. Если что-то не так, он выводит понятную ошибку и завершается с кодом 1. По Ctrl+C или команде `kill` скрипт завершается корректно.

## Запуск в Docker

```bash
docker build -t my-script .
docker run -d -p 8080:8080 --name my-app my-script
curl http://127.0.0.1:8080/monitor.log
```

Через Compose всё запускается одной командой `docker compose up -d`.

## Развёртывание за Nginx с HTTPS

Nginx принимает запросы на портах 80 и 443, перенаправляет HTTP на HTTPS и передаёт запросы контейнеру на порт 8080. Для учебного стенда используется самоподписанный сертификат. Контейнер запущен как systemd-служба, поэтому после перезагрузки сервера он поднимается сам.

```bash
# сертификат
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/my-app.key -out /etc/ssl/certs/my-app.crt -subj "/CN=my-app.local"

# nginx
sudo cp deploy/nginx-my-app.conf /etc/nginx/sites-available/my-app
sudo ln -s /etc/nginx/sites-available/my-app /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# systemd
sudo cp deploy/my-app.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now my-app
```

Проверить работу можно двумя запросами. Команда `curl -kI https://<IP>` должна вернуть код 200, а `curl -I http://<IP>` вернёт 301 с перенаправлением на HTTPS.

## RAID и LVM

Дополнительных дисков на учебной машине нет, поэтому вместо них используются файлы, подключённые как loop-устройства. Из двух таких устройств собирается зеркальный массив RAID 1, а на третьем создаётся LVM-том, который потом расширяется прямо на ходу, без размонтирования.

```bash
cd /mnt/raid-lab
LOOP1=$(sudo losetup -fP --show disk1.img)
LOOP2=$(sudo losetup -fP --show disk2.img)
LOOP3=$(sudo losetup -fP --show disk3.img)

sudo mdadm --create /dev/md0 --level=1 --raid-devices=2 "$LOOP1" "$LOOP2"
sudo mkfs.ext4 /dev/md0 && sudo mount /dev/md0 /mnt/raid

sudo pvcreate "$LOOP3" && sudo vgcreate vg_data "$LOOP3"
sudo lvcreate -L 200M -n lv_logs vg_data
sudo mkfs.ext4 /dev/vg_data/lv_logs && sudo mount /dev/vg_data/lv_logs /mnt/logs
sudo lvextend -r -L +100M /dev/vg_data/lv_logs
```
