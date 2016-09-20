#!/bin/bash -eux

cd $(dirname $0)

DUMP=core/tmp/$(date "+%y%m%d-%H%M%S").dump
ssh buckybox-core -C "su postgres -c \"pg_dump -i -F c -b -v core_production\"" > $DUMP
dropdb bucky_box_development && createdb bucky_box_development && pg_restore -F c -d bucky_box_development -O $DUMP
echo Done
