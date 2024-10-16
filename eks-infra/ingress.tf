data "aws_caller_identity" "current2" {}

# EKS Cluster 1
data "aws_eks_cluster" "cluster_1" {
  name       = module.eks_1.cluster_name
  depends_on = [module.eks_1]
}

locals {
  oidc_issuer_url_1   = replace(data.aws_eks_cluster.cluster_1.identity[0].oidc[0].issuer, "https://", "")
  oidc_provider_arn_1 = "arn:aws:iam::${data.aws_caller_identity.current2.account_id}:oidc-provider/${local.oidc_issuer_url_1}"
}

module "lb_role_1" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "${module.eks_1.cluster_name}_eks_lb"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = local.oidc_provider_arn_1
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "kubernetes_service_account" "service-account_1" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"       = "aws-load-balancer-controller"
      "app.kubernetes.io/component"  = "controller"
      "app.kubernetes.io/managed-by" = "terraform"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = module.lb_role_1.iam_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}

resource "helm_release" "alb-controller_1" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  depends_on = [
    kubernetes_service_account.service-account_1,
    module.eks_1
  ]

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = module.vpc_1.vpc_id
  }

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.${var.region}.amazonaws.com/amazon/aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "clusterName"
    value = module.eks_1.cluster_name
  }
}

# EKS Cluster 2
data "aws_eks_cluster" "cluster_2" {
  name       = module.eks_2.cluster_name
  depends_on = [module.eks_2]
}

locals {
  oidc_issuer_url_2   = replace(data.aws_eks_cluster.cluster_2.identity[0].oidc[0].issuer, "https://", "")
  oidc_provider_arn_2 = "arn:aws:iam::${data.aws_caller_identity.current2.account_id}:oidc-provider/${local.oidc_issuer_url_2}"
}

module "lb_role_2" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "${module.eks_2.cluster_name}_eks_lb"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = local.oidc_provider_arn_2
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "kubernetes_service_account" "service-account_2" {
  metadata {
    name      = "aws-load-balancer-controller-2"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"       = "aws-load-balancer-controller"
      "app.kubernetes.io/component"  = "controller"
      "app.kubernetes.io/managed-by" = "terraform"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = module.lb_role_2.iam_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}

resource "helm_release" "alb-controller_2" {
  provider   = helm.eks_2
  name       = "aws-load-balancer-controller-2"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  depends_on = [
    kubernetes_service_account.service-account_2,
    module.eks_2
  ]

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = module.vpc_2.vpc_id
  }

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.${var.region}.amazonaws.com/amazon/aws-load-balancer-controller"
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
