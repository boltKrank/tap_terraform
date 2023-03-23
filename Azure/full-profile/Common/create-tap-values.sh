cat <<EOF > tap-values.yaml
profile: full

ceip_policy_disclosed: true

cnrs:
  domain_name: ${DOMAIN_NAME}  
  domain_template: "{{.Name}}-{{.Namespace}}.{{.Domain}}"
  default_tls_secret: tanzu-system-ingress/cnrs-default-tls

buildservice:
  kp_default_repository: ${ACR_SERVER}/build-service
  kp_default_repository_username: ${ACR_USERNAME}
  kp_default_repository_password: ${ACR_PASSWORD}

supply_chain: basic

ootb_supply_chain_basic:
  registry:
    server: ${ACR_SERVER}
    repository: supply-chain
  gitops:
    ssh_secret: git-ssh

contour:
  infrastructure_provider: azure
  envoy:
    service:
      type: LoadBalancer
      externalTrafficPolicy: Local
      annotations:
        service.beta.kubernetes.io/azure-load-balancer-resource-group: tap-rg

tap_gui:
  ingressEnabled: true
  ingressDomain: ${DOMAIN_NAME} 
  service_type: ClusterIP
  tls:
    secretName: cnrs-default-tls
    namespace: tanzu-system-ingress
  app_config:
    app:
      baseUrl: https://tap-gui.${DOMAIN_NAME}
    backend:
      baseUrl: https://tap-gui.${DOMAIN_NAME}
      cors:
        origin: https://tap-gui.${DOMAIN_NAME}
    catalog:
      locations:
      - type: url
        target: https://github.com/sample-accelerators/tanzu-java-web-app/blob/main/catalog/catalog-info.yaml
      - type: url
        target: https://github.com/sample-accelerators/spring-petclinic/blob/accelerator/catalog/catalog-info.yaml
      - type: url
        target: https://github.com/tanzu-japan/spring-music/blob/tanzu/catalog/catalog-info.yaml

accelerator:
  domain: ${DOMAIN_NAME}  
  ingress:
    include: true
    enable_tls: true
  tls:
    secret_name: cnrs-default-tls
    namespace: tanzu-system-ingress
  server:
    service_type: ClusterIP

metadata_store:
  app_service_type: ClusterIP
  ingress_enabled: "true"
  ingress_domain: ${DOMAIN_NAME}

scanning:
  metadataStore:
    url: "" # Disable embedded integration since it's deprecated

package_overlays:
- name: contour
  secrets:
  - name: contour-loadbalancer-ip
- name: cnrs
  secrets:
  - name: cnrs-default-tls
  - name: cnrs-slim
- name: metadata-store
  secrets:
  - name: metadata-store-ingress-tls

excluded_packages:
- grype.scanning.apps.tanzu.vmware.com
- learningcenter.tanzu.vmware.com
- workshops.learningcenter.tanzu.vmware.com
EOF