# Step 1: build the native image
FROM oracle/graalvm-ce:20.1.0-java11 as graalvm

# Install Graal Native Image plugin
RUN gu install --no-progress native-image

# Download and install Maven
ARG MAVEN_VERSION=3.6.3
ARG USER_HOME_DIR="/root"
ARG SHA=C35A1803A6E70A126E80B2B3AE33EED961F83ED74D18FCD16909B2D44D7DADA3203F1FFE726C17EF8DCCA2DCAA9FCA676987BEFEADC9B9F759967A8CB77181C0
ARG BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries

RUN echo "get maven from ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz"
RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha512sum -c - \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven
ENV GRAALVM_HOME $JAVA_HOME
ENV MAVEN_OPTS "-Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn"

COPY . /home/app
WORKDIR /home/app

RUN $MAVEN_HOME/bin/mvn -B -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn package -Pnative

# Step 2: build the running container
FROM registry.access.redhat.com/ubi8/ubi-minimal
WORKDIR /svc/
COPY --from=graalvm /home/app/target/*-runner /svc/app
RUN chmod 775 /svc

USER 1000

EXPOSE 8080
ENTRYPOINT ["./app", "-Dquarkus.http.host=0.0.0.0"]
