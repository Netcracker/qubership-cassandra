FROM alpine:3.20.3

ARG version
ENV CASSANDRA_VERSION $version

ARG exp_version
ENV EXPORTER_VERSION $exp_version

COPY /deployments /deployments
COPY /version/ /version/
RUN cp -rf /version/${CASSANDRA_VERSION}/templates/* /deployments/charts/cassandra/templates/

RUN echo 'https://dl-cdn.alpinelinux.org/alpine/v3.20/main' > /etc/apk/repositories \
    && echo 'https://dl-cdn.alpinelinux.org/alpine/v3.20/community' >> /etc/apk/repositories \
    && apk add --no-cache wget net-tools jq openjdk11 openssh-server bash python3 py-pip rsync libarchive-tools grep openssl \
    # ping takes over 999 uid 
    && sed -i "s/999/99/" /etc/group 


ENV CASSANDRA_CONFIG_DIR /opt/cassandra/conf
ENV CASSANDRA_INIT_CONFIG_DIR /var/lib/cassandra/configuration
ENV CASSANDRA_DATA /var/lib/cassandra/data
ENV CASSANDRA_HOME /opt/cassandra

COPY pip.conf /etc/pip.conf
RUN pip3 install --break-system-packages cassandra-driver

RUN wget -qO- https://dlcdn.apache.org/cassandra/${CASSANDRA_VERSION}/apache-cassandra-${CASSANDRA_VERSION}-bin.tar.gz | tar xvfz - -C /tmp/ && mv /tmp/apache-cassandra-${CASSANDRA_VERSION} $CASSANDRA_HOME
ENV PATH $PATH:$CASSANDRA_HOME/bin:$CASSANDRA_HOME/tools/bin

RUN echo 'export PATH=$PATH:'"$CASSANDRA_HOME/bin:$CASSANDRA_HOME/tools/bin" > $CASSANDRA_HOME/.profile 
RUN cp $CASSANDRA_HOME/bin/cqlsh /usr/share/bin

RUN mkdir -p /usr/share/java/

RUN wget -O /usr/share/java/sjk-plus-0.17.jar https://repo1.maven.org/maven2/org/gridkit/jvmtool/sjk-plus/0.17/sjk-plus-0.17.jar
RUN wget -O /usr/share/java/cassandra-exporter-agent.jar https://github.com/instaclustr/cassandra-exporter/releases/download/${EXPORTER_VERSION}


RUN rm -f $CASSANDRA_CONFIG_DIR/cassandra-topology.properties

RUN cp /files/sshd_config /var/lib/cassandra/custom_ssh/
RUN cp /files/run.sh /

RUN mkdir -p /var/lib/cassandra \
        && mkdir -p /var/lib/cassandra/custom_ssh \
        && chmod -R 777 /var/lib/cassandra \
        && chmod -R 777 /var/lib/cassandra \
        && chmod -R 777 $CASSANDRA_CONFIG_DIR \
        && chmod -R 777 $CASSANDRA_HOME \
        && chmod 777 /etc/passwd \
        && chmod -R 777 /var/lib/cassandra/custom_ssh

VOLUME /var/lib/cassandra

EXPOSE 7000 7001 7199 9042 9160 2222 8778

RUN chmod +x /run.sh
