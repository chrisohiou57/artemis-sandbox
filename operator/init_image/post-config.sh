# echo "RHEL version is..."
# cat /etc/redhat-release
# echo "Updating yum"
# yum update

# echo "#####################################################"
# echo "##                NOTE: IMPORTANT!                 ##"
# echo "## Installing EPEL outside of subscription-manager ##"
# echo "## is not a recommended practice. This is just for ##"
# echo "## demo purposes.                                  ##"
# echo "#####################################################"

# echo "Installing Extra Packages for Enterprise Linux (EPEL)"
# yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y

# echo "Enabling the the optional, extras, and HA repositories"
# subscription-manager repos --enable "rhel--optional-rpms" --enable "rhel--extras-rpms" --enable "rhel-ha-for-rhel-*-server-rpms"

# echo "####################################################"
# echo "##              Installing xmlstartlet            ##"
# echo "####################################################"
# yum install xmlstarlet -y

echo "########## Custom Artemis Config Script ############"
echo "##                                                ##"
echo "##   Applying custom configuration to Artemis:    ##"
echo "##       Artemis Prometheus Metrics Plugin        ##"
echo "####################################################"

echo "Copying artemis-prometheus-metrics-plugin.jar to $CONFIG_INSTANCE_DIR/lib"
cp /amq/artemis-prometheus-metrics-plugin.jar $CONFIG_INSTANCE_DIR/lib

echo "Overwriting bootstrap.xml"
cp -f /amq/bootstrap.xml $CONFIG_INSTANCE_DIR/etc/bootstrap.xml

# echo "Navigating to $CONFIG_INSTANCE_DIR/etc"
# cd $CONFIG_INSTANCE_DIR/etc

# echo "Adding metrics app to bootstrap.xml"
# xmlstarlet edit --inplace -s /broker/web -t elem -n app -v "" -i /broker/web/app -t attr -n url -v metrics -i /broker/web/app -t attr -n war -v metrics.war bootstrap.xml

# xmlstarlet edit --inplace -s /broker/web -t elem -n AppTMP -v "" \
#     -i //AppTMP -t attr -n "url" -v "metrics" \
#     -i //AppTMP -t attr -n "war" -v "metrics.war" \
#     -r //AppTMP -v app \
#     bootstrap.xml

# echo "Modified bootstrap.xml:"
# cat bootstrap.xml