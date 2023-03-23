cat <<EOF > metadata-store-ingress-tls.yaml
#@ load("@ytt:overlay", "overlay")
#@overlay/match by=overlay.subset({"metadata":{"name":"metadata-store-ingress"}, "kind": "HTTPProxy"})
---
spec:
  virtualhost:
    tls:
      secretName: tanzu-system-ingress/cnrs-default-tls
#@overlay/match by=overlay.subset({"metadata":{"name":"ingress-cert"}, "kind": "Certificate"})
#@overlay/remove
---
EOF
