cat <<EOF > $HOME/overlays/cnrs-https.yaml
#@ load("@ytt:overlay", "overlay")
#@overlay/match by=overlay.subset({"metadata":{"name":"config-network"}, "kind": "ConfigMap"})
---
data:
  #@overlay/match missing_ok=True
  default-external-scheme: https
  #@overlay/match missing_ok=True
  http-protocol: redirected
EOF