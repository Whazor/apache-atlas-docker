FROM maven:3.6.0-jdk-8-alpine AS stage-atlas

ENV	ATLAS_REPO      https://www-eu.apache.org/dist/atlas/1.1.0/apache-atlas-1.1.0-sources.tar.gz
ENV	MAVEN_OPTS	"-Xms2g -Xmx2g"

RUN apk add nodejs
RUN apk add npm
RUN curl ${ATLAS_REPO} -o apache-atlas-1.1.0-sources.tar.gz
RUN tar xzf apache-atlas-1.1.0-sources.tar.gz
WORKDIR /apache-atlas-sources-1.1.0
RUN mkdir -p /apache-atlas-sources-1.1.0/dashboardv2/target/node/
RUN cp /usr/bin/node /apache-atlas-sources-1.1.0/dashboardv2/target/node/node
RUN mvn clean -T 4 -DskipTests package -Pdist,embedded-hbase-solr
RUN mv distro/target/apache-atlas-*-bin.tar.gz /apache-atlas.tar.gz

FROM centos:7

COPY --from=stage-atlas /apache-atlas.tar.gz /apache-atlas.tar.gz

ADD resources/entrypoint.sh /entrypoint.sh

RUN yum update -y  \
	&& yum install java-1.8.0-openjdk java-1.8.0-openjdk-devel python net-tools -y \
	&& yum clean all 
RUN cd /opt \
	&& tar xzf /apache-atlas.tar.gz \
	&& rm -rf /apache-atlas.tar.gz

COPY model /tmp/model
COPY resources/atlas-setup.sh /tmp

ENTRYPOINT ["sh", "-c", "/entrypoint.sh"]

EXPOSE 21000 9027
