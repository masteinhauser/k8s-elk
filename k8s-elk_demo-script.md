# Setup demo pre-reqs

```
# install [direnv](http://direnv.net/)
# install [gcloud](https://cloud.google.com/sdk/#Quick_Start)
brew cask install google-cloud-sdk
# setup bashrc with includes (.envrc using direnv)
gcloud auth login
```

# Setup local demo project repo

```
# clone k8s-elk
# cd into k8s-elk
direnv allow
```

# Setup gcloud

```
# [Following Guide](https://cloud.google.com/container-engine/docs/before-you-begin)
# [enable GKE](https://console.developers.google.com/project/_/kubernetes/list)
# **Create new project k8s-elk**
# enable beta features in gcloud client tool
gcloud components update beta
gcloud components update kubectl
gcloud config set project k8s-elk
gcloud config set compute/zone us-central1-f
# review cloud config
gcloud config list
```

# Setup GKE cluster

```
gcloud compute machine-types list --zones us-central1-f
gcloud beta container clusters create k8s-elk \
    --num-nodes 1 \
    --machine-type n1-standard-1

CLUSTER_INFO=$(gcloud beta container clusters describe k8s-elk | grep -E 'endpoint|password|admin')
echo "$CLUSTER_INFO"

ENDPOINT=$(echo "$CLUSTER_INFO" | grep endpoint | sed -e 's/endpoint://' -e 's/[ \t]*//')
PASSWORD=$(echo "$CLUSTER_INFO" | grep password | sed -e 's/password://' -e 's/[ \t]*//')
open "https://admin:$PASSWORD@$ENDPOINT/ui/"

# what instances do we now have?
gcloud compute instances list
gcloud beta container clusters list

### NOTE: GKE runs the master for us! We only need to specify adding/removing minion nodes!
```

# Setup Elasticsearch pod

Docker Images:
- [Elasticsearch](https://registry.hub.docker.com/_/elasticsearch/)
- [Logstash](https://registry.hub.docker.com/_/logstash/)
- [Kibana](https://registry.hub.docker.com/_/kibana/)



```
# Download and start the Elasticsearch docker image
kubectl run elasticsearch --image=elasticsearch --port=9200
# Expose the running container to the world
# TODO: Talk about services and the distributed load-balancer arch
kubectl expose rc elasticsearch --create-external-load-balancer=true

kubectl get services elasticsearch
curl http://${IP}:9200

kubectl get services elasticsearch
# NOTE: Note there are 2 IP(s) listed, both serving port 80. One is the internal IP that other pods in the cluster can use to talk to your service; the other is the external load-balanced IP.
```

# Cleanup Elasticsearch Pod
```
kubectl delete services elasticsearch
kubectl stop rc elasticsearch
```

# Deploy Elasticsearch cluster
```
cd kubernetes-elasticsearch-cluster

# set up the Kubernetes shared service account
kubectl create -f service-account.yaml

# set up the Kubernetes services for dynamic lookups
kubectl create -f elasticsearch-discovery-service.yaml
kubectl create -f elasticsearch-service.yaml

# launch the elasticsearch master
kubectl create -f elasticsearch-master-controller.yaml

# wait until the master is launched
kubectl get pods

# launch the elasticsearch data aggregator
kubectl create -f elasticsearch-lb-controller.yaml

# launch the elasticsearch data server
kubectl create -f elasticsearch-data-controller.yaml

# check everything launched
kubectl get pods

# are we sure?
es_master=$(kubectl get pods | grep master | awk '{print $1}')
kubectl logs $es_master

# okay, let's expose this to the outside world
kubectl expose rc elasticsearch-lb --create-external-load-balancer=true
--port=9200 --name=elasticsearch --protocol=TCP \
       && watch -g -n 1 'gcloud compute forwarding-rules list'

LB_IP=$(gcloud compute forwarding-rules list | grep -v NAME | awk '{ print $3 }')

# check to see everything is working
curl http://$LB_IP:9200/_cluster/health?pretty

# check the k8s cluster health again
open "https://admin:$PASSWORD@$ENDPOINT/ui/"

# Looks like we need more hosts! Let's add some more.
INSTANCE_GROUP=$(gcloud compute instance-groups list | grep -v NAME | awk '{ print $1 }')
gcloud compute instance-groups managed resize $INSTANCE_GROUP --size 3

# scale up the data hosts
kubectl scale --replicas=3 rc elasticsearch-data

# wait for it...
kubectl get pods

# check to see new elasticsearch nodes were added 
curl http://$LB_IP:9200/_cluster/health?pretty
```

# Deploy Kibana
```
cd kubernetes-elk-cluster/

### !!! update kibana-controller.yml with service IP for elasticsearch !!!

kubectl create -f kibana-controller.yaml

# kubectl create -f kibana-service.yaml
kubectl expose rc kibana --create-external-load-balancer=true
--port=80 --target-port=5601 --name=kibana --protocol=TCP \
       && watch -g -n 1 'gcloud compute forwarding-rules list'

KIBANA_IP=$(kubectl get services kibana -o yaml | grep ip: | sed -e 's/- ip://' -e 's/[ \t]*//' )
open http://${KIBANA_IP}
open "http://${KIBANA_IP}/#/discover?_g=(refreshInterval:(display:'5%20seconds',section:1,value:5000),time:(from:now-15m,mode:quick,to:now))&_a=(columns:!(message),index:'logstash-*',interval:auto,query:(query_string:(analyze_wildcard:!t,query:'*')),sort:!('@timestamp',desc))"

```

# Deploy Logstash
```
# kubectl create -f logstash-service.yaml
kubectl create -f logstash-controller.yaml

# scale down logstash, but leave available
kubectl scale --replicas=0 rc logstash
```

# Cleanup Resources
```
kubectl delete service kibana
kubectl delete service elasticsearch
kubectl delete service elasticsearch-discovery

kubectl delete rc logstash
kubectl delete rc kibana
kubectl delete rc elasticsearch-data
kubectl delete rc elasticsearch-lb
kubectl delete rc elasticsearch-master

gcloud beta container clusters delete k8s-elk
```

