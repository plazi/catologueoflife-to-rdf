FROM mcr.microsoft.com/devcontainers/base:jammy

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
RUN apt update
RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install default-jre wget git curl
RUN wget https://github.com/tarql/tarql/releases/download/v1.2/tarql-1.2.tar.gz
RUN cd /usr/local/lib/ && tar xzf /tarql-1.2.tar.gz && rm /tarql-1.2.tar.gz
RUN chmod a+x /usr/local/lib/tarql-1.2/bin/tarql
RUN ln -s /usr/local/lib/tarql-1.2/bin/tarql /usr/local/bin/