FROM ubuntu:14.04
 
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN locale-gen en_US en_US.UTF-8
ENV LANG en_US.UTF-8
RUN echo "export PS1='\e[1;31m\]\u@\h:\w\\$\[\e[0m\] '" >> /root/.bashrc

#Runit
RUN apt-get install -y runit 
CMD export > /etc/envvars && /usr/sbin/runsvdir-start
RUN echo 'export > /etc/envvars' >> /root/.bashrc

#Utilities
RUN apt-get install -y vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common jq psmisc

RUN apt-get install -y libfontconfig

#Grafana
RUN wget -O - https://grafanarel.s3.amazonaws.com/builds/grafana-2.1.3.linux-x64.tar.gz | tar zx
RUN mv grafana* grafana

#Grafana Plugins
RUN git clone --depth 1 https://github.com/grafana/grafana-plugins.git

#Prometheus Plugin
RUN cp -r /grafana-plugins/datasources/prometheus /grafana/public/app/plugins/datasource/

#Add runit services
COPY sv /etc/service 
