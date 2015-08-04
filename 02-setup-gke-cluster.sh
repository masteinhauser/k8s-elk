#!/bin/bash
source inc-funcs.sh


pmt="List gcloud machine types?"
cmd="gcloud compute machine-types list --zones us-central1-f"
pmt_cmd "$pmt" "$cmd"


pmt="Launch GKE cluster?"
cmd="gcloud beta container clusters create k8s-elk --num-nodes 1 --machine-type n1-standard-1"
pmt_cmd "$pmt" "$cmd"


CLUSTER_INFO=$(gcloud beta container clusters describe k8s-elk | grep -E 'endpoint|password|admin')
ENDPOINT=$(echo "$CLUSTER_INFO" | grep endpoint | sed -e 's/endpoint://' -e 's/[ \t]*//')
PASSWORD=$(echo "$CLUSTER_INFO" | grep password | sed -e 's/password://' -e 's/[ \t]*//')

pmt="Launch Kubernetes UI?"
cmd="open "https://admin:$PASSWORD@$ENDPOINT/ui/""
pmt_cmd "$pmt" "$cmd"


pmt="What instances do we now have?"
cmd="gcloud compute instances list && gcloud beta container clusters list"
pmt_cmd "$pmt" "$cmd"

echo "!!!!!"
echo "NOTE: GKE runs the master for us! We only need to specify adding/removing minion nodes!"
echo "!!!!!" 
