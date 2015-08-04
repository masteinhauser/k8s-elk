#!/bin/bash
source inc-funcs.sh

ES_IP=$(kubectl get services elasticsearch -o yaml | grep ip: | sed -e 's/- ip://' -e 's/[ \t]*//' )
put="Let's see if Elasticsearch is actually up and available..."
cmd="curl http://${ES_IP}:9200"
put_cmd "$put" "$cmd"


pmt="Ready to cleanup the elasticsearch service and pod?..."
cmd="kubectl delete services elasticsearch"
pmt_cmd "$pmt" "$cmd"


put="deleting elasticsearch replication-controller"
cmd="kubectl delete rc elasticsearch"
put_cmd "$put" "$cmd"
