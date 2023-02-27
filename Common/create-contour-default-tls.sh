cat <<EOF > overlays/view/contour-default-tls.yaml                                                                                                                                                                                                                          
#@ load("@ytt:data", "data")
#@ load("@ytt:overlay", "overlay")
#@ namespace = data.values.namespace
---
apiVersion: v1
kind: Secret
metadata:
  name: default-ca
  namespace: #@ namespace
type: kubernetes.io/tls
stringData:
  tls.crt: $(cat tls-cert-sed.txt)
  tls.key: $(cat tls-key-sed.txt)
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: default-ca-issuer
  namespace: #@ namespace
spec:
  ca:
    secretName: default-ca
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: tap-default-tls
  namespace: #@ namespace
spec:
  dnsNames:
  - #@ "*.${DOMAIN_NAME_VIEW}"
  issuerRef:
    kind: Issuer
    name: default-ca-issuer
  secretName: tap-default-tls
---
apiVersion: projectcontour.io/v1
kind: TLSCertificateDelegation
metadata:
  name: contour-delegation
  namespace: #@ namespace
spec:
  delegations:
  - secretName: tap-default-tls
    targetNamespaces:
    - "*"
EOF