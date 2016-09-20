#!/bin/bash -eux

staging="${1:-root@52.208.137.102}"
prod="${2:-root@188.166.64.22}"
db=core_staging

cd $(dirname $0)

ssh_no_key="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
DUMP=$(date "+%y%m%d-%H%M%S").dump

for path in system private_uploads; do
    ssh -A $staging "rsync -avzPh --delete --chown buckybox:buckybox -e \"$ssh_no_key\" ${prod}:/home/buckybox/core/shared/$path/ /home/buckybox/core/shared/$path"
done

#ssh buckybox-production -C "touch maintenance.html"
ssh $staging -A -C "$ssh_no_key $prod -- sudo -u postgres pg_dump -i -F c -b -v core_production > /tmp/$DUMP"
ssh $staging -C "/etc/init.d/unicorn-core stop; /etc/init.d/delayed_job-core stop; /etc/init.d/nginx stop; sleep 30"
ssh $staging -C "su postgres -c \"cd /tmp && dropdb -e $db && createdb -e -E utf8 -O buckybox $db && pg_restore -v -n public -F c -d $db /tmp/$DUMP\""
ssh $staging -C "rm -v /tmp/$DUMP"
ssh $staging -C "test -e /home/buckybox/core/current && { /etc/init.d/unicorn-core start; /etc/init.d/delayed_job-core start; /etc/init.d/nginx start; }"

echo Done
