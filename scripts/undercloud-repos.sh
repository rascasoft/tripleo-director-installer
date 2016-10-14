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
           sudo yum localinstall http://buildlogs.centos.org/centos/7/cloud/x86_64/openstack-newton/python-tripleoclient-5.2.1-0.1.34590ccgit.el7.noarch.rpm
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
