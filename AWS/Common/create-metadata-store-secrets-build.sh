mkdir -p overlays/build

cat <<EOF > overlays/build/metadata-store-secrets.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: metadata-store-secrets
---
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: store-ca-cert
  namespace: metadata-store-secrets
stringData:
  ca.crt: |
$(kubectl get secret -n metadata-store ingress-cert -otemplate='{{index .data "ca.crt" | base64decode}}' --context tap-view-admin | sed 's/^/    /g')
---
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: store-auth-token
  namespace: metadata-store-secrets
stringData:
  auth_token: $(kubectl get secret -n metadata-store metadata-store-read-write-client -otemplate='{{.data.token | base64decode}}' --context tap-view-admin)
---
apiVersion: secretgen.carvel.dev/v1alpha1
kind: SecretExport
metadata:
  name: store-ca-cert
  namespace: metadata-store-secrets
spec:
  toNamespace: "*"
---
apiVersion: secretgen.carvel.dev/v1alpha1
kind: SecretExport
metadata:
  name: store-auth-token
  namespace: metadata-store-secrets
spec:
  toNamespace: "*"
EOF