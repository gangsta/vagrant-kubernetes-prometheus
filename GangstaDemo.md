# Vagrant-Kubernetes-Demo

## Overview

* TBD

## Setup

### Usage

To get started, perform a git clone on. Make sure you have [Vagrant installed](https://docs.vagrantup.com/v2/installation/), and also [VirtualBox](https://www.virtualbox.org/).

```
# Download kubernetes-server-linux-amd64.tar.gz and kubernetes-server-linux-amd64.tar.gz in to Github directory
# link to download https://kubernetes.io/docs/setup/release/
vagrant up --provider virtualbox
```

Once vagrant is done provisioning the VMs run `vagrant status` to confirm all instances are running:

### Kubernetes Deployments,Service,Delete.
You can run the kubernetes deployment and  service on your cluster by issuing:

```
  vagrant ssh kube-master
  kubectl run hello-world --replicas=5 --labels="run=load-balancer-example" --image=docker.io/redis:latest
  kubectl get deployments hello-world
  kubectl describe deployments hello-world
  kubectl expose deployment hello-world --type=LoadBalancer --name=my-service
  kubectl get services my-service
  kubectl describe services my-service

  for pros
  kubectl get pods --output=wide

  Clean Up
  kubectl delete services my-service
  kubectl delete deployment hello-world
```

### Kubernetes RollingUpdat,RollingRollback

```
kubectl rollout status deployment/$DEPLOYMENT

Read the deployment history

kubectl rollout history deployment/$DEPLOYMENT
kubectl rollout history deployment/$DEPLOYMENT --revision 42

Rollback to the previous deployed version

kubectl rollout undo deployment/$DEPLOYMENT

Rollback to a specific previously deployed version

kubectl rollout undo deployment/$DEPLOYMENT --to-revision 21
```

### Kubernetes Secrets

```
kubectl create secret docker-registry dockerhub --docker-server=<your-registry-server> --docker-username=<your-name> --docker-password=<your-pword> --docker-email=<your-email>

!Note: use --docker-server=https://index.docker.io/v1/ for Hub.Docker.com

kubectl get secret dockerhub --output=yaml

in K8S config

apiVersion: v1
kind: Pod
metadata:
  name: foo
spec:
  containers:
    - name: whatever
      image: index.docker.io/DOCKER_USER/PRIVATE_REPO_NAME:latest
      imagePullPolicy: Always
      command: [ "echo", "SUCCESS" ]
  imagePullSecrets:
    - name: docker-registry

```

When you're done, you can shut down the cluster using
```
vagrant destroy -f
```

### If you want to change any of the configuration/scripts run

```
vagrant provision
```

### Docker Build

```
docker build -t dockerip:latest .
docker login --username=gangsta
docker tag dockerip:latest gangsta/dockerip:latest
docker push gangsta/dockerip:latest
```

### Docker Cleanup

```
docker rmi -f  $(docker images -a -q)
docker rm $(docker ps -a -q)
```

### Install Prometheus

* Prometheus Server

  `For this example we will take prometheus vagrant machine` To Use it do `vagrant ssh prometheus`

```bash
"As ROOT User"

useradd -m -s /bin/bash prometheus
su - prometheus

"As Prometheus User"

wget https://github.com/prometheus/prometheus/releases/download/v2.4.3/prometheus-2.4.3.linux-amd64.tar.gz
tar -xzvf prometheus-2.4.3.linux-amd64.tar.gz 
mv prometheus-2.4.3.linux-amd64/ prometheus/

"As ROOT User"

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
systemctl status prometheus -l

ss -putan | grep 9090
'Should be output'
"tcp    LISTEN     0      128      :::9090                 :::*                   users:(("prometheus",pid=7207,fd=6))"

firewall-cmd --add-port=9090/tcp --permanent
firewall-cmd --reload


```

* Install Node Exporter 

  `For this example we will take kube-node1 vagrant machine` To Use it do `vagrant ssh kube-node1`


```bash
"As ROOT User"

useradd -m -s /bin/bash prometheus  #feel free to change name
su - prometheus

"As Prometheus User"

wget https://github.com/prometheus/node_exporter/releases/download/v0.16.0/node_exporter-0.16.0.linux-amd64.tar.gz
tar -xzvf node_exporter-0.16.0.linux-amd64.tar.gz 
mv node_exporter-0.16.0.linux-amd64 node_exporter

"As ROOT User"

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
systemctl status node_exporter -l

ss -putan | grep 9100
"tcp    LISTEN     0      128      :::9100                 :::*                   users:(("node_exporter",pid=30041,fd=3))"

firewall-cmd --add-port=9100/tcp --permanent
firewall-cmd --reload

```

* Add node to Prometheus

   `Go back to Prometheus Server` If you follow Readme example do `vagrant ssh prometheus`

```bash
su - prometheus
vi prometheus/prometheus.yml

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['172.17.8.101:9100']

# 172.17.8.101:9100 Ip comes from node kube-node1 , in your case can be other

systemctl restart prometheus
```

### Install Alertmanager

   `Go back to Prometheus Server` If you follow Readme example do `vagrant ssh prometheus`

```bash
"Adding Alertmanager to Prometheus"

su - prometheus
vi prometheus/prometheus.yml
alerting:
  alert_relabel_configs: []
  alertmanagers:
  - static_configs:
    - targets:
      - localhost:9093

systemctl restart prometheus


useradd -m -s /bin/bash alertmanager
mkdir /etc/alertmanager
mkdir /etc/alertmanager/template
mkdir -p /var/lib/alertmanager/data
touch /etc/alertmanager/alertmanager.yml
chown -R alertmanager:alertmanager /etc/alertmanager
chown -R alertmanager:alertmanager /var/lib/alertmanager

wget https://github.com/prometheus/alertmanager/releases/download/v0.15.2/alertmanager-0.15.2.linux-amd64.tar.gz
tar xvzf alertmanager-0.15.2.linux-amd64.tar.gz
cp alertmanager-0.15.2.linux-amd64/alertmanager /usr/local/bin/
cp alertmanager-0.15.2.linux-amd64/amtool /usr/local/bin/
chown alertmanager:alertmanager /usr/local/bin/alertmanager
chown alertmanager:alertmanager /usr/local/bin/amtool

vi /etc/alertmanager/alertmanager.yml

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

```

### Adding Alerts

```bash
su - prometheus
vi prometheus/prometheus.yml

rule_files:                    
- "/home/prometheus/prometheus/alert.rules"

cat >> /home/prometheus/prometheus/alert.rules <<EOF
---
# Ansible managed
groups:
- name: alert.rules
  rules:
  - alert: Instance Down
    expr: up == 0
    for: 15s
    labels:
      severity: page
    annotations:
      summary: Instance {{ $labels.instance }} down
      description: Instance {{ $labels.instance }} of job {{ $labels.job }} has been down for more than 15 seconds.
  - alert: Kube Metrics Container Down
    expr: kube_pod_container_status_running{job='KubeStateMetrics'} == 0
    for: 15s
    labels:
      severity: page
    annotations:
      summary: Container{{ $labels.instance }} down
      description: Container {{ $labels.instance }} of job {{ $labels.job }} has been down for more than 15 seconds.
  - alert: Container Down
    expr: kube_pod_container_status_running{job!='KubeStateMetrics'} == 0
    for: 15s
    labels:
      severity: page
    annotations:
      summary: Container{{ $labels.instance }} down
      description: Container {{ $labels.instance }} of job {{ $labels.job }} has been down for more than 15 seconds.
EOF


systemctl restart prometheus
```

### Add Kube-State-Metrics to Prometheus

```bash
su - prometheus
vi prometheus/prometheus.yml

  - job_name: KubeStateMetrics
    scrape_interval: 5s
    scrape_timeout:  5s
    static_configs:
    - targets: ['172.17.8.101:30036']


# 32061 port expo

systemctl restart prometheus
```

### Deploy Kube State Metrics to Kubernetes

```bash

"Expose"

git clone https://github.com/kubernetes/kube-state-metrics.git

kubectl apply -f kube-state-metrics/kubernetes/
# kubectl expose deployment kube-state-metrics  --type=LoadBalancer --name=my-service -n kube-system

cat >> my-service.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: my-service
  namespace: kube-system
  labels: 
    k8s-app: kube-state-metrics
spec:
  selector:
    k8s-app: kube-state-metrics
  type: LoadBalancer
  ports:
  - name: http
    port: 8080
    targetPort: 8080
    nodePort: 30036
    protocol: TCP
  - name: http
    port: 8081
    targetPort: 8081
    nodePort: 30037
    protocol: TCP
EOF

kubectl apply -f my-service.yaml
```

### Deploy some Container

```Bash
cat >> gangsta.sh <<EOF
#!/bin/bash

GEN=$(openssl rand -hex 7)

kubectl get deployments | grep gangsta
if [ "$?" = "0" ]; then
        echo "apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: gangsta
spec:
  replicas: 5
  template:
    metadata:
      labels:
        app: gangsta
    spec:
      containers:
      - name: gangsta
        imagePullPolicy: Always
        image: gangsta/dockerip:latest
        ports:
        - containerPort: 80
        env:
        - name: Changing_Hash_for_Kubernetes_Deployment
          value: ${GEN}" > gangsta.yaml
        kubectl apply -f gangsta.yaml
else
        echo "apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: gangsta
spec:
  replicas: 5
  template:
    metadata:
      labels:
        app: gangsta
    spec:
      containers:
      - name: gangsta
        imagePullPolicy: Always
        image: gangsta/dockerip:latest
        ports:
        - containerPort: 80" > gangsta.yaml
        kubectl create -f gangsta.yaml
fi
EOF

kubectl delete pod $(kubectl get pods -o wide --all-namespaces | grep gangsta | awk '{print $2}')

```

### Install Kubernetes

```bash
"MASTER"

setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo


yum install kubelet kubeadm kubectl docker-ce -y


sed -i 's/cgroup-driver=systemd/cgroup-driver=cgroupfs/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

systemctl daemon-reload
systemctl restart kubelet
systemctl start docker
systemctl stop firewalld
systemctl enable docker
systemctl enable kubelet
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
swapoff -a
# get images before kubeadm init kubeadm config images pull
kubeadm init --apiserver-advertise-address=192.168.10.60 --pod-network-cidr=10.254.0.0/16

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

"NODE"
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo


yum install kubeadm docker-ce -y


sed -i 's/cgroup-driver=systemd/cgroup-driver=cgroupfs/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

systemctl daemon-reload
systemctl restart kubelet
systemctl start docker
systemctl stop firewalld
systemctl enable docker
systemctl enable kubelet
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
swapoff -a

kubeadm join 192.168.10.60:6443 --token cgecmm.clg29hllp7ji12pd --discovery-token-ca-cert-hash sha256:d73aedc93dd7cb383d484abefd9b959eebbb95c736118996c59aec8d9739dd0b

# wait 1 Minute
```
