#!/bin/bash -eux

cd $(dirname $0)

DUMP=../tmp/$(date "+%y%m%d-%H%M%S").dump
ssh buckybox-core -C "pg_dump -F c -v -h core-production.cbqr8ikjw2qk.eu-west-1.rds.amazonaws.com -p 5432 -U buckybox -d core_production" > $DUMP
dropdb bucky_box_development && createdb bucky_box_development && pg_restore -F c -d bucky_box_development -O $DUMP
echo Done
