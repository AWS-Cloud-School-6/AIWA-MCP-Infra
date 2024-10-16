terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

provider "kubernetes" {
  config_path = "~/.kube/config" # 사용자의 kubeconfig를 사용하여 접근
}

provider "helm" {
  # EKS Cluster 1
  kubernetes {
    host        = data.aws_eks_cluster.cluster_1.endpoint
    config_path = "~/.kube/config" # 동일하게 kubeconfig 사용
  }
}

# Add this block for EKS Cluster 2
provider "helm" {
  alias = "eks_2"

  kubernetes {
    host        = data.aws_eks_cluster.cluster_2.endpoint
    config_path = "~/.kube/config" # 동일하게 kubeconfig 사용
  }
}
