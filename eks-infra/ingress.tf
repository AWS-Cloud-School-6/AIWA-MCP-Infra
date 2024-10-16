# ingress.tf 파일 최상단에 추가
data "aws_caller_identity" "current" {}

# Fetch EKS Cluster Details
data "aws_eks_cluster" "cluster_1" {
  name       = module.eks_1.cluster_name
  depends_on = [module.eks_1]
}

data "aws_eks_cluster" "cluster_2" {
  name       = module.eks_2.cluster_name
  depends_on = [module.eks_2]
}

locals {
  oidc_issuer_url_1   = replace(data.aws_eks_cluster.cluster_1.identity[0].oidc[0].issuer, "https://", "")
  oidc_provider_arn_1 = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_issuer_url_1}"

  oidc_issuer_url_2   = replace(data.aws_eks_cluster.cluster_2.identity[0].oidc[0].issuer, "https://", "")
  oidc_provider_arn_2 = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_issuer_url_2}"
}

# Load Balancer Controller Role for Cluster 1
module "lb_role_1" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "${module.eks_1.cluster_name}_eks_lb"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = local.oidc_provider_arn_1
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller-1"]
    }
  }
}

# Load Balancer Controller Role for Cluster 2
module "lb_role_2" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "${module.eks_2.cluster_name}_eks_lb"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = local.oidc_provider_arn_2
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller-2"]
    }
  }
}

# Service Account for Cluster 1
resource "kubernetes_service_account" "service-account-1" {
  metadata {
    name      = "aws-load-balancer-controller-1"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = module.lb_role_1.iam_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
  provider = kubernetes.cluster1
}

# Service Account for Cluster 2
resource "kubernetes_service_account" "service-account-2" {
  metadata {
    name      = "aws-load-balancer-controller-2"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = module.lb_role_2.iam_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
  provider = kubernetes.cluster2
}

# ALB Controller for Cluster 1
resource "helm_release" "alb-controller-1" {
  name       = "aws-load-balancer-controller-1"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  provider   = helm.cluster1

  depends_on = [
    kubernetes_service_account.service-account-1,
    module.eks_1
  ]

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller-1"
  }

  set {
    name  = "clusterName"
    value = module.eks_1.cluster_name
  }
}

# ALB Controller for Cluster 2
resource "helm_release" "alb-controller-2" {
  name       = "aws-load-balancer-controller-2"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  provider   = helm.cluster2

  depends_on = [
    kubernetes_service_account.service-account-2,
    module.eks_2
  ]

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller-2"
  }

  set {
    name  = "clusterName"
    value = module.eks_2.cluster_name
  }
}
