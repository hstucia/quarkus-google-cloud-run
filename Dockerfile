# Step 1: build the native image
FROM oracle/graalvm-ce:19.2.1 as graalvm

# Install Graal Native Image plugin
RUN gu install --no-progress native-image

# Download and install Maven
ARG MAVEN_VERSION=3.6.3
ARG USER_HOME_DIR="/root"
ARG SHA=c35a1803a6e70a126e80b2b3ae33eed961f83ed74d18fcd16909b2d44d7dada3203f1ffe726c17ef8dcca2dcaa9fca676987befeadc9b9f759967a8cb77181c0
ARG BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries

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
FROM registry.fedoraproject.org/fedora-minimal
WORKDIR /svc/
COPY --from=graalvm /home/app/target/*-runner /svc/app
RUN chmod 775 /svc

USER 1000

EXPOSE 8080
ENTRYPOINT ["./app", "-Dquarkus.http.host=0.0.0.0"]
