echo "###############################################"
echo "### Configuring repos #########################"
echo $(date)

set -eux

source environment

sudo yum update -y

if [ "$OPENSTACK_VERSION" == "mitaka" ]
 then
  git clone https://git.openstack.org/openstack-infra/tripleo-ci
  export STABLE_RELEASE="mitaka"
  sudo ./tripleo-ci/scripts/tripleo.sh --repo-setup
  sudo yum -y install yum-plugin-priorities python-tripleoclient
 else
  sudo yum localinstall -y http://rhos-release.virt.bos.redhat.com/repos/rhos-release/rhos-release-latest.noarch.rpm
  # To pick a specific release
  #rhos-release -p Y3.1 7-director -r 7.2
  #rhos-release -p Z4 7
  case $OPENSTACK_VERSION in
  "osp10") sudo rhos-release -p latest 10-director
           #sudo yum install -y python-tripleoclient
           # Workaround for bug https://bugzilla.redhat.com/show_bug.cgi?id=1382956
           #sudo yum -y localinstall http://buildlogs.centos.org/centos/7/cloud/x86_64/openstack-newton/python-tripleoclient-5.2.1-0.1.34590ccgit.el7.noarch.rpm
           sudo yum -y localinstall http://buildlogs.centos.org/centos/7/cloud/x86_64/openstack-newton/python-tripleoclient-5.3.0-1.el7.noarch.rpm
           # Workaround for bug https://bugs.launchpad.net/tripleo/+bug/1633611
           sudo yum -y localinstall http://buildlogs.centos.org/centos/7/cloud/x86_64/openstack-newton/puppet-tripleo-5.3.0-1.el7.noarch.rpm
           # Workaround for bug https://bugzilla.redhat.com/show_bug.cgi?id=1385470
           #sudo yum -y localinstall http://trunk.rdoproject.org/centos7-newton/current/openstack-tripleo-common-5.2.1-0.20161015221239.3163e51.el7.centos.noarch.rpm
           sudo yum -y localinstall https://trunk.rdoproject.org/centos7-newton/current/openstack-tripleo-common-5.3.1-0.20161019091424.eddce89.el7.centos.noarch.rpm
          ;;
  "osp9") sudo rhos-release -p latest 9-director
          sudo yum install -y python-tripleoclient
          ;;
  "osp8") sudo rhos-release -p latest 8-director
          sudo yum install -y python-tripleoclient
          ;;
  "osp7") sudo rhos-release -p latest 7-director
          sudo yum install -y python-rdomanager-oscplugin
          ;;
  esac
fi
