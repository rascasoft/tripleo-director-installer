echo "###############################################"
echo "### Configuring repos #########################"
echo $(date)

yum install -y http://rhos-release.virt.bos.redhat.com/repos/rhos-release/rhos-release-latest.noarch.rpm
rhos-release 7-director
# To pick a specific release
#rhos-release -p Y3.1 7-director -r 7.2
#rhos-release -p Z4 7
yum install -y python-rdomanager-oscplugin
