#!/bin/bash
tanzu package install tap -p tap.tanzu.vmware.com -v $1 --values-file $2 -n tap-install --wait=false
while [ "$(kubectl -n tap-install get app tap -o=jsonpath='{.status.friendlyDescription}')" != "Reconcile succeeded" ];do
  date
  kubectl get app -n tap-install
  echo "---------------------------------------------------------------------"
  sleep 30
done
echo "Install succeeded"
