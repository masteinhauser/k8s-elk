#!/bin/bash
source inc-funcs.sh


pmt="Scale down logstash, but leave the controller staged"
cmd="kubectl scale --replicas=0 rc logstash"
pmt_cmd "$put" "$cmd"


put="Delete services?"
cmd="kubectl delete service kibana && kubectl delete service elasticsearch && kubectl delete service elasticsearch-discovery"
put_cmd "$put" "$cmd"


pmt="Delete replication-controllers?"
cmd="kubectl delete rc logstash && kubectl delete rc kibana && kubectl delete rc elasticsearch-data && kubectl delete rc elasticsearch-lb && kubectl delete rc elasticsearch-master"
pmt_cmd "$pmt" "$cmd"
