#!/bin/bash
source inc-funcs.sh

put="Deploy Logstash"
cmd="kubectl create -f kubernetes-elk-cluster/logstash-controller.yaml"
put_cmd "$put" "$cmd"


put="Deploy Kibana"
cmd="kubectl create -f kubernetes-elk-cluster/kibana-controller.yaml"
put_cmd "$put" "$cmd"


pmt="Expose Kibana to the world"
cmd="kubectl expose rc kibana --create-external-load-balancer=true --port=80 --target-port=5601 --name=kibana --protocol=TCP && watch -g -n 1 'gcloud compute forwarding-rules list' && gcloud compute forwarding-rules list"
pmt_cmd "$pmt" "$cmd"


pmt="Watch for kubernetes to see the new load balancer external IP"
cmd="watch -g -n 1 'kubectl get services kibana' && kubectl get services kibana"
pmt_cmd "$pmt" "$cmd"


KIBANA_IP=$(kubectl get services kibana -o yaml | grep ip: | sed -e 's/- ip://' -e 's/[ \t]*//' )


pmt="Check to see if Kibana can access the cluster"
cmd="sleep 5 && curl --retry 10 http://${KIBANA_IP}/elasticsearch/_cluster/health?pretty"
pmt_cmd "$pmt" "$cmd"


pmt="Configure Kibana default index-pattern"
cmd="curl -i -XPUT --data-binary @kibana-index-pattern.json --globoff \"http://${KIBANA_IP}/elasticsearch/.kibana/index-pattern/logstash-*?version_type=force&version=1\""
pmt_cmd "$pmt" "$cmd"


pmt="Configure Kibana default index"
cmd="curl -i -XPUT --data-binary @kibana-config.json --globoff \"http://${KIBANA_IP}/elasticsearch/.kibana/config/4.0.3?version_type=force&version=1\""
pmt_cmd "$pmt" "$cmd"


pmt="Check the Kibana UI works"
cmd="open \"http://${KIBANA_IP}/#/discover?_g=(refreshInterval:(display:'5%20seconds',section:1,value:5000),time:(from:now-15m,mode:quick,to:now))&_a=(columns:!(message),index:'logstash-*',interval:auto,query:(query_string:(analyze_wildcard:!t,query:'*')),sort:!('@timestamp',desc))\""
pmt_cmd "$pmt" "$cmd"
