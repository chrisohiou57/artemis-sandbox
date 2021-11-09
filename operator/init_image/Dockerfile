FROM quay.io/artemiscloud/activemq-artemis-broker-init:0.2.3
ADD artemis-prometheus-metrics-plugin-1.0.0.CR1-redhat-00018.jar /amq/artemis-prometheus-metrics-plugin.jar
ADD artemis-prometheus-metrics-plugin-servlet-1.0.0.CR1-redhat-00018.war /amq/metrics.war
ADD bootstrap.xml /amq/bootstrap.xml
ADD post-config.sh /amq/scripts/post-config.sh