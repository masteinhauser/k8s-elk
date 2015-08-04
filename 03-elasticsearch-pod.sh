#!/bin/bash
source inc-funcs.sh

pmt="Download and start the Elasticsearch docker image?"
cmd="kubectl run elasticsearch --image=elasticsearch --port=9200"
pmt_cmd "$pmt" "$cmd"


pmt="Watch for the Elasticsearch container to start"
cmd="watch -g -n 1 'kubectl get pods | grep -i running' && kubectl get pods"
pmt_cmd "$pmt" "$cmd"


pmt="Expose the running container to the world. (discuss services and kube-proxy)"
cmd="kubectl expose rc elasticsearch --create-external-load-balancer=true && watch -g -n 1 'gcloud compute forwarding-rules list' && gcloud compute forwarding-rules list"
pmt_cmd "$pmt" "$cmd"


pmt="Watch for kubernetes to see the new load balancer external IP"
cmd="watch -g -n 1 'kubectl get services elasticsearch' && kubectl get services elasticsearch"
pmt_cmd "$pmt" "$cmd"


put="NOTE: Note there are 2 IP(s) listed, both serving port 80. One is the internal IP that other pods in the cluster can use to talk to your service; the other is the external load-balanced IP."
cmd="kubectl get services elasticsearch"
put_cmd "$put" "$cmd"


ES_IP=$(kubectl get services elasticsearch -o yaml | grep ip: | sed -e 's/- ip://' -e 's/[ \t]*//' )
put="Let's see if Elasticsearch is actually up and available..."
cmd="curl --retry 10 http://${ES_IP}:9200"
put_cmd "$put" "$cmd"
