#! /bin/sh
#

[[ ! -f /backup.sh/backup.sh ]] && cp /backup.sh /backup.sh/backup.sh
[[ ! -f /backup.sh/crontabs/root ]] && cp /crontab /backup.sh/crontabs/root

crond -f -S -l 0 -c /backup.sh/crontabs