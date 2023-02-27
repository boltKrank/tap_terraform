cat <<EOF > $HOME/overlays/view/metadata-store-read-only-client.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: metadata-store-ready-only
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: metadata-store-read-only
subjects:
- kind: ServiceAccount
  name: metadata-store-read-client
  namespace: metadata-store
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metadata-store-read-client
  namespace: metadata-store
automountServiceAccountToken: false
---
apiVersion: v1
kind: Secret
metadata:
  name: metadata-store-read-client
  namespace: metadata-store
  annotations:
    kubernetes.io/service-account.name: metadata-store-read-client
type: kubernetes.io/service-account-token
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: metadata-store-read-client-secret-read
  namespace: metadata-store
rules:
- apiGroups: [ "" ]
  resources: [ "secrets" ]
  resourceNames: [ "metadata-store-read-client" ]
  verbs: [ "get" ]
EOF