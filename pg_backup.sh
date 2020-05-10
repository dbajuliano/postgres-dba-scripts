#!/bin/bash

# Physical backup using pg_basebackup on stream mode -Xs
# Remove old directories according to specified date interval
# Compress backup using tar and pigzip removing the fresh backup "pg" folder
# Clean old archives apllied to the fresh backup
# Added -R option to save the recovery.conf, might useful keep it on the backup
# Author www.github.com/julianodba on 07/05/2020

# Postgres connection
db_ip=$1
db_port=$2
bak_user=$3

# Postgres directories
pg_dir=/usr/pgsql-11/bin
pg_archive=/pg/pg_archive

# Backup directories
bak_path=/backup/
bak_fresh=$bak_path/pg # temp directory
bak_dir_tar=$bak_path/$(date "+%Y-%m-%d") # deleted according to the rotation interval of days
bak_logs=$bak_path/backup_logs/$(date "+%Y-%m-%d").log # read by zabbix+telegram

function backupProcess()
{
        echo "[$(date "+%Y-%m-%d - %H:%M:%S")] : $0 : Performing base backup"
        $pg_dir/pg_basebackup -h $db_ip -p $db_port -U $bak_user -Xs -R -l "Backup $(date +"%Y-%m-%d")" -D $bak_fresh

        echo "[$(date "+%Y-%m-%d - %H:%M:%S")] : $0 : Compressing backup"
        mkdir $bak_dir_tar
        tar -cf - -C $bak_path pg --remove-files | pigz -4 -p 4 > $bak_dir_tar/base.tar.gz # bug here
        # - (dash) = Use the outputed listed from "pg" dir
        # -C = Creation of a tarball without the full path. Note: there is a space between "$bak_path" and "pg"; tar will replace full path with just "pg"
        # --remove-files = remove the uncompressed pg folder after compression
        # | pigz = Multiple commands are combined into a single process, which will concatenate the stdout of them.
        # -4 = compression level (0 to 9), 6 is the default
        # -p 4 = process n (4 thread processors)

        # How to manually extract in a custom target dir
        # unpigz -p 8 < /backup/2020-05-07/base.tar.gz | tar -xC /backup/ #it will create "pg" dir

        echo "[$(date "+%Y-%m-%d - %H:%M:%S")] : $0 : Cleaning backups older then 2 days and logs optional"
        find $bak_path/* -type d -ctime +1 | xargs rm -rf;
        #find $bak_path/backup_logs/ -name "*.log" -type f -mtime +7 -exec rm {} \;

        # Set archive file name to be cleaned
        filename=$(grep -l "Backup $(date +"%Y-%m-%d")" $pg_archive/*.backup | cut -c14-"$COLUMNS")
        # If this script is executed more than once a day will cause conflict due to multiple archive files on pg_archivecleanup

        # Clean the archived files which are already applied in the new backup
        echo "[$(date "+%Y-%m-%d - %H:%M:%S")] : $0 : Deleting archives"
        $pg_dir/pg_archivecleanup $pg_archive $filename
        # -d generate debug output (verbose mode)

        echo "[$(date "+%Y-%m-%d - %H:%M:%S")] : $0 : Finish backup script"
}

# Call backup function and send the output to a log file
backupProcess > $bak_logs 2>&1

exit 0
