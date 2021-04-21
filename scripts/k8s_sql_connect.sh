#!/bin/bash
 
# Script to quick automate and direct connect to an RDS instance using K8S pods
# Database credentials are stored in this script, DON'T SHARE IT
 
set -eo pipefail
 
function usage() {
    echo ""
    echo "Usage:"
    echo "     ./psql_k8s.sh -i [instance] -c [context]"
    echo "Or   ./psql_k8s.sh -c [context] -i [instance]"
    echo ""
    echo "E.g. ./psql_k8s.sh -i pg-staging01 -c staging"
    echo "Or   ./psql_k8s.sh -c staging -i pg-staging01"
    echo ""
    echo "     -c, --context     EKS K8S context: staging | production"
    echo ""
    echo "     -i, --instance    1. staging --> pg-staging01 | mysql-staging01"
    echo "                       2. production --> pg-production01 | pg-production02 | mysql-production01" 
    echo ""
    echo "     -h, --help        This message"
    echo ""
}
 
while [ -n "$1" ]; do   
     case $1 in
        -i | --instance )
            shift
            instance=$1
            ;;
        -c | --context )
            shift
            context=optional_prefix-$1 # I use "optional_prefix" because all my contexts start with the word "k8s_"
            ;;
        -h | --help )
            usage
            exit 1
            ;;
    esac
    shift
done
 
# Sanity check
if [ -z "$instance" ]; then
    echo "-i ERROR: AWS RDS instance is missing."
    exit 1
fi
if [ -z "$context" ]; then
    echo "-c ERROR: EKS K8S context is missing."
    exit 1
fi
 
# set dba namespace
kubens dba
  
# staging
elif [ "$context" == "optional_prefix-staging" ] && [[ "$instance" =~ ^(pg-staging01|mysql-staging01)$ ]]; then
    kubectl config use-context $context
    pod=$(kubectl get pod -o name | grep my-pod-) # I use "my-pod-" because all my pods start with the word "dba-pod-"
    if [ "$instance" == "pg-staging01" ] ; then
        kubectl exec -it $pod -- env PGPASSWORD="**********" psql -h $instance.qwerty.us-east-1.rds.amazonaws.com -U pg_user -d db_name
        # PGPASSWORD is not recommended, please use .pgpass or .pg_service.conf
        exit 1
    fi
    if [ "$instance" == "mysql-staging01" ] ; then
              kubectl exec -it $pod -- mysql -h $instance.asdfgh.us-east-1.rds.amazonaws.com -u my_user -p"**********" db_name
        exit 1
    fi
     
# production
elif [ "$context" == "optional_prefix-production" ] && [[ "$instance" =~ ^(pg-production01|pg-production02|mysql-production01)$ ]]; then
    kubectl config use-context $context
    pod=$(kubectl get pod -o name | grep my-pod-)
    if [ "$instance" == "pg-production01" ] ; then
        kubectl exec -it $pod -- env PGPASSWORD="**********" psql -h $instance.zxcvbn.us-east-1.rds.amazonaws.com -U pg_user -d db_name
        exit 1
    fi
    if [ "$instance" == "pg-production02" ] ; then
        kubectl exec -it $pod -- env PGPASSWORD="**********" psql -h $instance.tyuiop.us-east-1.rds.amazonaws.com -U pg_user -d db_name
        exit 1
    fi
    if [ "$instance" == "mysql-production01" ] ; then
        kubectl exec -it $pod -- mysql -h $instance.fghjkl.us-east-1.rds.amazonaws.com -u my_user -p"**********" db_name
        exit 1
    fi
 
else
        echo "ERROR: RDS instance "$instance" or K8S context $context not found"
        exit 1
fi
