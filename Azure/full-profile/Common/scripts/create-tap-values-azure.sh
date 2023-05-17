cat <<EOF > tap-values-azure.yaml
profile: full
ceip_policy_disclosed: true # Installation fails if this is set to 'false'
buildservice:
  kp_default_repository: tapbuildservice.azurecr.io/buildservice
  kp_default_repository_secret:
    name: registry-credentials
    namespace: $1
  enable_automatic_dependency_updates: false

supply_chain: testing_scanning

ootb_templates:
  iaas_auth: true

ootb_supply_chain_testing:
  registry:
    server: $2.azurecr.io
    repository:tapsupplychain
  gitops:
    ssh_secret: ""

ootb_supply_chain_testing_scanning:
  registry:
    server: $2.azurecr.io
    repository: tapsupplychain
  gitops:
    ssh_secret: ""

learningcenter:
  ingressDomain: learning-center.tap.com

ootb_delivery_basic:
  service_account: default

tap_gui:
  ingressEnabled: true
  ingressDomain: tap.com
  app_config:
    supplyChain:
      enablePlugin: true
    auth:
      allowGuestAccess: true
    backend:
      baseUrl: http://tap-gui.tap.com
      cors:
        origin: http://tap-gui.tap.com
    app:
      baseUrl: http://tap-gui.tap.com

scanning:
  metadataStore:
    url: ""

metadata_store:
  ingressEnabled: true
  ingressDomain: tap.com
  app_service_type: ClusterIP
  ns_for_export_app_cert: tap-workload

contour:
  envoy:
    service:
      type: LoadBalancer

accelerator:
  server:
    service_type: "ClusterIP"


cnrs:
  domain_name: tap.com

grype:
  namespace: tap-workload
  targetImagePullSecret: registry-credentials

EOF