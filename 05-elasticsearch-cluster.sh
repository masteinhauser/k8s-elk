#!/bin/bash
source inc-funcs.sh

pmt="Set up the Kubernetes shared service account"
cmd="kubectl create -f kubernetes-elasticsearch-cluster/service-account.yaml"
pmt_cmd "$pmt" "$cmd"


pmt="Set up the Kubernetes services for dynamic lookups"
cmd="kubectl create -f kubernetes-elasticsearch-cluster/elasticsearch-discovery-service.yaml"
pmt_cmd "$pmt" "$cmd"


pmt="Launch the elasticsearch master controller and pod"
cmd="kubectl create -f kubernetes-elasticsearch-cluster/elasticsearch-master-controller.yaml"
pmt_cmd "$pmt" "$cmd"


pmt="Wait for ES Master to start"
cmd="watch -g -n 1 'kubectl get pods | grep master | grep -i running'"
pmt_cmd "$pmt" "$cmd"


pmt="Launch the ES LB controller and pod"
cmd="kubectl create -f kubernetes-elasticsearch-cluster/elasticsearch-lb-controller.yaml"
pmt_cmd "$pmt" "$cmd"


pmt="Wait for ES LB to start"
cmd="watch -g -n 1 'kubectl get pods | grep elasticsearch-lb | grep -i running'"
pmt_cmd "$pmt" "$cmd"


pmt="Launch the ES data controller and pods"
cmd="kubectl create -f kubernetes-elasticsearch-cluster/elasticsearch-data-controller.yaml"
pmt_cmd "$pmt" "$cmd"


pmt="Wait for ES data pod to start"
cmd="watch -g -n 1 'kubectl get pods | grep elasticsearch-data | grep -i running'"
pmt_cmd "$pmt" "$cmd"


pmt="What pods are now running?"
cmd="kubectl get pods"
pmt_cmd "$pmt" "$cmd"


es_master=$(kubectl get pods | grep master | awk '{print $1}')
pmt="Are we sure ES is green and happy?"
cmd="kubectl logs $es_master"
pmt_cmd "$pmt" "$cmd"


pmt="Sweet! Let's expose this to the world"
cmd="kubectl expose rc elasticsearch-lb --create-external-load-balancer=true --port=9200 --name=elasticsearch --protocol=TCP && watch -g -n 1 'gcloud compute forwarding-rules list'"
pmt_cmd "$pmt" "$cmd"


LB_IP=$(gcloud compute forwarding-rules list | grep -v NAME | awk '{ print $3 }')
pmt="Check ES still thinks it is happy"
cmd="curl --retry 10 http://$LB_IP:9200/_cluster/health?pretty"
pmt_cmd "$pmt" "$cmd"


CLUSTER_INFO=$(gcloud beta container clusters describe k8s-elk | grep -E 'endpoint|password|admin')
ENDPOINT=$(echo "$CLUSTER_INFO" | grep endpoint | sed -e 's/endpoint://' -e 's/[ \t]*//')
PASSWORD=$(echo "$CLUSTER_INFO" | grep password | sed -e 's/password://' -e 's/[ \t]*//')

pmt="Check the k8s cluster health again"
cmd="open "https://admin:$PASSWORD@$ENDPOINT/ui/""
pmt_cmd "$pmt" "$cmd"


INSTANCE_GROUP=$(gcloud compute instance-groups list | grep -v NAME | awk '{ print $1 }')
pmt="Looks like we need more hosts!"
cmd="gcloud compute instance-groups managed resize $INSTANCE_GROUP --size 3"
pmt_cmd "$pmt" "$cmd"


pmt="Wait for hosts to join"
cmd="watch -n 1 'gcloud compute instances list' && gcloud compute instances list"
pmt_cmd "$pmt" "$cmd"


pmt="Scale up the ES data pods"
cmd="kubectl scale --replicas=3 rc elasticsearch-data"
pmt_cmd "$pmt" "$cmd"


pmt="Wait for pods to all start"
cmd="watch -g -n 1 'kubectl get pods | grep elasticsearch-data | grep -v -i running'"
pmt_cmd "$pmt" "$cmd"


pmt="Check to see if the ES data pods were added to the cluster"
cmd="sleep 5 && curl http://$LB_IP:9200/_cluster/health?pretty"
pmt_cmd "$pmt" "$cmd"
