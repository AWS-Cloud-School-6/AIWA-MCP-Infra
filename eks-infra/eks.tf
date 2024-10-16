data "aws_caller_identity" "current" {}

resource "aws_iam_role" "something" {
  name = "something"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# EKS Cluster 1
module "eks_1" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "my-cluster-1"
  cluster_version = "1.30"

  cluster_endpoint_public_access = true

  # Addons
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    aws-ebs-csi-driver     = {}
    vpc-cni = {
      before_compute = true
      most_recent    = true
      configuration_values = jsonencode({
        env = {
          ENABLE_POD_ENI                    = "true"
          ENABLE_PREFIX_DELEGATION          = "true"
          POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
        }
        nodeAgent = {
          enablePolicyEventLogs = "true"
        }
        enableNetworkPolicy = "true"
      })
    }
  }

  vpc_id                   = module.vpc_1.vpc_id
  subnet_ids               = module.vpc_1.private_subnets
  control_plane_subnet_ids = module.vpc_1.public_subnets

  eks_managed_node_groups = {
    example = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]

      min_size     = 3
      max_size     = 10
      desired_size = 3
    }
  }

  enable_cluster_creator_admin_permissions = true

  access_entries = {
    example = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/something"
      policy_associations = {
        example = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = {
            namespaces = ["default"]
            type       = "namespace"
          }
        }
      }
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

# EKS Cluster 2
module "eks_2" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "my-cluster-2"
  cluster_version = "1.30"

  cluster_endpoint_public_access = true

  # Addons
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    aws-ebs-csi-driver     = {}
    vpc-cni = {
      before_compute = true
      most_recent    = true
      configuration_values = jsonencode({
        env = {
          ENABLE_POD_ENI                    = "true"
          ENABLE_PREFIX_DELEGATION          = "true"
          POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
        }
        nodeAgent = {
          enablePolicyEventLogs = "true"
        }
        enableNetworkPolicy = "true"
      })
    }
  }

  vpc_id                   = module.vpc_2.vpc_id
  subnet_ids               = module.vpc_2.private_subnets
  control_plane_subnet_ids = module.vpc_2.public_subnets

  eks_managed_node_groups = {
    example = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]

      min_size     = 3
      max_size     = 10
      desired_size = 3
    }
  }

  enable_cluster_creator_admin_permissions = true

  access_entries = {
    example = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/something"
      policy_associations = {
        example = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = {
            namespaces = ["default"]
            type       = "namespace"
          }
        }
      }
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

resource "null_resource" "update_kubeconfig" {
  depends_on = [module.eks_1, module.eks_2]

  triggers = {
    cluster_name_1 = module.eks_1.cluster_name
    cluster_name_2 = module.eks_2.cluster_name
    timestamp      = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws eks update-kubeconfig --name ${module.eks_1.cluster_name} --region ${var.region} || exit 1
      aws eks update-kubeconfig --name ${module.eks_2.cluster_name} --region ${var.region} || exit 2

      until kubectl get nodes; do
        echo "Waiting for cluster to be ready..."
        sleep 5
      done

      kubectl config use-context arn:aws:eks:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/${module.eks_2.cluster_name}
      helm install aws-load-balancer-controller-3 aws-load-balancer-controller --namespace kube-system \
        --repo https://aws.github.io/eks-charts \
        --set region=${var.region} \
        --set vpcId=${module.vpc_2.vpc_id} \
        --set image.repository=602401143452.dkr.ecr.${var.region}.amazonaws.com/amazon/aws-load-balancer-controller \
        --set serviceAccount.create=false \
        --set serviceAccount.name=aws-load-balancer-controller-3 \
        --set clusterName=${module.eks_2.cluster_name}
    EOT
  }
}
