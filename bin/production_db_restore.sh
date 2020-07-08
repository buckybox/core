#!/bin/bash

set -euxo pipefail

cd $(dirname $0)

DUMP=../tmp/$(date "+%y%m%d-%H%M%S").dump
ssh buckybox-core -C "pg_dump -F c -v -h core-production.cbqr8ikjw2qk.eu-west-1.rds.amazonaws.com -p 5432 -U buckybox -d core_production" > $DUMP
dropdb -h 127.0.0.1 -U buckybox --if-exists bucky_box_development
createdb -h 127.0.0.1 -U buckybox bucky_box_development
pg_restore -F c -h 127.0.0.1 -U buckybox -d bucky_box_development --no-owner $DUMP
