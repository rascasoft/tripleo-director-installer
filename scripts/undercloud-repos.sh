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
  "osp9") sudo rhos-release -P 9-director
          sudo yum install -y python-tripleoclient
          ;;
  "osp8") sudo rhos-release -P 8-director
          sudo yum install -y python-tripleoclient
          ;;
  "osp7") sudo rhos-release -P 7-director
          sudo yum install -y python-rdomanager-oscplugin
          ;;
  esac
fi
