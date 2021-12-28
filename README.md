# Overview

[Apache ActiveMQ Artemis](https://activemq.apache.org/components/artemis/documentation/) is an open source project to build a multi-protocol, embeddable, very high performance, clustered, asynchronous messaging system. It is the next generation of [Apache ActiveMQ "Classic"](https://activemq.apache.org/components/classic/) and offers better support for scaling and managing your messaging platform in the cloud.

This project is an exploration of different strategies for deploying and maintaining Artemis broker deployments in Kubernetes (K8s). Many of the instructions and inspiration for the work come from [ArtemisCloud.io](https://artemiscloud.io/), which provides a collection of container images and an Operator that aid those who want to run Artemis in K8s.

ActiveMQ Artemis [is used](https://access.redhat.com/documentation/en-us/red_hat_amq/2020.q4/html/deploying_amq_broker_on_openshift/con_br-intro-to-broker-on-ocp-broker-ocp) by RedHat in their OpenShift Container Platform. So, you can find a lot of useful information about Artemis in their documentation. RedHat [recommends](https://access.redhat.com/documentation/en-us/red_hat_amq/2020.q4/html/deploying_amq_broker_on_openshift/assembly-br-planning-a-deployment_broker-ocp#con-br-comparison-of-deployment-methods_broker-ocp) using the [Operator](https://github.com/artemiscloud/activemq-artemis-operator/) deployment approach for their platform. This project demonstrates using the operator in your own K8s cluster as well as using custom broker and [init](https://artemiscloud.io/blog/initcontainer/) containers.

<!-- Artemis Metrics
http://techiekhannotes.blogspot.com/2018/12/artemis-monitoring-with-grafana.html
https://github.com/jbertram/artemis-prometheus-metrics-plugin
http://activemq.apache.org/components/artemis/documentation/latest/metrics.html
https://stackoverflow.com/questions/60881223/activemq-prometheus-metrics-like-enque-deque-count-for-monitoring

Artemis K8s
https://artemiscloud.io/blog/using_operator/
https://dzone.com/articles/customized-artemis-broker-configuration-with-init
https://github.com/artemiscloud/activemq-artemis-operator -->

## Install Artemis Operator
The ArtemisCloud Operator is a powerful tool that allows you to configure and manage ActiveMQ Artemis broker resources in a cloud environment. This documentation assumes you are deploying the operator and broker instances to the K8s namespace `message`. If you pick a different namespace change the commands below.

Make sure that you are running the commands in the appropriate directory. You will notice that you have to clone the operator repository. So, sometimes you will be running commands in that project and other times you are running commands within this project.

### Clone the operator project
```
git clone https://github.com/artemiscloud/activemq-artemis-operator.git
```

### Create K8s namespace
```
kubectl create namespace message
```

### Install operator service account and role
```
cd activemq-artemis-operator
kubectl create -f deploy/service_account.yaml -n message
kubectl create -f deploy/role.yaml -n message
kubectl create -f deploy/role_binding.yaml -n message
```

### Install the Custom Resource Definitions (CRDs)
```
kubectl create -f deploy/crds/broker_activemqartemis_crd.yaml -n message
kubectl create -f deploy/crds/broker_activemqartemisaddress_crd.yaml -n message
kubectl create -f deploy/crds/broker_activemqartemisscaledown_crd.yaml -n message
kubectl create -f deploy/crds/broker_activemqartemissecurity_crd.yaml -n message
```

### Install the Operator
```
kubectl create -f deploy/operator.yaml -n message
```

## Custom broker and init images
Switch to the operator project with our custom code
```
cd ../artemis-sandbox/operator
```

### Build container images
This project uses a custom Artemis broker image. It also uses an init image. In both cases, we are extending the [ArtemisCloud.io](https://artemiscloud.io/) base images. I'm obviously using my personal Docker Hub account. You will want to change it to whatever image repo you're using.

The custom broker image is being used to help with enabling the [Artemis Prometheus Metrics Plugin](https://github.com/jbertram/artemis-prometheus-metrics-plugin). The Dockerfile adds the metrics plugin WAR file to the <b>web</b> directory of the base image.

The custom init image also helps with enabling the metrics plugin. It copies the metrics plugin JAR file to the <b>lib</b> directory and applies a `bootstrap.xml` file that references the metrics plugin WAR file. The `bootstrap.xml` file is also configured to use the pod name (HOSTNAME environment variable) to appropriately map web requests to the pod in which the web apps are running in.

The init shell script also installs the kubectl tooling and adds annotations that informs Prometheus that metrics can be scraped from the pods <b>(see note below)</b>.

##### NOTE

I'm not sure why I need to do some of this. When I use enableMetricsPlugin in the CRD and a custom init image I am able to configure everything except the prometheus metrics WAR file. The init image lets us copy JARs to the lib directory, but doesn't seem to allow us to copy WAR files to the web directory. The idea for extending the base image came from [this GitHub issue](https://github.com/artemiscloud/activemq-artemis-operator/issues/62), which was still open when I was working on this.

Also, I'm not sure how to add the Prometheus pod annoations with the CRD. I ended up doing this with kubectl in the init image in my local for now. If I can't ultimately handle this with the CRD I will refactor this to use something like the [Kubernetes Python Client](https://github.com/kubernetes-client/python) which seems like a more appropriate way to do this.

#### Build and push broker image
```
docker build -t chriaass/activemq-artemis-broker-kubernetes ./broker_image
docker push chriaass/activemq-artemis-broker-kubernetes
```

#### Build and push the init image
```
docker build -t chriaass/artemis-basic-init ./init_image
docker push chriaass/artemis-basic-init
```

### Create Artemis Deployment
There is an example of deploying a single broker and a cluster of brokers in this project. To change the type of deployment just swap the deployment YAML file.

#### Create an Artemis deployment using the CRD
```
kubectl create -f artemis-basic-deploy.yaml -n message
```

Once you have a broker pod running you can get a shell connection to it and take a look at the config that was created by merging the init container config with the default config. The config will be in the <b>/amq/init/config/amq-broker/etc/</b> directory. If you change the `metadata.name` value in the YAML deployment file your pod name will be different.
```
kubectl exec --stdin --tty ex-aao-ss-0 -- /bin/bash
```

#### Test the deployment
Verify empty queue stats.
```
kubectl exec ex-aao-ss-0 -n message -- /bin/bash /home/jboss/amq-broker/bin/artemis queue stat --user admin --password password --url tcp://ex-aao-ss-0:61616 -n message
```

Add some messages, then verify queue stats again with command we just used above.
```
kubectl exec ex-aao-ss-0 -n message -- /bin/bash /home/jboss/amq-broker/bin/artemis producer --user admin --password password --url tcp://ex-aao-ss-0:61616 --destination myQueue0::myAddress0 --message-count 100
```

#### Delete Deployment
To delete the deployment run the command below with approparite YAML deployment file:
```
kubectl delete -f artemis-basic-deployment.yaml -n message
```

### Expose Hawtio Console
Create a K8s service to expose the admin console on one of the nodes in the cluster. This service is designed to expose the broker using the pod with index 0. The operator increments the index of the pods as brokers are added to the cluster. So, using the 0 index will work with a single broker or a cluster. If we spray traffic to all broker nodes we will get kicked out of the console as we bounce between pods and lose our session. I did test what happens if the 0 index pod goes down (I deleted it). The operator recreates the 0 index pod and you can login again once the pod is recreated.
```
kubectl apply -f artemis-console-service.yml -n message
```

Once you have created the service you can see what port the console is available on by running the command below:
```
kubectl get svc artemis-console-svc -n message
```

Say the command above returned `8161:30022/TCP` for the <b>PORT(S)</b> value. You would access the console at the URL below using the credentials in the broker YAML deployment file.

http://localhost:30022/console

<b>NOTE (TODO)</b>

Further investigation should be done to see how the <b>ex-aao-hdls-svc</b> service that is created by the operator can be reused for this. The operator is creating it as a ClusterIp. Not sure how to change it to a NodePort yet.

Might be able to get this working with all nodes using an Ingress. Couldn't get an Ingress working properly locally yet. Might also try configuring the service to use use SessionAffinity so we stick to the pod.

### Delete Operator Deployment
Execute the commands below within the <b>activemq-artemis-operator</b> directory that was created when you cloned the operator project.
```
kubectl create -f deploy/operator.yaml -n message
kubectl delete -f deploy/crds/broker_activemqartemis_crd.yaml -n message
kubectl delete -f deploy/crds/broker_activemqartemisaddress_crd.yaml -n message
kubectl delete -f deploy/crds/broker_activemqartemisscaledown_crd.yaml -n message
kubectl delete -f deploy/crds/broker_activemqartemissecurity_crd.yaml -n message
kubectl delete -f deploy/role_binding.yaml -n message
kubectl delete -f deploy/service_account.yaml -n message
kubectl delete -f deploy/role.yaml -n message
```

<!-- If you import the sample Prometheus dashboard in this project you should see the broker metrics -->
