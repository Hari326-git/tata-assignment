# # Initialize Terraform
# terraform {
#   required_providers {
#     helm = {
#       source = "hashicorp/helm"
#       version = "~> 2.0"
#     }
#   }
# }

# # Configure Kubernetes provider
# provider "kubernetes" {
#   config_context_cluster = "test"
# }

# Configure Kubernetes provider
provider "kubernetes" {
  config_context_cluster = "gke_valid-moment-410717_asia-south2-a_test"
}



# Install ArgoCD using Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "3.24.0"  # Or any version you prefer

  namespace  = "argocd"

  # Optionally, you can provide values for Helm chart parameters
  values = [
    # Example values file
    <<EOF
    server:
      service:
        type: ClusterIP  # Use ClusterIP instead of LoadBalancer
    EOF
  ]
}

# Extract ArgoCD server ClusterIP
data "kubernetes_service" "argocd_server" {
  metadata {
    name      = helm_release.argocd.metadata[0].name
    namespace = "argocd"
  }
}

# Output ArgoCD server ClusterIP
output "argocd_server_ip" {
  value = data.kubernetes_service.argocd_server.spec[0].cluster_ip
}
