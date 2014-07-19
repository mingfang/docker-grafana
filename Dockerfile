FROM ubuntu:14.04
 
RUN apt-get update

#Runit
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y runit 
CMD /usr/sbin/runsvdir-start

#SSHD
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server &&	mkdir -p /var/run/sshd && \
    echo 'root:root' |chpasswd
RUN sed -i "s/session.*required.*pam_loginuid.so/#session    required     pam_loginuid.so/" /etc/pam.d/sshd
RUN sed -i "s/PermitRootLogin without-password/#PermitRootLogin without-password/" /etc/ssh/sshd_config

#Utilities
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y vim less net-tools inetutils-ping curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common

#nginx
RUN echo 'deb http://nginx.org/packages/ubuntu/ precise nginx' > /etc/apt/sources.list.d/nginx.list && \
    wget http://nginx.org/keys/nginx_signing.key -O - | apt-key add - && \
    apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y nginx 

#grafana
RUN curl -L http://grafanarel.s3.amazonaws.com/grafana-1.6.1.tar.gz | tar xz
RUN mv grafana* grafana

#influxdb
RUN wget http://s3.amazonaws.com/influxdb/influxdb_latest_amd64.deb && \
    dpkg -i influxdb_latest_amd64.deb && \
    rm *.deb

#sysinfo
RUN wget https://github.com/novaquark/sysinfo_influxdb/releases/download/0.2.0/sysinfo_influxdb && \
    chmod +x sysinfo_influxdb

#Configuration

#nginx conf
RUN mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.saved
ADD nginx.conf /etc/nginx/conf.d/grafana.conf

#grafana conf
ADD config.js /grafana/src/config.js

#Add runit services
ADD sv /etc/service 

RUN runsv /etc/service/influxdb& \
    while ! nc -vz localhost 8086;do sleep 1; done && \
    curl -X POST 'http://localhost:8086/db?u=root&p=root' -d '{"name": "sysinfo"}' && \
    sv stop influxdb

#hack to avoid influxdb crash
RUN rm -rf /opt/influxdb/shared/data/raft
