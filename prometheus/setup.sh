#!/bin/bash
set -o pipefail
set -e

yum install wget firewalld -y
useradd -m -s /bin/bash prometheus

wget https://github.com/prometheus/prometheus/releases/download/v2.7.1/prometheus-2.7.1.linux-amd64.tar.gz
tar -xzvf prometheus-2.7.1.linux-amd64.tar.gz 
mv prometheus-2.7.1.linux-amd64/ /home/prometheus/prometheus/
chown -R prometheus:prometheus /home/prometheus/prometheus/

cat >> /etc/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus Server
Documentation=https://prometheus.io/docs/introduction/overview/
After=network-online.target

[Service]
User=prometheus
Restart=on-failure

#Change this line if you download the 
#Prometheus on different path user
ExecStart=/home/prometheus/prometheus/prometheus \
  --config.file=/home/prometheus/prometheus/prometheus.yml \
  --storage.tsdb.path=/home/prometheus/prometheus/data

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus

systemctl start firewalld
firewall-cmd --add-port=9090/tcp --add-port=9100/tcp --add-port=9093/tcp --permanent
firewall-cmd --reload