#!/bin/bash

set -eux

source stackrc

echo "$(date) Uploading images"
pushd ~/images
openstack overcloud image upload --image-path ~/images/
popd

echo "$(date) Updating neutron subnet with DNS"
netid=$(neutron subnet-list | grep -v "+" |grep -v cidr | awk '{print $2}')
neutron subnet-update $netid --dns-nameserver 10.16.36.29

echo "$(date) Verifying instackenv.json"
json_verify < instackenv.json

echo "$(date) Importing instackenv.json"
openstack baremetal import --json ~/instackenv.json

echo "$(date) Configuring boot for introspection"
openstack baremetal configure boot

echo "$(date) Introspectioning..."
openstack baremetal introspection bulk start 2>&1 | tee overcloud_introspection.log

echo "$(date) Creating flavor baremetal"
openstack flavor create --id auto --ram 4096 --disk 40 --vcpus 4 baremetal || true

echo "$(date) Updating capabilities of flavor baremetal"
openstack flavor set --property "cpu_arch"="x86_64" --property "capabilities:boot_option"="local" --property "capabilities:profile"="baremetal" baremetal

case $OPENSTACK_VERSION in
"osp10") ids="$(openstack baremetal node list --fields uuid driver | grep pxe_ipmi | awk '{ print $2 }')"
                  ;;
"osp7"|"osp8"|"osp9"|"mitaka") ids="$(ironic node-list --detail | grep pxe_ipmi | awk '{print $(NF-3)}')"
                      ;;
esac

for i in $ids; do
  ironic node-update $i add properties/capabilities='profile:baremetal,boot_option:local'
done
