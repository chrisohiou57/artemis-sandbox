FROM quay.io/artemiscloud/activemq-artemis-broker-kubernetes:latest
ADD --chown=jboss:root https://maven.repository.redhat.com/ga/org/apache/activemq/artemis-prometheus-metrics-plugin-servlet/1.0.0.CR1-redhat-00018/artemis-prometheus-metrics-plugin-servlet-1.0.0.CR1-redhat-00018.war /opt/amq/web/metrics.war
USER 185
CMD [ "/opt/amq/bin/launch.sh", "start" ]