#! /bin/sh
#

  
[[ ! -f /backup/backup.sh ]] && mkdir -p /backup && cp /backup.sh /backup/backup.sh
[[ ! -f /backup/crontabs/root ]] && mkdir /backup/crontabs && cp /crontab /backup/crontabs/root

crond -f -S -l 0 -c /backup/crontabs