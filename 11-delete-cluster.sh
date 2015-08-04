#!/bin/bash
source inc-funcs.sh

put="Delete cluster?"
cmd="gcloud beta container clusters delete k8s-elk"
put_cmd "$put" "$cmd"
