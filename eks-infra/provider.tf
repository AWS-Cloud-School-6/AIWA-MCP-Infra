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
  region = "ap-northeast-2"
}

provider "kubernetes" {
  # Remove exec block as it's redundant with local kubeconfig
  config_path = "~/.kube/config" # 사용자의 kubeconfig를 사용하여 접근
}

provider "helm" {
  kubernetes {
    host        = data.aws_eks_cluster.cluster.endpoint
    config_path = "~/.kube/config" # 동일하게 kubeconfig 사용
  }
}
