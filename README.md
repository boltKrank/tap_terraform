# tap_terraform

Terraform to deploy Tanzu Application Platform

Check [https://github.com/Azure/terraform-azurerm-aks]

Check [https://github.com/hashicorp/terraform-provider-azurerm/blob/main/examples/kubernetes/public-ip/main.tf]

azurerm examples: [https://containersolutions.github.io/terraform-examples/examples/azurerm/azurerm.html]

## Creating a Service Principal

- Go to Azure AD -> "App Registrations" (Left hand side)
- "Register an app, copy the client_id, tennant_id
- Create a secret (copy secret, it's not retrieveable)
