#!/bin/bash
cat <<EOF > tap-values.yaml
profile: full

ceip_policy_disclosed: true

shared:
  ingress_domain: ${DOMAIN_NAME}
  image_registry:
    project_path: ${ACR_NAME}.azurecr.io
    username: admin
    password: ${ACR_PASS}

contour:
  infrastructure_provider: azure
  contour:
    configFileContents:
      accesslog-format: json  
  envoy:
    service:
      type: LoadBalancer
      loadBalancerIP: ${ENVOY_IP_VIEW}      
      annotations:
         service.beta.kubernetes.io/azure-load-balancer-resource-group: ${TAP_RG}

tap_gui:
  service_type: ClusterIP
  tls:
    secretName: tap-default-tls
    namespace: tanzu-system-ingress
  app_config:
    catalog:
      locations:
      - type: url
        target: https://github.com/sample-accelerators/tanzu-java-web-app/blob/main/catalog/catalog-info.yaml

appliveview:
  ingressEnabled: true
  tls:
    secretName: tap-default-tls
    namespace: tanzu-system-ingress

accelerator:
  ingress:
    include: true    
    enable_tls: true  
  tls:
    secret_name: tap-default-tls
    namespace: tanzu-system-ingress
  server:
    service_type: ClusterIP

metadata_store:
  app_service_type: ClusterIP
  ingress_enabled: "true"

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
- name: metadata-store
  secrets:
  - name: metadata-store-ingress-tls

excluded_packages:
- grype.scanning.apps.tanzu.vmware.com
- learningcenter.tanzu.vmware.com
- workshops.learningcenter.tanzu.vmware.com
- eventing.tanzu.vmware.com
- policy-controller policy.apps.tanzu.vmware.com


excluded_packages:
- learningcenter.tanzu.vmware.com
- workshops.learningcenter.tanzu.vmware.com
- api-portal.tanzu.vmware.com
EOF
