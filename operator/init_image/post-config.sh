echo "########## Custom Artemis Config Script ############"
echo "##   Applying custom configuration to Artemis:    ##"
echo "##       Artemis Prometheus Metrics Plugin        ##"
echo "####################################################"

echo "Copying $HOSTNAME artemis-prometheus-metrics-plugin.jar to $CONFIG_INSTANCE_DIR/lib"
cp /amq/artemis-prometheus-metrics-plugin.jar $CONFIG_INSTANCE_DIR/lib

echo "Overwriting $HOSTNAME bootstrap.xml with file that has metrics app definition"
cp -f /amq/bootstrap.xml $CONFIG_INSTANCE_DIR/etc/bootstrap.xml

echo "Populating HOSTNAME:$HOSTNAME in bootstrap web binding address"
sed -i 's/${HOSTNAME}/'"$HOSTNAME"'/g' $CONFIG_INSTANCE_DIR/etc/bootstrap.xml

echo "Copying kube config to $HOSTNAME"
cp /amq/kube_config ~/.kube/config

echo "Adding yum repo for kubectl on $HOSTNAME and installing it"
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
yum install -y kubectl

echo "Found kube cluster info on $HOSTNAME: $(kubectl cluster-info)"
echo "Adding Prometheus metric scraping annotations to $HOSTNAME in verbose mode"
kubectl -v8 annotate po $HOSTNAME prometheus.io/scrape="true"
kubectl -v8 annotate po $HOSTNAME prometheus.io/port="8161"
kubectl -v8 annotate po $HOSTNAME prometheus.io/path="metrics"