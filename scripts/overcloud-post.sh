#!/bin/bash

set -eux

source environment

source stackrc 

echo "###############################################"
echo "$(date) Starting overcloud post operations"

echo "$(date) Configuring ssh client"
cat >> ~/.ssh/config <<EOF
Host 192.0.2.*
StrictHostKeyChecking no
UserKnownHostsFile=/dev/null
User heat-admin
port 22 
EOF

chmod 600 /home/stack/.ssh/config

echo "$(date) Generating sosreports"

# Getting sos package
sudo yum reinstall --downloadonly  --downloaddir=. sos

mkdir -p /tmp/sosreports
for i in $(nova list | grep overcloud  | awk '{ print $12; }' | cut -f2 -d=)
do
 $SCP ./sos*.rpm $i:
 $SSH $i "sudo rpm -Uvh --force sos*.rpm; sudo sosreport --batch; sudo mv -v /var/tmp/sosre*xz /tmp; sudo chmod 644 /tmp/sosrep*xz"
 $SCP $i:/tmp/sosrep*xz /tmp/sosreports/
done

sudo sosreport --batch || true
sudo mv /var/tmp/sosre*xz /tmp/sosreports || true
sudo chmod 644 /tmp/sosreports/*

## WORKAROUND per https://bugzilla.redhat.com/show_bug.cgi?id=1349493
#wget http://pulp-read.dist.prod.ext.phx2.redhat.com/content/dist/rhel/server/7/7Server/x86_64/highavailability/os/Packages/pacemaker-1.1.13-10.el7_2.4.x86_64.rpm
#wget http://pulp-read.dist.prod.ext.phx2.redhat.com/content/dist/rhel/server/7/7Server/x86_64/highavailability/os/Packages/pacemaker-cli-1.1.13-10.el7_2.4.x86_64.rpm
#wget http://pulp-read.dist.prod.ext.phx2.redhat.com/content/dist/rhel/server/7/7Server/x86_64/highavailability/os/Packages/pacemaker-cluster-libs-1.1.13-10.el7_2.4.x86_64.rpm
#wget http://pulp-read.dist.prod.ext.phx2.redhat.com/content/dist/rhel/server/7/7Server/x86_64/highavailability/os/Packages/pacemaker-libs-1.1.13-10.el7_2.4.x86_64.rpm
#wget http://pulp-read.dist.prod.ext.phx2.redhat.com/content/dist/rhel/server/7/7Server/x86_64/highavailability/os/Packages/pacemaker-remote-1.1.13-10.el7_2.4.x86_64.rpm
#for i in $(nova list | grep overcloud  | awk '{ print $12; }' | cut -f2 -d=)
#do
# $SCP pacemaker-* $i:
# $SSH $i "sudo rpm -Uvh pacemaker*"
#done
