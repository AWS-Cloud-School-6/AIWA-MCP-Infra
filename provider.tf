terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  profile = var.profile
  region  = var.region
}

# Kubernetes provider for cluster 1
provider "kubernetes" {
  alias                  = "cluster1"
  host                   = module.eks_1.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_1.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks_1.cluster_name
    ]
  }
}

# Kubernetes provider for cluster 2
provider "kubernetes" {
  alias                  = "cluster2"
  host                   = module.eks_2.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_2.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks_2.cluster_name
    ]
  }
}

# Helm provider for cluster 1
provider "helm" {
  alias = "cluster1"
  kubernetes {
    host                   = module.eks_1.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_1.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks_1.cluster_name
      ]
    }
  }
}

# Helm provider for cluster 2
provider "helm" {
  alias = "cluster2"
  kubernetes {
    host                   = module.eks_2.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_2.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks_2.cluster_name
      ]
    }
  }
}
