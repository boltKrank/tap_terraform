#!/bin/bash
NAMESPACE=demo
cat <<EOF > grype-${NAMESPACE}-values.yaml
namespace: ${NAMESPACE}
targetImagePullSecret: registry-credentials
metadataStore:
  url: https://metadata-store.${DOMAIN_NAME_VIEW}
  caSecret:
    name: store-ca-cert
    importFromNamespace: metadata-store-secrets
  authSecret:
    name: store-auth-token
    importFromNamespace: metadata-store-secrets
EOF
