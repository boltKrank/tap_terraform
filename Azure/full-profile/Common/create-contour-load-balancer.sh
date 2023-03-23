cat <<EOF > overlays/contour-loadbalancer-ip.yaml
#@ load("@ytt:overlay", "overlay")
#@overlay/match by=overlay.subset({"kind": "Service", "metadata": {"name": "envoy"}})
---
spec:
  #@overlay/match missing_ok=True
  loadBalancerIP: ${ENVOY_IP}
EOF
