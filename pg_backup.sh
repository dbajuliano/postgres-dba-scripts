#!/bin/bash

# Physical backup using pg_basebackup on stream mode -Xs
# Remove old directories according to specified date interval
# Compress backup using tar and pigz removing the fresh backup "/backup/postgres" folder
# Clean old archives already into the fresh backup
# Added -R option to save the recovery.conf, might useful keep it on the backup

# Postgres connection
bak_user=$1
db_ip=$2
db_port=$3

# Postgres directories
pg_dir=/usr/pgsql-11/bin
pg_archive=/postgres/pg_archive

timestamp=$(date "+%Y.%m.%d-%H.%M.%S") # static predefined to match all dir names and pg_archivecleanup label

# Backup directories
bak_path=/backup/
bak_fresh=$bak_path/postgres # temp directory
bak_dir_tar=$bak_path/$timestamp # deleted according to the rotation interval of days
bak_logs=$bak_path/backup_logs/$timestamp.log

uniq_label="Backup $timestamp" # used by pg_archivecleanup

# FUNCTIONS
function backup()
{
    if [ -d "$bak_fresh" ]; then
        rm -rf $bak_fresh
        echo "[$(date "+%Y-%m-%d - %H:%M:%S")] : $0 : Removed pre-existent temp backup directory $bak_fresh"
    fi

    echo "[$(date "+%Y-%m-%d - %H:%M:%S")] : $0 : Performing base backup on $bak_fresh"
    $pg_dir/pg_basebackup -h $db_ip -p $db_port -U $bak_user -Xs -R -l "$uniq_label" -D $bak_fresh
}

function compress()
{
    mkdir $bak_dir_tar
    if [ $? -ne 0 ] ; then
        exit 2
    else
       echo "[$(date "+%Y-%m-%d - %H:%M:%S")] : $0 : Created compressed backup directory $bak_dir_tar"
    fi

    echo "[$(date "+%Y-%m-%d - %H:%M:%S")] : $0 : Move compressing $bak_fresh into $bak_dir_tar"
    tar -cf - -C $bak_path postgres --remove-files | pigz -4 -p 4 > $bak_dir_tar/postgres.tar.gz
    # - (dash) = Use outputted content from "/backup/postgres" dir
    # -C = Creation of tarball without the full path. tar will ignore $bak_path and use just "postgres" dir
    # --remove-files = remove the uncompressed postgres folder after compression
    # | pigz = Multiple commands are combined into a single process, which will concatenate the stdout of them.
    # -4 = compression level (0 to 9), 6 is the default
    # -p 4 = process n (4 thread processors)

    # How to manually extract in a custom target dir
    # unpigz -p 8 < /backup/2020.05.10-13.12.02/postgres.tar.gz | tar -xvC /backup/ #it will create the subdir "postgres"
}

function clean()
{
    echo "[$(date "+%Y-%m-%d - %H:%M:%S")] : $0 : Cleaning compressed backup directories older than 4 days"

    find $bak_path/* -type d -ctime +3 | xargs rm -rf;
    #find $bak_path/backup_logs/ -name "*.log" -type f -mtime +7 -exec rm {} \; # Optional clean log files

    # Find last archive file belongs to this backup
    filename=$(grep -l "$uniq_label" $pg_archive/*.backup | cut -c23-"$COLUMNS")

    # Clean old archived files already applied in this backup
    echo "[$(date "+%Y-%m-%d - %H:%M:%S")] : $0 : Deleting archives"
    $pg_dir/pg_archivecleanup $pg_archive $filename
    # -d debug output (verbose mode)

    echo "[$(date "+%Y-%m-%d - %H:%M:%S")] : $0 : Finished"
}

# Call functions and send the output to a log file
backup > $bak_logs 2>&1
compress >> $bak_logs 2>&1
clean >> $bak_logs 2>&1

exit 0
