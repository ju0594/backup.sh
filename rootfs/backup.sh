#!/usr/bin/env bash
# Copyright (C) 2013 - 2020 Teddysun <i@teddysun.com>
# 
# This file is part of the LAMP script.
#
# LAMP is a powerful bash script for the installation of 
# Apache + PHP + MySQL/MariaDB/Percona and so on.
# You can install Apache + PHP + MySQL/MariaDB/Percona in an very easy way.
# Just need to input numbers to choose what you want to install before installation.
# And all things will be done in a few minutes.
#
# Description:      Auto backup shell script
# Description URL:  https://teddysun.com/469.html
#
# Website:  https://lamp.sh
# Github:   https://github.com/teddysun/lamp
#
# You must to modify the config before run it!!!
# Backup files and directories
# Backup file is encrypted with AES256-cbc with SHA1 message-digest (option)
# Auto transfer backup file to FTP server (option)
# Auto delete FTP server's remote file (option)
#
# Re-modified by ju0594

[[ $EUID -ne 0 ]] && echo "Error: This script must be run as root!" && exit 1

########## START OF CONFIG ##########

# Encrypt flag (true: encrypt, false: not encrypt)
ENCRYPTFLG=true

# WARNING: KEEP THE PASSWORD SAFE!!!
# The password used to encrypt the backup
# To decrypt backups made by this script, run the following command:
# openssl enc -aes256 -in [encrypted backup] -out decrypted_backup.tgz -pass pass:[backup password] -d -md sha1
BACKUPPASS="ju0594"

# Directory to store backups
LOCALDIR="/backup/"

# Temporary directory used during backup creation
TEMPDIR="/backup/temp/"

# File to log the outcome of backups
LOGFILE="/backup/backup.log"

# Below is a list of files and directories that will be backed up in the tar backup
# For example:
# File: /data/www/default/test.tgz
# Directory: /data/www/default/test
BACKUP[0]=""

# Number of days to store daily local backups (default 7 days)
LOCALAGEDAILIES="7"

# Delete FTP server's remote file flag (true: delete, false: not delete)
DELETE_REMOTE_FILE_FLG=true

# Upload to FTP server flag (true: upload, false: not upload)
FTP_FLG=true

# FTP server
# OPTIONAL: If you want upload to FTP server, enter the Hostname or IP address below
FTP_HOST=""

# FTP port
# OPTIONAL: If you want upload to FTP server, enter the FTP port below
FTP_PORT="21"

# FTP username
# OPTIONAL: If you want upload to FTP server, enter the FTP username below
FTP_USER=""

# FTP password
# OPTIONAL: If you want upload to FTP server, enter the username's password below
FTP_PASS=""

# FTP server remote folder
# OPTIONAL: If you want upload to FTP server, enter the FTP remote folder below
# For example: public_html
FTP_DIR=""

########## END OF CONFIG ##########

# Date & Time
DAY=$(date +%d)
MONTH=$(date +%m)
YEAR=$(date +%C%y)
BACKUPDATE=$(date +%Y%m%d%H%M%S)
# Backup file name
TARFILE="${LOCALDIR}""$(hostname)"_"${BACKUPDATE}".tgz
# Encrypted backup file name
ENC_TARFILE="${TARFILE}.enc"

log() {
    echo "$(date "+%Y-%m-%d %H:%M:%S")" "$1"
    echo -e "$(date "+%Y-%m-%d %H:%M:%S")" "$1" >> ${LOGFILE}
}

# Check for list of mandatory binaries
check_commands() {
    # This section checks for all of the binaries used in the backup
    BINARIES=( cat cd du date dirname echo openssl pwd rm tar )
    
    # Iterate over the list of binaries, and if one isn't found, abort
    for BINARY in "${BINARIES[@]}"; do
        if [ ! "$(command -v "$BINARY")" ]; then
            log "$BINARY is not installed. Install it and try again"
            exit 1
        fi
    done

    # check ftp command
    if ${FTP_FLG}; then
        if [ ! "$(command -v "lftp")" ]; then
            log "lftp is not installed. Install it and try again"
            exit 1
        fi
    fi
}

calculate_size() {
    local file_name=$1
    local file_size=$(du -h $file_name 2>/dev/null | awk '{print $1}')
    if [ "x${file_size}" = "x" ]; then
        echo "unknown"
    else
        echo "${file_size}"
    fi
}


start_backup() {
    [ "${BACKUP[*]}" == "" ] && echo "Error: You must to modify the [$(basename $0)] config before run it!" && exit 1

    log "Tar backup file start"
    tar -zcf ${TARFILE} ${BACKUP[*]}
    if [ $? -gt 1 ]; then
        log "Tar backup file failed"
        exit 1
    fi
    log "Tar backup file completed"

    # Encrypt tar file
    if ${ENCRYPTFLG}; then
        log "Encrypt backup file start"
        openssl enc -aes256 -in "${TARFILE}" -out "${ENC_TARFILE}" -pass pass:"${BACKUPPASS}" -md sha1
        log "Encrypt backup file completed"

        # Delete unencrypted tar
        log "Delete unencrypted tar file: ${TARFILE}"
        rm -f ${TARFILE}
    fi

    if ${ENCRYPTFLG}; then
        OUT_FILE="${ENC_TARFILE}"
    else
        OUT_FILE="${TARFILE}"
    fi
    log "File name: ${OUT_FILE}, File size: $(calculate_size ${OUT_FILE})"
}

# Tranferring backup file to FTP server
ftp_upload() {
    if ${FTP_FLG}; then
        [ -z "${FTP_HOST}" ] && log "Error: FTP_HOST can not be empty!" && exit 1
        [ -z "${FTP_USER}" ] && log "Error: FTP_USER can not be empty!" && exit 1
        [ -z "${FTP_PASS}" ] && log "Error: FTP_PASS can not be empty!" && exit 1
        [ -z "${FTP_DIR}" ] && log "Error: FTP_DIR can not be empty!" && exit 1

        local FTP_OUT_FILE=$(basename ${OUT_FILE})
        log "Tranferring backup file to FTP server"
        lftp ${FTP_USER}:${FTP_PASS}@${FTP_HOST} 2>&1 >> ${LOGFILE} <<EOF
lcd $LOCALDIR
cd $FTP_DIR
put $FTP_OUT_FILE
quit
EOF
        log "Tranferring backup file to FTP server completed"
    fi
}

# Get file date
get_file_date() {
    #Approximate a 30-day month and 365-day year
    DAYS=$(( $((10#${YEAR}*365)) + $((10#${MONTH}*30)) + $((10#${DAY})) ))

    unset FILEYEAR FILEMONTH FILEDAY FILEDAYS FILEAGE
    FILEYEAR=$(echo "$1" | cut -d_ -f2 | cut -c 1-4)
    FILEMONTH=$(echo "$1" | cut -d_ -f2 | cut -c 5-6)
    FILEDAY=$(echo "$1" | cut -d_ -f2 | cut -c 7-8)

    if [[ "${FILEYEAR}" && "${FILEMONTH}" && "${FILEDAY}" ]]; then
        #Approximate a 30-day month and 365-day year
        FILEDAYS=$(( $((10#${FILEYEAR}*365)) + $((10#${FILEMONTH}*30)) + $((10#${FILEDAY})) ))
        FILEAGE=$(( 10#${DAYS} - 10#${FILEDAYS} ))
        return 0
    fi

    return 1
}

# Delete FTP server's old backup file
delete_ftp_file() {
    local FILENAME=$1
    if ${DELETE_REMOTE_FILE_FLG} && ${FTP_FLG}; then
        lftp ${FTP_USER}:${FTP_PASS}@${FTP_HOST} 2>&1 >> ${LOGFILE} <<EOF
cd $FTP_DIR
rm $FILENAME
quit
EOF
        log "FTP server's old backup file name: ${FILENAME} has been deleted"
    fi
}

# Clean up old file
clean_up_files() {
    cd ${LOCALDIR} || exit

    if ${ENCRYPTFLG}; then
        LS=($(ls *.enc))
    else
        LS=($(ls *.tgz))
    fi

    for f in ${LS[@]}
    do
        get_file_date ${f}
        if [ $? -eq 0 ]; then
            if [[ ${FILEAGE} -gt ${LOCALAGEDAILIES} ]]; then
                rm -f ${f}
                log "Old backup file name: ${f} has been deleted"
                delete_gdrive_file ${f}
                delete_ftp_file ${f}
            fi
        fi
    done
}

# Main progress
STARTTIME=$(date +%s)

# Check if the backup folders exist and are writeable
if [ ! -d "${LOCALDIR}" ]; then
    mkdir -p ${LOCALDIR}
fi
if [ ! -d "${TEMPDIR}" ]; then
    mkdir -p ${TEMPDIR}
fi

log "Backup progress start"
check_commands
start_backup
log "Backup progress complete"

log "Upload progress start"
ftp_upload
log "Upload progress complete"

clean_up_files

ENDTIME=$(date +%s)
DURATION=$((ENDTIME - STARTTIME))
log "All done"
log "Backup and transfer completed in ${DURATION} seconds"
