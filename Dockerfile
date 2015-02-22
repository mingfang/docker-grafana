FROM ubuntu:14.04
 
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN locale-gen en_US en_US.UTF-8
ENV LANG en_US.UTF-8

#Runit
RUN apt-get install -y runit 
CMD export > /etc/envvars && /usr/sbin/runsvdir-start
RUN echo 'export > /etc/envvars' >> /root/.bashrc

#Utilities
RUN apt-get install -y vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common

#nginx
RUN echo 'deb http://nginx.org/packages/ubuntu/ precise nginx' > /etc/apt/sources.list.d/nginx.list && \
    wget http://nginx.org/keys/nginx_signing.key -O - | apt-key add - && \
    apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y nginx 

#grafana
RUN curl -L http://grafanarel.s3.amazonaws.com/grafana-1.9.1.tar.gz | tar xz
RUN mv grafana* grafana

#influxdb
RUN wget http://s3.amazonaws.com/influxdb/influxdb_latest_amd64.deb && \
    dpkg -i influxdb_latest_amd64.deb && \
    rm *.deb

#sysinfo
RUN wget https://github.com/novaquark/sysinfo_influxdb/releases/download/0.5.3/sysinfo_influxdb && \
    chmod +x sysinfo_influxdb

#Configuration

#nginx conf
RUN mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.saved
ADD nginx.conf /etc/nginx/conf.d/grafana.conf

#grafana conf
ADD config.js /grafana/config.js

#Add runit services
ADD sv /etc/service 

RUN runsv /etc/service/influxdb& \
    while ! nc -vz localhost 8086;do sleep 3; done && \
    curl -X POST 'http://localhost:8086/db?u=root&p=root' -d '{"name": "sysinfo"}' && \
    curl -X POST 'http://localhost:8086/db?u=root&p=root' -d '{"name": "grafana"}' && \
    sv stop influxdb