#!/bin/bash

set -eux

source $1/environment &> /dev/null
WORKINGDIR=$(dirname $0)
: ${PROVISION_SCRIPT:=""}
: ${INTROSPECTION_PRE_SCRIPT:=""}
: ${INTROSPECTION_POST_SCRIPT:=""}
: ${SSL_ENABLE:=""}
: ${IPV6_ENABLE:=""}

if [ $? -eq 0 ]
 then
  export ENVIRONMENTDIR=$1
  if [ "$OPENSTACK_VERSION" != "osp8" -a "$OPENSTACK_VERSION" != "osp7" -a "$OPENSTACK_VERSION" != "osp9" -a "$OPENSTACK_VERSION" != "mitaka" ]
   then
    echo "OPENSTACK_VERSION must be 'osp7', 'osp8', 'osp9' or 'mitaka'."
    exit 1
  fi
 else
  echo "A file named 'environment' must exists under $1"
  exit 1
fi

cd $WORKINGDIR

# If provisioning is declared, then we provide the undercloud
if [ "x$PROVISION_SCRIPT" != "x" ]
 then
  echo "###############################################"
  echo "$(date) Provisioning $UNDERCLOUD (root)"
  $ENVIRONMENTDIR/$PROVISION_SCRIPT
fi

echo "###############################################"
echo "$(date) Uploading undercloud preparation scripts $UNDERCLOUD (root)"
$SCP -r scripts/undercloud-{preparation,repos-$OPENSTACK_VERSION}.sh root@$UNDERCLOUDIP:

echo "###############################################"
echo "$(date) Starting undercloud preparation in $UNDERCLOUD"
$SSH root@$UNDERCLOUDIP ./undercloud-preparation.sh $UNDERCLOUDIP

echo "###############################################"
echo "$(date) Uploading undercloud scripts $UNDERCLOUD (stack)"
$SCP -r tests scripts/undercloud-install.sh scripts/overcloud-{images,introspection,deploy,post}.sh scripts/{opensink,follow-events.py} $ENVIRONMENTDIR/{environment,undercloud.conf,instackenv.json,nic-configs} stack@$UNDERCLOUDIP:

echo "###############################################"
echo "$(date) Configuring undercloud repositories in $UNDERCLOUD"
$SSH stack@$UNDERCLOUDIP ./undercloud-repos.sh

# If IPV6 is enabled copy files
if [ "x$IPV6_ENABLE" != "x" ]
 then
  echo "###############################################"
  echo "$(date) Uploading IPV6 configuration $UNDERCLOUD (stack)"
  $SCP $ENVIRONMENTDIR/network-environment-v6.yaml stack@$UNDERCLOUDIP:
 else 
  echo "###############################################"
  echo "$(date) Uploading IPV4 configuration $UNDERCLOUD (stack)"
  $SCP $ENVIRONMENTDIR/network-environment.yaml stack@$UNDERCLOUDIP:
fi

# If SSL is enabled copy files
if [ "x$SSL_ENABLE" != "x" ]
 then
  echo "###############################################"
  echo "$(date) Uploading SSL configuration $UNDERCLOUD (stack)"
  $SCP scripts/undercloud-ssl.sh $ENVIRONMENTDIR/undercloud.pem stack@$UNDERCLOUDIP:
  $SSH stack@$UNDERCLOUDIP ./undercloud-ssl.sh
fi

echo "###############################################"
echo "$(date) Starting undercloud installation in $UNDERCLOUD (user stack)"
$SSH stack@$UNDERCLOUDIP ./undercloud-install.sh

echo "###############################################"
echo "$(date) Starting overcloud image generation (user stack)"
$SSH stack@$UNDERCLOUDIP ./overcloud-images.sh

# If introspectin pre script is declared, we execute it now
if [ "x$INTROSPECTION_PRE_SCRIPT" != "x" ]
 then
  echo "###############################################"
  echo "$(date) Executing $INTROSPECTION_PRE_SCRIPT (stack)"
  $SCP $ENVIRONMENTDIR/$INTROSPECTION_PRE_SCRIPT stack@$UNDERCLOUDIP:
  $SSH stack@$UNDERCLOUDIP ./$INTROSPECTION_PRE_SCRIPT
fi

echo "###############################################"
echo "$(date) Starting overcloud introspection (user stack)"
$SSH stack@$UNDERCLOUDIP ./overcloud-introspection.sh

# If introspectin post script is declared, we execute it now
if [ "x$INTROSPECTION_POST_SCRIPT" != "x" ]
 then
  echo "###############################################"
  echo "$(date) Executing $INTROSPECTION_POST_SCRIPT (stack)"
  $SCP $ENVIRONMENTDIR/$INTROSPECTION_POST_SCRIPT stack@$UNDERCLOUDIP:
  $SSH stack@$UNDERCLOUDIP ./$INTROSPECTION_POST_SCRIPT
fi

# If SSL is enabled copy files for the overcloud and perform configuration
if [ "x$SSL_ENABLE" != "x" ]
 then
  echo "###############################################"
  echo "$(date) Uploading SSL configuration $UNDERCLOUD (stack)"
  $SCP scripts/overcloud-ssl.sh $ENVIRONMENTDIR/{cloudname,enable-tls,inject-trust-anchor}.yaml $ENVIRONMENTDIR/overcloud-cacert.pem stack@$UNDERCLOUDIP:
  $SSH stack@$UNDERCLOUDIP ./overcloud-ssl.sh
fi

echo "###############################################"
echo "$(date) Starting overcloud deploy (user stack)"
$SSH stack@$UNDERCLOUDIP ./overcloud-deploy.sh

echo "###############################################"
echo "$(date) Starting overcloud post operations"
$SSH stack@$UNDERCLOUDIP ./overcloud-post.sh

echo "###############################################"
echo "$(date) Getting sosreports"
LOGDIR=$ENVIRONMENTDIR/TDi_$OPENSTACK_VERSION\_$(date +%s)
mkdir -p $LOGDIR
$SCP stack@$UNDERCLOUDIP:/tmp/sosreports/* $LOGDIR/
