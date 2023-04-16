#!/bin/bash
DOMAIN_NAME=$1
CERT_COUNTRY=$2

mkdir -p certs
docker run --rm -v ${PWD}/certs:/certs hitch openssl req -new -nodes -out /certs/ca.csr -keyout /certs/ca.key -subj "/CN=default-ca/O=TAP/C=${CERT_COUNTRY}"
chmod og-rwx ca.key
docker run --rm -v ${PWD}/certs:/certs hitch openssl x509 -req -in /certs/ca.csr -days 3650 -extfile /etc/ssl/openssl.cnf -extensions v3_ca -signkey /certs/ca.key -out /certs/ca.crt




cat <<EOF > overlays/contour-default-tls.yaml                                                                                                  
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
  tls.crt: |
$(cat certs/ca.crt | sed 's/^/    /g')
  tls.key: |
$(cat certs/ca.key | sed 's/^/    /g')
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

kubectl -n tap-install create secret generic contour-default-tls \
  -o yaml \
  --dry-run=client \
  --from-file=overlays/contour-default-tls.yaml \
  | kubectl apply -f-
  
