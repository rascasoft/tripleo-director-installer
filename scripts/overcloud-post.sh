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

mkdir -p /tmp/sosreports
for i in $(nova list | grep overcloud  | awk '{ print $12; }' | cut -f2 -d=)
do
 $SSH $i "sudo sosreport --batch; sudo mv -v /var/tmp/sosre*xz /tmp; sudo chmod 644 /tmp/sosrep*xz"
 $SCP $i:/tmp/sosrep*xz /tmp/sosreports/
done

sudo sosreport --batch || true
sudo mv /var/tmp/sosre*xz /tmp/sosreports || true
sudo chmod 644 /tmp/sosreports/*
