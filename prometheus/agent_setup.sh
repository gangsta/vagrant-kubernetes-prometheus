#!/bin/bash

useradd -m -s /bin/bash prometheus


wget https://github.com/prometheus/node_exporter/releases/download/v0.17.0/node_exporter-0.17.0.linux-amd64.tar.gz
tar -xzvf node_exporter-0.17.0.linux-amd64.tar.gz
mv node_exporter-0.17.0.linux-amd64 /home/prometheus/node_exporter
chown -R prometheus:prometheus /home/prometheus/node_exporter

cat >> /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
ExecStart=/home/prometheus/node_exporter/node_exporter

[Install]
WantedBy=default.target
EOF

systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter