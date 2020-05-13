# :elephant: postgres-dba-scripts
Daily scripts used on multi cluster environments with many hosts

Developed using CentOS 7 and Postgres 11

I would appreciate any collaboration and improvement

:closed_lock_with_key:.pgpass
---------------------
File sample 


:floppy_disk: pg_backup.sh
---------------------
Connection credentials are stored on [.pgpass](https://www.postgresql.org/docs/11/libpq-pgpass.html) file and should be auto-read

Cron syntax:
```
mm hh dd month weekday /path/to/script.sh hostname port username
```
The example below runs every midnight cron user replication on 02 different hosts:
```
00 00 * * * /opt/bin/pg_backup.sh primary.production.localhost 5432 replication
00 00 * * * /opt/bin/pg_backup.sh single.test.localhost 5433 replication
```
The example below exports the `.pgpass` credentials used on `/etc/crontab`:
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

:mag_right: find_user_multiple_hosts.sh
---------------------
The connection list with each host detail are stored on [.pgpass](https://www.postgresql.org/docs/11/libpq-pgpass.html) file. All you need is to provide a username to find during the execution time. I.e.: `/opt/bin/find_user_multiple_hosts.sh juliano`

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

:clipboard:refresh_materialized_view.sh
---------------------

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

# [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

# [![Buy Me Coffee](https://github.com/julianodba/Postgres-dba-scripts/blob/master/coffe.png)](https://www.paypal.me/julianotech)
