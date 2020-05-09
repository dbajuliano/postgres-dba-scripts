#!/bin/bash

# Refresh Materialized View script to be scheduled as a Cron job
# Author www.github.com/julianodba on 07/05/2020

pg_dir=/usr/pgsql-11/bin

# Postgres connection
db_ip=localhost
db_port=$1 # provide on cron job line to any pg instances running in different ports
db_user=postgres
db_name=postgres

# List of views in an array format
views=("public.mview_queries" "public.mview_trx" "public.mview_tests")

logfile=/var/log/mviews.log

function run()
{
    echo -e "[$(date "+%Y-%m-%d - %H:%M:%S")] : $0 : Started\n"

    for i in "${views[@]}"
    do
        echo "REFRESHING $i"

        $pg_dir/psql --no-psqlrc -h $db_ip -p $db_port -U $db_user -c '\timing' -c "REFRESH MATERIALIZED VIEW $i;" $db_name

        echo

    done

    echo -e "[$(date "+%Y-%m-%d - %H:%M:%S")] : $0 : Finished\n"
    echo -e "-------------------------------------------------\n"
}

run >> $logfile 2>&1

exit 0
