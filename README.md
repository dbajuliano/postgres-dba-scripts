# :elephant: postgres-dba-scripts
Welcome to my public scripts and notes repository

<br>

# :closed_lock_with_key: [.pgpass](.pgpass)
:heavy_exclamation_mark: Most of the scripts requires credentials stored on the file [.pgpass](https://www.postgresql.org/docs/11/libpq-pgpass.html) to access the databases

<br>

# :floppy_disk: [pg_backup.sh](scripts/pg_backup.sh)

Cron syntax:
```
mm hh dd month weekday /path/to/script.sh hostname port username
```
The example below runs every midnight cron user replication on 02 different hosts:
```
00 00 * * * /opt/bin/pg_backup.sh primary.production.localhost 5432 replication
00 00 * * * /opt/bin/pg_backup.sh single.test.localhost 5433 replication
```
Or as an alternative, we can use the `/etc/crontab` like the example below exporting the `.pgpass` credentials:
```
00 00 * * * postgres export PGPASSFILE=/home/replication/.pgpass | /opt/bin/pg_backup.sh localhost 5432 replication
```

Output:
```
[2020-05-10 - 13:12:02] : /opt/bin/pg_backup.sh : Performing base backup on new dir /backup/postgres
[2020-05-10 - 13:24:33] : /opt/bin/pg_backup.sh : Created compressed backup directory /backup/2020.05.10-13.12
[2020-05-10 - 13:24:33] : /opt/bin/pg_backup.sh : Compressing /backup/postgres into /backup/2020.05.10-13.12
[2020-05-10 - 13:33:49] : /opt/bin/pg_backup.sh : Cleaning compressed backup directories older than 4 days
[2020-05-10 - 13:33:50] : /opt/bin/pg_backup.sh : Deleting archives
[2020-05-10 - 13:33:50] : /opt/bin/pg_backup.sh : Finished
```
```
ls -l /backup/
2020.05.08-00.00
2020.05.09-00.00
2020.05.10-00.00
2020.05.11-00.00
backup_logs/
```

<br>

# :mag_right: [find_user_multiple_hosts.sh](scripts/find_user_multiple_hosts.sh)
All you need is to provide a username as parameter to find. I.e.: `/opt/bin/find_user_multiple_hosts.sh juliano`

Output:
```
Host: primary.production.local Port: 5432
user
juliano_readonly
juliano_admin
(2 rows)
------------------------------

Host: single.test.local Port: 5433
user
ro_juliano
su_juliano
(2 rows)
------------------------------

Host: demo.local Port: 5434
user
(0 rows)
------------------------------
```

<br>

# :clipboard: [refresh_materialized_view.sh](scripts/refresh_materialized_view.sh)

A Cron script with customized port in case of running multiple pg instances
```
00 2 * * * /opt/bin/refresh_materialized_view.sh localhost 5432
00 2 * * * /opt/bin/refresh_materialized_view.sh demo.local 5434
```

Output:
```
[2020-05-07 - 02:00:00] : /opt/bin/refresh_materialized_view.sh : Started

REFRESHING public.mview_queries
Timing is on.
REFRESH MATERIALIZED VIEW
Time: 315.307 ms

REFRESHING public.mview_trx
Timing is on.
REFRESH MATERIALIZED VIEW
Time: 574.408 ms

REFRESHING public.mview_tests
Timing is on.
REFRESH MATERIALIZED VIEW
Time: 142.555 ms

[2020-05-07 - 02:00:01] : /opt/bin/refresh_materialized_view.sh : Finished

-------------------------------------------------
```

<br>

# :watch: [idle_in_transaction.sql](scripts/idle_in_transaction.sql)

Just put the psql straightly on the cron job to find queries "idle in transaction" (running every 2 minutes below)
```
*/2 * * * * psql -h localhost -U postgres -d postgres -p 5432 --no-psqlrc -q -t -A -c "SELECT TO_CHAR(NOW(), 'DD-MM-YYYY HH:MI:SS'),pid,STATE,usename,client_addr,application_name,query FROM pg_stat_activity WHERE pid <> pg_backend_pid() AND STATE IN ( 'idle in transaction' ,'idle in transaction (aborted)', 'disabled' ) AND state_change < current_timestamp - '2 minutes'::INTERVAL" >> /var/log/pg_idle_tx_conn.log
```
* You can change the output symbol from ">>" to ">" if you want to reset the log file for each entry instead of increment the file otherwise would be recommended develop a log rotate plan, just in case
* A good strategy is to configure your alert system tool to read the log file on every change and send a notification
* Don't forget to create the log file with the correct permissions

Output:
```
20-07-2020 09:52:01|14779|idle in transaction|juliano|192.168.0.1|psql|SELECT 'Juliano detection test';
```

<br>

# ⏩ [port-forward_k8s.sh](scripts/port-forward_k8s.sh)
This script maps all database instances and ports using k8s ```port-forward``` from each remote environment to your local machine (```localhost``` or ```127.0.0.1```). It can be used also to access AWS RDS Aurora Postgres and MySQL instances.

If you don’t want to use a bash script you can use [kubefwd](https://github.com/txn2/kubefwd) instead.

1. Edit the script with your instances already configured to use ```port-forward``` on k8s and run the script ```./port-forward_k8s.sh```

Bonus: To list the service names and ports run ```kubectl --context=context-name-here -n dba get services```

Once the script is running you can using you prefred cli or gui on localhost.

2. To stop it list the opened ports ```ps -ef | grep kubectl``` and then just kill the connection you want ```kill -9 pid_here``` or all connections ```pkill -9 kubectl```

<br>

# ☸️ [k8s_sql_connect.sh](/scripts/k8s_sql_connect.sh)
Script to quick automate and direct connect to an AWS RDS instance using K8S pods
Run ```./k8s_sql_connect.sh --help``` to see how it works

# [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

# [![Buy Me Coffee](coffe.png)](https://www.paypal.me/julianotech)
