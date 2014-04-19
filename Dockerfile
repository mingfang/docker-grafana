FROM ubuntu
 
RUN apt-get update


#Runit
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y runit 
CMD /usr/sbin/runsvdir-start

#SSHD
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server &&	mkdir -p /var/run/sshd && \
    echo 'root:root' |chpasswd

#Utilities
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y vim less net-tools inetutils-ping curl git telnet nmap socat dnsutils netcat tree htop unzip sudo

#nginx
RUN echo 'deb http://nginx.org/packages/ubuntu/ precise nginx' > /etc/apt/sources.list.d/nginx.list && \
    wget http://nginx.org/keys/nginx_signing.key -O - | apt-key add - && \
    apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y nginx 

#grafana
RUN curl -L https://github.com/torkelo/grafana/archive/v1.5.3.tar.gz | tar xz

#influxdb
RUN wget http://s3.amazonaws.com/influxdb/influxdb_latest_amd64.deb && \
    dpkg -i influxdb_latest_amd64.deb && \
    rm *.deb

#sysinfo
RUN wget https://github.com/novaquark/sysinfo_influxdb/releases/download/0.2.0/sysinfo_influxdb && \
    chmod +x sysinfo_influxdb

#Configuration
ADD . /docker

#nginx conf
RUN rm /etc/nginx/conf.d/default.conf && ln -s /docker/nginx.conf /etc/nginx/conf.d/grafana.conf

#grafana conf
RUN ln -s /docker/config.js /grafana-1.5.3/src/config.js

#Runit Automatically setup all services in the sv directory
RUN for dir in /docker/sv/*; do echo $dir; chmod +x $dir/run $dir/log/run; ln -s $dir /etc/service/; done

RUN runsv /etc/service/influxdb& \
    while ! nc -vz localhost 8086;do sleep 1; done && \
    curl -X POST 'http://localhost:8086/db?u=root&p=root' -d '{"name": "sysinfo"}' && \
    sv stop influxdb

#hack to avoid influxdb crash
RUN rm -rf /opt/influxdb/shared/data/raft

ENV HOME /root
WORKDIR /root
EXPOSE 22
