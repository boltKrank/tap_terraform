#!/bin/bash
cat <<EOF > tap-values-view.yaml
profile: view

ceip_policy_disclosed: true

shared:
  ingress_domain: ${DOMAIN_NAME_VIEW}
  ca_cert_data: $(cat tls-cert-sed.txt)

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
        service.beta.kubernetes.io/azure-load-balancer-resource-group: tap-view

tap_gui:
  service_type: ClusterIP
  tls:
    secretName: tap-default-tls
    namespace: tanzu-system-ingress
  app_config:
    backend:
      database:
        client: pg
        connection:
          host: \${TAP_GUI_DB_SERVICE_HOST}
          port: \${TAP_GUI_DB_SERVICE_PORT}
          user: \${POSTGRES_USER}
          password: \${POSTGRES_PASSWORD}
    kubernetes:
      serviceLocatorMethod:
        type: multiTenant
      clusterLocatorMethods:
      - type: config
        clusters:
        - url: $(cat tap-gui/cluster-url-run)
          name: run
          authProvider: serviceAccount
          serviceAccountToken: $(cat tap-gui/cluster-token-run)
          skipTLSVerify: false
          caData: $(cat tap-gui/cluster-ca-run)
      - type: config
        clusters:
        - url: $(cat tap-gui/cluster-url-build)
          name: build
          authProvider: serviceAccount
          serviceAccountToken: $(cat tap-gui/cluster-token-build)
          skipTLSVerify: false
          caData: $(cat tap-gui/cluster-ca-build)
    proxy:
      /metadata-store:
        target: https://metadata-store-app.metadata-store:8443/api/v1
        changeOrigin: true
        secure: false
        headers:
          Authorization: "Bearer CHANGEME"
          X-Custom-Source: project-star
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

metadata_store:
  ns_for_export_app_cert: "*"

package_overlays:
- name: contour
  secrets:
  - name: contour-default-tls
- name: tap-gui
  secrets:
  - name: tap-gui-db
- name: metadata-store
  secrets:
  - name: metadata-store-read-only-client

excluded_packages:
- learningcenter.tanzu.vmware.com
- workshops.learningcenter.tanzu.vmware.com
- api-portal.tanzu.vmware.com
EOF