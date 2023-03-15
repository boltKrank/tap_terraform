#!/bin/bash
tanzu package install full-tbs-deps -p full-tbs-deps.tanzu.vmware.com -v $1 -n tap-install --wait=false
while [ "$(kubectl -n tap-install get app full-tbs-deps -o=jsonpath='{.status.friendlyDescription}')" != "Reconcile succeeded" ];do
  date
  kubectl get app -n tap-install
  echo "---------------------------------------------------------------------"
  sleep 30
done
echo "✅ Install succeeded"