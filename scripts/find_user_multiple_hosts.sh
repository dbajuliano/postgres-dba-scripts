#! /bin/bash

# This script needs to be executed in a machine that can access all your DB hosts
# Generally is a DBA machine or a HUB server with connection guaranteed on firewall and/or VPN 
# This script uses the file .pgpass as a map of all hosts and pass the conn parameters accordingly    

# It supports comments on .pgpass files ignoring and using awk to return 
# the necessary data only (hostname, port, dbuser) in a loop used by psql as a list to connect.
# Connections attempt are configured to timeout in 3secs if failed shows a default corresponding error msg
# Also shows the message "psql: timeout expired" if is blocked on the firewall or you are not in the correct network/VPN
# Author www.github.com/julianodba on 07/05/2020

pg_dir=/usr/pgsql-11/bin  # Optional: useful to change between different psql versions

username=$1

# Simple bash input argument check 
if [[ -z $username ]]
then
    echo "Invalid argument."
    echo "Please inform one valid username to start to search!"
    exit 1;
fi

if [[ $# -ne 1 ]]
then
    echo "Incorrect numbers of arguments supplied."
    echo "Please inform one valid username to start to search!"
    exit 1;
fi

# $desc="$(grep '^\#.*$' ~/.pgpass)" # optional to show the hosts description, not necessary if connect using clear hostnames instead of ip
awk -F ':' '/^[^#]/ { print $1,$2,$4 }' ~/.pgpass | while read ip port dbauser; do
echo "Host: $ip Port: $port"
PGCONNECT_TIMEOUT=3 $pg_dir/psql -c "SELECT usename as User FROM pg_user WHERE usename iLIKE '%${username}%'" -h $ip -p $port -U $dbauser -d postgres -A --no-psqlrc; 2>&1
echo -e "------------------------------\n"
Done

# You can replace the psql command to "DROP ROLE IF EXISTS ${username}" to transform this script in an auto-delete-user
# -A mean unaligned table output mode
# iLike is useful in this case to find username variants for a username for example on "juliano": adminjuliano, juliano_ro, su-juliano, etc..
