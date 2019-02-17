#!/bin/bash
set -o pipefail
set -e

useradd -m -s /bin/bash alertmanager
mkdir /etc/alertmanager
mkdir /etc/alertmanager/template
mkdir -p /var/lib/alertmanager/data
touch /etc/alertmanager/alertmanager.yml
chown -R alertmanager:alertmanager /etc/alertmanager
chown -R alertmanager:alertmanager /var/lib/alertmanager

wget https://github.com/prometheus/alertmanager/releases/download/v0.16.1/alertmanager-0.16.1.linux-amd64.tar.gz
tar xvzf alertmanager-0.16.1.linux-amd64.tar.gz
cp alertmanager-0.16.1.linux-amd64/alertmanager /usr/local/bin/
cp alertmanager-0.16.1.linux-amd64/amtool /usr/local/bin/
chown alertmanager:alertmanager /usr/local/bin/alertmanager
chown alertmanager:alertmanager /usr/local/bin/amtool

cat >> /etc/alertmanager/alertmanager.yml <<EOF
---
# {{ ansible_managed }}
global:
  smtp_smarthost: localhost:25
  smtp_from: alertmanager@localhost
templates:
- "/etc/alertmanager/*.tmpl"
route:
  group_by:
  - alertname
  - cluster
  - service
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 3h
  receiver: slack
receivers:
- name: slack
  slack_configs:
  - api_url: SlackURL
    channel: "#prometheus"
    send_resolved: true
    username: prometheus
    pretext: "Some stuff"
    text: "Some text"
inhibit_rules:
- source_match:
    severity: critical
  target_match:
    severity: warning
  equal:
  - alertname
  - cluster
  - service
EOF

cat >> /etc/systemd/system/alertmanager.service <<EOF
[Unit]
Description=Prometheus Alertmanager Service
Wants=network-online.target
After=network.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/usr/local/bin/alertmanager \
    --config.file /etc/alertmanager/alertmanager.yml \
    --storage.path /var/lib/alertmanager/data
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable alertmanager
systemctl start alertmanager