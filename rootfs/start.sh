#! /bin/sh
#

[[ ! -f /backup/backup.sh ]] && cp /backup.sh /backup/backup.sh
[[ ! -f /backup/crontabs/root ]] && cp /crontab /backup/crontabs/root

crond -f -S -l 0 -c /backup/crontabs