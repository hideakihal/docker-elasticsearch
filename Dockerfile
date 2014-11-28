FROM ubuntu:12.04

MAINTAINER hideaki

# Ubuntu update 
ADD sources.list /etc/apt/sources.list
RUN apt-get -y update

# ssh install
RUN apt-get -y install openssh-server
RUN apt-get -y install python-setuptools
RUN apt-get clean 
RUN easy_install supervisor

RUN mkdir /var/run/sshd
RUN echo 'root:root' | chpasswd

# sshd config
ADD id_rsa.pub /root/id_rsa.pub
RUN mkdir /root/.ssh/
RUN mv /root/id_rsa.pub /root/.ssh/authorized_keys
RUN chmod 700 /root/.ssh
RUN chmod 600 /root/.ssh/authorized_keys
RUN sed -i -e '/^UsePAM\s\+yes/d' /etc/ssh/sshd_config

# supervisor config
RUN mkdir -p /var/log/supervisor
RUN mkdir -p /etc/supervisor/conf.d/ 
ADD supervisord.conf /etc/supervisord.conf

# Install Java
RUN apt-get install -y python-software-properties debconf-utils
RUN add-apt-repository ppa:webupd8team/java
RUN apt-get update
RUN echo "oracle-java7-installer shared/accepted-oracle-license-v1-1 boolean true" | debconf-set-selections
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get install -y oracle-java7-installer

# Install Elasticsearch
RUN apt-get install -y curl
RUN curl http://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add -
RUN echo "deb http://packages.elasticsearch.org/elasticsearch/1.2/debian stable main" >> /etc/apt/sources.list.d/elasticsearch.list
RUN apt-get update
RUN apt-get install -y elasticsearch
RUN /usr/share/elasticsearch/bin/plugin -install mobz/elasticsearch-head 
ADD elasticsearch.conf /etc/supervisor/conf.d/elasticsearch.conf

# Install Kibana
RUN apt-get install -y unzip
RUN wget http://download.elasticsearch.org/kibana/kibana/kibana-latest.zip
RUN unzip kibana-latest.zip
RUN mv kibana-latest /usr/local/kibana
ADD config.js /usr/local/kibana/config.js

# Install Nginx
RUN echo "deb http://nginx.org/packages/ubuntu/ precise nginx" >> /etc/apt/sources.list.d/nginx.list
RUN echo "deb-src http://nginx.org/packages/ubuntu/ precise nginx" >> /etc/apt/sources.list.d/nginx.list
RUN curl http://nginx.org/keys/nginx_signing.key | apt-key add -
RUN apt-get update
RUN apt-get install -y nginx
ADD nginx.conf /etc/supervisor/conf.d/nginx.conf 
ADD default.conf /etc/nginx/conf.d/default.conf

# Expose ports.
EXPOSE 22 80 9200 9300

# Define default command.
CMD ["supervisord", "-n"]
