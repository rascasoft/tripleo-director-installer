#!/bin/bash

set -eux

source environment

source stackrc 

case $OPENSTACK_VERSION in
"mitaka") IMAGE_URL="https://ci.centos.org/artifacts/rdo/images/mitaka/delorean/stable/"
          ;;
"osp10") IMAGE_URL="http://rhos-release.virt.bos.redhat.com/ci-images/rhos-10/current-passed-ci/"
        ;;
"osp9") IMAGE_URL="http://rhos-release.virt.bos.redhat.com/ci-images/rhos-9/current-passed-ci/"
        ;;
"osp8") IMAGE_URL="http://rhos-release.virt.bos.redhat.com/ci-images/rhos-8/current-passed-ci/"
        ;;
"osp7") IMAGE_URL="http://rhos-release.virt.bos.redhat.com/puddle-images/latest-7.0-images/"
        ;;
esac

echo "$(date) Retrieving images"
source stackrc
[ -d ~/images ] && rm -rf ~/images
mkdir ~/images
cd ~/images
lftp $IMAGE_URL << EOF
get overcloud-full.tar
get deploy-ramdisk-ironic.tar
get discovery-ramdisk.tar
get ironic-python-agent.tar
quit 0
EOF
for i in *.tar; do
tar xvfp $i
done

echo "$(date) Installing libguestfs-tools"
sudo yum -y install libguestfs-tools.noarch

echo "$(date) Restarting libvirtd"
sudo systemctl restart libvirtd

echo "$(date) Updating DNS and packages on overcloud image and changing root password"
case $OPENSTACK_VERSION in
"mitaka"|"osp8"|"osp9"|"osp10") virt-customize --verbose -a overcloud-full.qcow2 --root-password password:redhat
                                ;;
"osp7") export LIBGUESTFS_BACKEND=direct
        sudo -E bash -c "virt-customize --verbose -a overcloud-full.qcow2 --selinux-relabel --memsize 8192 --smp 4 --root-password password:redhat --run-command 'yum localinstall -y http://rhos-release.virt.bos.redhat.com/repos/rhos-release/rhos-release-latest.noarch.rpm http://rhos-release.virt.bos.redhat.com/repos/rhos-release/extras/7/wget-1.14-9.el7.x86_64.rpm http://rhos-release.virt.bos.redhat.com/repos/rhos-release/extras/7/yum-utils-1.1.31-29.el7.noarch.rpm' --run-command 'rhos-release -p latest 7' --run-command 'yum -y -v update > /tmp/yum-update.log 2>&1' --run-command 'rhos-release -x' --run-command 'yum remove -y rhos-release wget yum-utils'" || /bin/true
        ;;
esac

# To generate mitaka images:
#export NODE_DIST=centos7
#export USE_DELOREAN_TRUNK=1
#export DELOREAN_TRUNK_REPO="http://trunk.rdoproject.org/centos7/current-tripleo/"
#export DELOREAN_REPO_FILE="delorean.repo"
#openstack overcloud image build --all

# To generate 9 images:
#wget http://download.eng.bos.redhat.com/brewroot/packages/rhel-guest-image/7.2/20160302.0/images/rhel-guest-image-7.2-20160302.0.x86_64.qcow2
#export USE_DELOREAN_TRUNK=0
#export RHOS=1
#export DIB_LOCAL_IMAGE=rhel-guest-image-7.2-20160302.0.x86_64.qcow2
#export DIB_CLOUD_IMAGES="http://download.eng.bos.redhat.com/brewroot/packages/rhel-guest-image/7.2/20160302.0/images/"
#export DIB_YUM_REPO_CONF="/etc/yum.repos.d/rhos-release-9.repo  /etc/yum.repos.d/rhos-release-rhel-7.2.repo /etc/yum.repos.d/rhos-release-9-director.repo"
#export DIB_CLOUD_INIT_ETC_HOSTS=false
#openstack overcloud image build --all

# To generate 8 images:
#wget http://mrg-05.mpc.lab.eng.bos.redhat.com/images/rhel-guest-image-7.2-20151102.0.x86_64.qcow2
#export USE_DELOREAN_TRUNK=0
#export RHOS=1
#export DIB_LOCAL_IMAGE=rhel-guest-image-7.2-20151102.0.x86_64.qcow2
#export DIB_YUM_REPO_CONF="/etc/yum.repos.d/rhos-release-8.repo  /etc/yum.repos.d/rhos-release-rhel-7.2.repo /etc/yum.repos.d/rhos-release-8-director.repo"
#openstack overcloud image build --all
