cat <<EOF > tap-values.yaml
profile: full

shared:
  ingress_domain: ${DOMAIN_NAME}
  ca_cert_data: |
$(cat tls-cert-sed.txt)
  image_registry:
    project_path: "${ACR_NAME}.azurecr.io/tanzu-application-platform"
    secret:
      name: repository-secret
      namespace: tap-install

ceip_policy_disclosed: true

cnrs:
  domain_template: "{{.Name}}-{{.Namespace}}.{{.Domain}}"
  default_tls_secret: tanzu-system-ingress/tap-default-tls

buildservice: 
  exclude_dependencies: true

supply_chain: testing_scanning

scanning:
  metadataStore:
    url: ""

contour:
  infrastructure_provider: azure
  contour:
    configFileContents:
      accesslog-format: json  
  envoy:
    service:
      type: LoadBalancer
      loadBalancerIP: ${ENVOY_IP}      
      annotations:
        service.beta.kubernetes.io/azure-load-balancer-resource-group: ${TAP_RG}

tap_gui:
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
  ingress:
    include: true    
    enable_tls: true  
  tls:
    secret_name: tap-default-tls
    namespace: tanzu-system-ingress

appliveview:
  ingressEnabled: true
    tls:
      secretName: tap-default-tls
      namespace: tanzu-system-ingress

metadata_store:
  ns_for_export_app_cert: "*"

scanning:
  metadataStore:
    url: "" # Disable embedded integration since it's deprecated

package_overlays:
- name: contour
  secrets:
  - name: contour-default-tls
- name: cnrs
  secrets:
  - name: cnrs-https
- name: metadata-store
  secrets:
  - name: metadata-store-ingress-tls

excluded_packages:
- grype.scanning.apps.tanzu.vmware.com
- learningcenter.tanzu.vmware.com
- workshops.learningcenter.tanzu.vmware.com
EOF