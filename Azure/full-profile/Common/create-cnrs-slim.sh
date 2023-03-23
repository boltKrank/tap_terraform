cat <<EOF > overlays/cnrs-slim.yaml
#@ load("@ytt:overlay", "overlay")
#@overlay/match by=overlay.subset({"metadata":{"namespace":"knative-eventing"}}), expects="1+"
#@overlay/remove
---
#@overlay/match by=overlay.subset({"metadata":{"namespace":"knative-sources"}}), expects="1+"
#@overlay/remove
---
#@overlay/match by=overlay.subset({"metadata":{"namespace":"triggermesh"}}), expects="1+"
#@overlay/remove
---
#@overlay/match by=overlay.subset({"metadata":{"namespace":"vmware-sources"}}), expects="1+"
#@overlay/remove
---
EOF
