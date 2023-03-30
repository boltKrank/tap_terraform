cat <<EOF > tap-values-full.yaml
profile: full
ceip_policy_disclosed: true # Installation fails if this is set to 'false'
shared:
  ingress_domain: "${DOMAIN_NAME}"

buildservice:
  kp_default_repository: siandersontap.azurecr.io/buildservice
  kp_default_repository_username: siandersontap
  kp_default_repository_password: "+fWjb7umfT396tEBbt+seflfwZ5hFG6rGYCasuE9MR+ACRDJMFKa"
  enable_automatic_dependency_updates: false

supply_chain: testing_scanning

ootb_templates:
  iaas_auth: true

ootb_supply_chain_testing:
  registry:
    server: sianderson.azurecr.io
    repository: tapsupplychain
  gitops:
    ssh_secret: ""

ootb_supply_chain_testing_scanning:
  registry:
    server: sianderson.azurecr.io
    repository: tapsupplychain
  gitops:
    ssh_secret: ""

# learningcenter:
#  ingressDomain: learning-center.tap.com

ootb_delivery_basic:
  service_account: default

tap_gui:
  ingressEnabled: true
  service_type: ClusterIP # NodePort for distributions that don't support LoadBalancer
  app_config:
    supplyChain:
      enablePlugin: true
    auth:
      allowGuestAccess: true
    backend:
      baseUrl: http://tap-gui."${DOMAIN_NAME}"
      cors:
        origin: http://tap-gui."${DOMAIN_NAME}"
    app:
      baseUrl: http://tap-gui."${DOMAIN_NAME}"

scanning:
  metadataStore:
    url: ""

metadata_store:
  ingressEnabled: true
  ingressDomain: "${DOMAIN_NAME}"
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
  domain_name: "${DOMAIN_NAME}"

  #grype:
  #namespace: tap-workload
  #targetImagePullSecret: tap-registry

EOF