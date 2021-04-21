#!/bin/bash

# Script to run port-forward on all databases and make them available to access by localhost or 127.0.0.1

function run(){
    
    # staging
    kubectl --context=staging -n dba port-forward --address 127.0.0.1 svc/pg-staging-01 5433:5432 &
    kubectl --context=staging -n dba port-forward --address 127.0.0.1 svc/pg-staging-02 5434:5432 &
    kubectl --context=staging -n dba port-forward --address 127.0.0.1 svc/mysql-staging-01 3307:3306 &
    kubectl --context=staging -n dba port-forward --address 127.0.0.1 svc/mysql-staging-02 3308:3306 &
 
    # production
    kubectl --context=production -n dba port-forward --address 127.0.0.1 svc/pg-production-01 5435:5432 &
    kubectl --context=production -n dba port-forward --address 127.0.0.1 svc/pg-production-02 5436:5432 &
    kubectl --context=production -n dba port-forward --address 127.0.0.1 svc/mysql-production-01 3309:3306 &
    kubectl --context=production -n dba port-forward --address 127.0.0.1 svc/mysql-production-02 3310:3306 &
    
    # other
    
}

run > /tmp/port-forward_k8s.log 2>&1
