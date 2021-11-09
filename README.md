Why I am leaning towards the Operator approach: https://access.redhat.com/documentation/en-us/red_hat_amq/2020.q4/html/deploying_amq_broker_on_openshift/assembly-br-planning-a-deployment_broker-ocp#con-br-comparison-of-deployment-methods_broker-ocp

Artemis Metrics
http://techiekhannotes.blogspot.com/2018/12/artemis-monitoring-with-grafana.html
https://github.com/jbertram/artemis-prometheus-metrics-plugin
http://activemq.apache.org/components/artemis/documentation/latest/metrics.html
https://stackoverflow.com/questions/60881223/activemq-prometheus-metrics-like-enque-deque-count-for-monitoring

Artemis K8s
https://artemiscloud.io/blog/using_operator/
https://dzone.com/articles/customized-artemis-broker-configuration-with-init
https://github.com/artemiscloud/activemq-artemis-operator


<!-------------------------------------------------------------->
<!----------------- INSTALL ARTEMIS COMPONENTS ----------------->
<!-------------------------------------------------------------->
<!-- Clone the operator repo -->
git clone https://github.com/artemiscloud/activemq-artemis-operator.git

<!-- Install the service account and role -->
cd activemq-artemis-operator
kubectl create -f deploy/service_account.yaml
kubectl create -f deploy/role.yaml
kubectl create -f deploy/role_binding.yaml

<!-- Install the CRDs -->
kubectl create -f deploy/crds/broker_activemqartemis_crd.yaml
kubectl create -f deploy/crds/broker_activemqartemisaddress_crd.yaml
kubectl create -f deploy/crds/broker_activemqartemisscaledown_crd.yaml
kubectl create -f deploy/crds/broker_activemqartemissecurity_crd.yaml

<!-- Install the Operator -->
kubectl create -f deploy/operator.yaml

<!-- Switch to the operator project with our custom code -->
cd ../artemis-sandbox/operator

<!--
Build and push the custom broker image

########
# NOTE #
########
I'm not sure why I need to do this. When I use enableMetricsPlugin in the CRD and a custom init image I am able to configure everything except the prometheus metrics WAR file. It is not present in the default broker image. The only way I could get it to work is by extending the image to include the WAR file. The init image doesn't seem to allow us to copy WAR files. Also, I'm not sure how to add the Prometheus pod annoations with the CRD.
-->
docker build -t chriaass/activemq-artemis-broker-kubernetes .\broker_image
docker push chriaass/activemq-artemis-broker-kubernetes

<!-- Build and push the init image -->
docker build -t chriaass/artemis-basic-init .\init_image
docker push chriaass/artemis-basic-init

<!--
Install/Delete basic Artemis broker (wait for Operator pod to be in Running status)
Using custom config: https://artemiscloud.io/blog/initcontainer/
-->
<!--
Get pod shell: kubectl exec --stdin --tty ex-aao-ss-0 -- /bin/bash
Config files: /amq/init/config/amq-broker/etc/

This was ran from the artemis 
-->
kubectl create -f artemis-basic-deployment.yaml
kubectl delete -f artemis-basic-deployment.yaml

<!-- Add annotations to tell Prometheus to scrape pod metrics -->
kubectl annotate po ex-aao-ss-0 prometheus.io/scrape="true"
kubectl annotate po ex-aao-ss-0 prometheus.io/port="8161"
kubectl annotate po ex-aao-ss-0 prometheus.io/path="metrics"

<!-- Verify empty queue stats -->
kubectl exec ex-aao-ss-0 -- /bin/bash /home/jboss/amq-broker/bin/artemis queue stat --user admin --password password --url tcp://ex-aao-ss-0:61616

<!-- Add some messages, then verify queue stats again with command above. -->
kubectl exec ex-aao-ss-0 -- /bin/bash /home/jboss/amq-broker/bin/artemis producer --user admin --password password --url tcp://ex-aao-ss-0:61616 --destination myQueue0::myAddress0 --message-count 100

<!-- If you import the sample Prometheus dashboard in this project you should see the broker metrics -->