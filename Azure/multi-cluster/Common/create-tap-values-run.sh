cat <<EOF > tap-values-run.yaml
profile: run

ceip_policy_disclosed: true

shared:
  ingress_domain: ${DOMAIN_NAME_RUN}
  ca_cert_data: |
$(cat tls-cert-sed.txt)

contour:
  infrastructure_provider: azure
  contour:
    configFileContents:
      accesslog-format: json  
  envoy:
    service:
      type: LoadBalancer
      loadBalancerIP: ${ENVOY_IP_RUN}      
      annotations:
        service.beta.kubernetes.io/azure-load-balancer-resource-group: tap-run

cnrs:
  domain_template: "{{.Name}}-{{.Namespace}}.{{.Domain}}"
  default_tls_secret: tanzu-system-ingress/tap-default-tls

appliveview_connector:
  backend:
    ingressEnabled: true
    host: appliveview.${DOMAIN_NAME_VIEW}

api_auto_registration:
  tap_gui_url: https://tap-gui.${DOMAIN_NAME_VIEW}
  cluster_name: run

accelerator:
  ingress:
    include: true    
    enable_tls: true  
  tls:
    secret_name: tap-default-tls
    namespace: tanzu-system-ingress

package_overlays:
- name: contour
  secrets:
  - name: contour-default-tls
- name: cnrs
  secrets:
  - name: cnrs-https

excluded_packages:
- image-policy-webhook.signing.apps.tanzu.vmware.com
- eventing.tanzu.vmware.com
EOF