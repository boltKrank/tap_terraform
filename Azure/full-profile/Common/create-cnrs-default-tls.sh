cat <<EOF > cnrs-default-tls.yaml
#@ load("@ytt:data", "data")
#@ load("@ytt:overlay", "overlay")
#@ namespace = data.values.ingress.external.namespace
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: cnrs-selfsigned-issuer
  namespace: #@ namespace
spec:
  selfSigned: { }
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: cnrs-ca
  namespace: #@ namespace
spec:
  commonName: cnrs-ca
  isCA: true
  issuerRef:
    kind: Issuer
    name: cnrs-selfsigned-issuer
  secretName: cnrs-ca
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: cnrs-ca-issuer
  namespace: #@ namespace
spec:
  ca:
    secretName: cnrs-ca
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: cnrs-default-tls
  namespace: #@ namespace
spec:
  dnsNames:
  - #@ "*.{}".format(data.values.domain_name)
  issuerRef:
    kind: Issuer
    name: cnrs-ca-issuer
  secretName: cnrs-default-tls
---
apiVersion: projectcontour.io/v1
kind: TLSCertificateDelegation
metadata:
  name: contour-delegation
  namespace: #@ namespace
spec:
  delegations:
  - secretName: cnrs-default-tls
    targetNamespaces:
    - "*"
#@overlay/match by=overlay.subset({"metadata":{"name":"config-network"}, "kind": "ConfigMap"})
---
data:
  #@overlay/match missing_ok=True
  default-external-scheme: https
EOF
