cat <<EOF > tap-values-build.yaml
profile: build

shared:
  image_registry:
    project_path: "${ACR_NAME}.azurecr.io/tanzu-application-platform"
    secret:
      name: repository-secret
      namespace: tap-install
  ca_cert_data: |
$(cat tls-cert-sed.txt)

ceip_policy_disclosed: true

buildservice: 
  exclude_dependencies: true

supply_chain: testing_scanning

scanning:
  metadataStore:
    url: ""

package_overlays:
- name: ootb-supply-chain-testing-scanning
  secrets:
  - name: metadata-store-secrets

excluded_packages:
- grype.scanning.apps.tanzu.vmware.com
- contour.tanzu.vmware.com
EOF