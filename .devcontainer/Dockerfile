FROM mcr.microsoft.com/devcontainers/base:jammy
ENV JAVA_HOME=/opt/java/openjdk
COPY --from=eclipse-temurin:21 $JAVA_HOME $JAVA_HOME
ENV PATH="${JAVA_HOME}/bin:${PATH}"

ARG JENA_VERSION=5.4.0

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
RUN apt update
RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install wget git curl
RUN wget https://github.com/tarql/tarql/releases/download/v1.2/tarql-1.2.tar.gz
RUN cd /usr/local/lib/ && tar xzf /tarql-1.2.tar.gz && rm /tarql-1.2.tar.gz
RUN chmod a+x /usr/local/lib/tarql-1.2/bin/tarql
RUN ln -s /usr/local/lib/tarql-1.2/bin/tarql /usr/local/bin/
# Pick the matching Jena/TDB2 version

# Install wget (for download) and unpack Jena into /opt/jena
RUN apt-get update && \
    apt-get install -y --no-install-recommends wget ca-certificates && \
    wget -qO /tmp/jena.tar.gz \
      https://dlcdn.apache.org/jena/binaries/apache-jena-${JENA_VERSION}.tar.gz && \
    mkdir -p /opt/jena && \
    tar xzf /tmp/jena.tar.gz -C /opt/jena --strip-components=1 && \
    rm /tmp/jena.tar.gz && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Expose Jena’s bin directory on the PATH so you can call tdb2.tdbloader, tdb2.tdbquery, arq, etc.
ENV PATH="/opt/jena/bin:${PATH}"